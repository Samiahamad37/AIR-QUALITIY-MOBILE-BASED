import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/Data/air_quality_data.dart';
import '/screens/app_theme.dart';
import '/widgets/common_widget.dart';
import '/services/shared_data_service.dart';
import '/utils/device_labels.dart';
import '/utils/time_utils.dart';
import 'package:air_quality_monitor/L10n/app_localizations.dart';

const String defaultDevice = 'lands-building';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Consumer<SharedDataService>(
      builder: (context, service, _) {
        // Show connection state indicator
        if (service.connectionState != 'connected' && service.connectionState != 'disconnected') {
          return Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              title: Text(_getConnectionStateText(service.connectionState)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getConnectionStateIcon(service.connectionState),
                  const SizedBox(height: 16),
                  Text(
                    _getConnectionStateText(service.connectionState),
                    style: TextStyle(fontSize: 16, color: palette.textSecondary),
                  ),
                  if (service.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      service.error!,
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (service.connectionState == 'no_sensor' || service.connectionState == 'error')
                    ElevatedButton(
                      onPressed: () => service.detectNearestSensor(),
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          );
        }

        if (service.isLoading && service.currentData == null) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (service.error != null || service.currentData == null) {
          return Scaffold(
            backgroundColor: bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: palette.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(service.error ?? 'No data',
                      style: TextStyle(color: palette.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => service.loadData(),
                    child: Text(AppLocalizations.of(context).errorRetry),
                  ),
                ],
              ),
            ),
          );
        }

        final data = service.currentData!;
        final level = data.level;
        final maxHourlyAqi = data.hourlyData.isEmpty
            ? 1
            : data.hourlyData
                .map((h) => h.aqi)
                .reduce((a, b) => a > b ? a : b)
                .clamp(1, 500);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: context.appOverlayStyle,
          child: Scaffold(
            backgroundColor: bg,
            body: RefreshIndicator(
              onRefresh: () => service.loadData(),
              color: level.color,
              backgroundColor: palette.card,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: _buildHero(context, data, level, service)),

                  if (service.devices.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: DropdownButtonFormField<String>(
                          value: service.selectedDevice,
                          dropdownColor: palette.card,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).homeLocation,
                            labelStyle:
                                TextStyle(color: palette.textSecondary),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: palette.border),
                            ),
                            filled: true,
                            fillColor: palette.card,
                          ),
                          items: service.devices
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(deviceDisplayName(d),
                                        style: TextStyle(
                                            color: palette.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              service.setSelectedDevice(val);
                            }
                          },
                        ),
                      ),
                    ),

                  // ─── Metrics Strip ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          MetricChip(
                            icon: Icons.thermostat_rounded,
                            value: '${data.temperature.toStringAsFixed(1)}°C',
                            label: AppLocalizations.of(context).homeTemperature,
                            color: const Color(0xFFFB923C),
                          ),
                          const SizedBox(width: 8),
                          MetricChip(
                            icon: Icons.water_drop_rounded,
                            value: '${data.humidity.round()}%',
                            label: AppLocalizations.of(context).homeHumidity,
                            color: const Color(0xFF60A5FA),
                          ),
                          const SizedBox(width: 8),
                          MetricChip(
                            icon: Icons.co2_rounded,
                            value: '${data.pollutants[2].value.round()} PPM',
                            label: 'CO2',
                            color: const Color(0xFF34D399),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Today's AQI Trend ────────────────────────────────────
                  if (data.hourlyData.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(title: AppLocalizations.of(context).homeTodayTrend),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: SizedBox(
                            height: 110,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children:
                                  data.hourlyData.asMap().entries.map((e) {
                                return HourlyChartBar(
                                  data: e.value,
                                  maxAqi: maxHourlyAqi,
                                  delayMs: e.key * 60,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ─── Pollutants Breakdown ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: SectionHeader(title: AppLocalizations.of(context).homePollutants),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        child: Column(
                          children: data.pollutants.asMap().entries.map((e) {
                            return PollutantBar(
                              pollutant: e.value,
                              delayMs: e.key * 80,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // ─── Health Advisory ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SectionHeader(title: AppLocalizations.of(context).homeHealthAdvisory),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: level.bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: level.color.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: level.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(Icons.health_and_safety_rounded,
                                    color: level.color, size: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(level.shortName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: level.textColor,
                                      )),
                                  const SizedBox(height: 3),
                                  Text(level.advice,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: level.textColor.withOpacity(0.8),
                                        height: 1.4,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, AirQualityData data, AqiLevel level,
      SharedDataService service) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: level.color),
                          const SizedBox(width: 4),
                          Text('Your Location',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Dar es Salaam',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary)),
                      Text(data.district,
                          style: TextStyle(
                              fontSize: 12, color: palette.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      if (service.isLoading || service.isRefreshing)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: level.color),
                        )
                      else
                        GestureDetector(
                          onTap: () => service.loadData(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: palette.cardLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.border),
                            ),
                            child: Icon(Icons.refresh_rounded,
                                size: 18, color: palette.textSecondary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.cardLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            size: 18, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AqiRing(aqi: data.aqi, size: 190),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: level.color.withOpacity(0.3)),
              ),
              child: Text(level.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: level.color)),
            ),
            const SizedBox(height: 6),
            Text(_getLocalizedAdvice(data.aqi, l10n),
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Updated ${_timeAgo(data.updatedAt)}',
                style: TextStyle(fontSize: 11, color: palette.textMuted)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  _quickStat(context, 'PM2.5',
                      '${data.pollutants[0].value.round()} µg/m³',
                      AppColors.pm25Color),
                  _divider(context),
                  _quickStat(context, 'PM10',
                      '${data.pollutants[1].value.round()} µg/m³',
                      AppColors.pm10Color),
                  _divider(context),
                  _quickStat(context, 'NOx',
                      '${data.pollutants[3].value.toStringAsFixed(2)} PPM',
                      AppColors.no2Color),
                  _divider(context),
                  _quickStat(context, 'VOC',
                      '${data.pollutants[4].value.toStringAsFixed(2)} PPM',
                      AppColors.so2Color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(
      BuildContext context, String label, String value, Color color) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: palette.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
        width: 1,
        height: 28,
        color: context.palette.border.withOpacity(0.5));
  }

  String _timeAgo(DateTime dt) => formatTimeAgo(dt);

  String _getLocalizedAdvice(int aqi, AppLocalizations l10n) {
    if (aqi <= 50) return l10n.aqiAdviceGood;
    if (aqi <= 100) return l10n.aqiAdviceModerate;
    if (aqi <= 150) return l10n.aqiAdviceSensitive;
    if (aqi <= 200) return l10n.aqiAdviceUnhealthy;
    if (aqi <= 300) return l10n.aqiAdviceVery;
    return l10n.aqiAdviceHazardous;
  }

  Widget _getConnectionStateIcon(String state) {
    switch (state) {
      case 'searching':
        return const CircularProgressIndicator(color: AppColors.good);
      case 'locating':
        return const Icon(Icons.location_searching_rounded, size: 48, color: AppColors.good);
      case 'detecting':
        return const Icon(Icons.sensors_rounded, size: 48, color: AppColors.good);
      case 'connecting':
        return const CircularProgressIndicator(color: AppColors.good);
      case 'connected':
        return const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.good);
      case 'no_sensor':
        return const Icon(Icons.sensor_door_rounded, size: 48, color: AppColors.unhealthy);
      case 'error':
        return const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.unhealthy);
      default:
        return const Icon(Icons.help_outline_rounded, size: 48, color: AppColors.moderate);
    }
  }

  String _getConnectionStateText(String state) {
    switch (state) {
      case 'searching':
        return 'Searching for nearby sensors...';
      case 'locating':
        return 'Getting your location...';
      case 'detecting':
        return 'Detecting sensors...';
      case 'connecting':
        return 'Connecting to sensor...';
      case 'connected':
        return 'Connected';
      case 'no_sensor':
        return 'No nearby sensors found';
      case 'error':
        return 'Connection error';
      default:
        return 'Unknown state';
    }
  }
}
