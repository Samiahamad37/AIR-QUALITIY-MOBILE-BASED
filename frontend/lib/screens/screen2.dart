import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/Data/air_quality_data.dart';
import '/services/api_service.dart';
import '/screens/app_theme.dart';
import '/widgets/common_widget.dart';
import '/services/shared_data_service.dart';
import 'package:air_quality_monitor/L10n/app_localizations.dart';

const String defaultDevice = 'lands-building';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  String _selectedPollutant = 'co2';
  int _selectedHours = 6;

  // Real data from API
  List<Map<String, dynamic>> _pollutantHistory = [];
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];

  final List<String> _pollutants = ['co2', 'nox', 'voc', 'pm25', 'pm10'];
  final List<int> _hourOptions = [6];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPollutantData();
    });
  }

  Future<void> _loadPollutantData() async {
    final service = context.read<SharedDataService>();
    try {
      final results = await Future.wait([
        api.fetchPollutantHistory(
          deviceId: service.selectedDevice,
          pollutant: _selectedPollutant,
          hours: _selectedHours,
        ),
        api.fetchPredictions(hours: _selectedHours, hoursAhead: _selectedHours),
      ]);

      final history = results[0] as List<Map<String, dynamic>>;
      final predictionResponse = results[1] as Map<String, dynamic>;
      final hourlyForecast = _buildHourlyForecastFromApi(
        predictionResponse,
        service.selectedDevice,
      );
      final dailyForecast = _buildDailyForecastFromHourly(hourlyForecast);

      setState(() {
        _pollutantHistory = history;
        _forecast = hourlyForecast;
        _dailyForecast = dailyForecast;
      });
    } catch (e) {
      // Error handled by main UI
    }
  }

  List<Map<String, dynamic>> _buildHourlyForecastFromApi(
    Map<String, dynamic> data,
    String deviceId,
  ) {
    final forecast6h = data['forecast_6h'];
    if (forecast6h is List) {
      return forecast6h.asMap().entries.map((entry) {
        final ts = DateTime.now().toLocal().add(Duration(hours: entry.key + 1));
        return {
          'timestamp': ts.toIso8601String(),
          'predicted_aqi': entry.value,
          'confidence': 0.0,
        };
      }).toList();
    }

    final devices =
        List<Map<String, dynamic>>.from(data['devices'] as List? ?? []);
    final device = devices.firstWhere(
      (d) => d['device_id'] == deviceId,
      orElse: () => devices.isNotEmpty ? devices[0] : {},
    );
    final predictions = List<Map<String, dynamic>>.from(
      device['predictions'] as List? ?? [],
    );

    return predictions.map((entry) {
      return {
        'timestamp': entry['timestamp'],
        'predicted_aqi': entry['value'],
        'confidence': entry['confidence'] ?? 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildDailyForecastFromHourly(
    List<Map<String, dynamic>> hourlyForecast,
  ) {
    if (hourlyForecast.isEmpty) return [];

    final now = DateTime.now().toLocal();
    final grouped = <DateTime, List<Map<String, dynamic>>>{};

    for (final item in hourlyForecast) {
      final ts = DateTime.parse(item['timestamp'].toString()).toLocal();
      final date = DateTime(ts.year, ts.month, ts.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final daily = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return daily.take(7).map((entry) {
      final values = entry.value
          .map((item) => (item['predicted_aqi'] as num?)?.toInt() ?? 0)
          .toList();
      final minAqi = values.reduce(min);
      final maxAqi = values.reduce(max);
      final avgAqi = (values.reduce((a, b) => a + b) / values.length).round();
      final level = getAqiLevel(avgAqi);
      final isToday = entry.key == DateTime(now.year, now.month, now.day);
      final dayName = isToday
          ? 'Today'
          : entry.key == DateTime(now.year, now.month, now.day + 1)
              ? 'Tomorrow'
              : DateFormat('EEE').format(entry.key);

      return {
        'date': entry.key.toIso8601String(),
        'day_name': dayName,
        'predicted_aqi': avgAqi,
        'aqi_min': minAqi,
        'aqi_max': maxAqi,
        'condition': level.shortName,
        'is_today': isToday,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharedDataService>(
      builder: (context, service, _) {
        final palette = context.palette;
        final bg = Theme.of(context).scaffoldBackgroundColor;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: context.appOverlayStyle,
          child: Scaffold(
            backgroundColor: bg,
            body: service.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.good))
                : service.error != null
                    ? _buildError(context, service)
                    : RefreshIndicator(
                        onRefresh: () => service.loadData(),
                        color: AppColors.good,
                        backgroundColor: palette.card,
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                                child: _buildHeader(context, service)),

                            if (service.devices.length > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  child: DropdownButtonFormField<String>(
                                    value: service.selectedDevice,
                                    dropdownColor: palette.card,
                                    style:
                                        TextStyle(color: palette.textPrimary),
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(context)
                                          .homeLocation,
                                      labelStyle: TextStyle(
                                          color: palette.textSecondary),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: palette.border),
                                      ),
                                      filled: true,
                                      fillColor: palette.card,
                                    ),
                                    items: service.devices
                                        .map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text(d,
                                                  style: TextStyle(
                                                      color:
                                                          palette.textPrimary)),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        service.setSelectedDevice(val);
                                        _loadPollutantData();
                                      }
                                    },
                                  ),
                                ),
                              ),

                            // ── 6-Hour Forecast ─────────────────────────────
                            SliverToBoxAdapter(
                              child: SectionHeader(title: '6-Hour Forecast'),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GlassCard(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                  child: Column(children: [
                                    SizedBox(
                                      height: 160,
                                      child: _buildHourlyChart(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _chartLegend(
                                            context,
                                            AppColors.good,
                                            AppLocalizations.of(context)
                                                .aqiGood),
                                        _chartLegend(
                                            context,
                                            AppColors.moderate,
                                            AppLocalizations.of(context)
                                                .aqiModerate),
                                        _chartLegend(
                                            context,
                                            AppColors.sensitiveGroups,
                                            AppLocalizations.of(context)
                                                .aqiSensitive),
                                        _chartLegend(
                                            context,
                                            AppColors.unhealthy,
                                            AppLocalizations.of(context)
                                                .aqiUnhealthy),
                                      ],
                                    ),
                                  ]),
                                ),
                              ),
                            ),

                            // ── Historical Trends ────────────────────────────
                            SliverToBoxAdapter(
                              child: SectionHeader(
                                  title: AppLocalizations.of(context)
                                      .forecastHistoricalTrends),
                            ),

                            // Pollutant selector
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _pollutants.map((p) {
                                      final isSelected =
                                          p == _selectedPollutant;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(
                                              () => _selectedPollutant = p);
                                          _loadPollutantData();
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.good
                                                    .withOpacity(0.15)
                                                : palette.card,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.good
                                                  : palette.border
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            p.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.good
                                                  : palette.textSecondary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                                child: SizedBox(height: 12)),

                            // Line chart
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GlassCard(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 8, 12),
                                  child: _pollutantHistory.isEmpty
                                      ? SizedBox(
                                          height: 180,
                                          child: Center(
                                            child: Text(
                                                AppLocalizations.of(context)
                                                    .forecastNoData,
                                                style: TextStyle(
                                                    color:
                                                        palette.textSecondary)),
                                          ),
                                        )
                                      : SizedBox(
                                          height: 180,
                                          child: _buildHistoryChart(),
                                        ),
                                ),
                              ),
                            ),

                            const SliverToBoxAdapter(
                                child: SizedBox(height: 100)),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, SharedDataService service) {
    final palette = context.palette;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).forecastTitle,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  service.selectedDevice,
                  style: TextStyle(fontSize: 13, color: palette.textSecondary),
                ),
              ]),
              GestureDetector(
                onTap: _loadPollutantData,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyChart() {
    final spots = _forecast.asMap().entries.map((e) {
      final aqi = (e.value['predicted_aqi'] as num).toDouble();
      return FlSpot(e.key.toDouble(), aqi);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 50,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i >= _forecast.length) return const SizedBox();
                final ts = DateTime.parse(_forecast[i]['timestamp'].toString())
                    .toLocal();
                return Text(
                  DateFormat('ha').format(ts).toLowerCase(),
                  style:
                      const TextStyle(fontSize: 9, color: AppColors.textMuted),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.good,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.good.withOpacity(0.08),
            ),
          ),
        ],
        minY: 0,
        maxY: 200,
      ),
    );
  }

  Widget _buildHistoryChart() {
    if (_pollutantHistory.isEmpty) return const SizedBox();

    final spots = _pollutantHistory.asMap().entries.map((e) {
      final value = (e.value['value'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, _) => Text(
                val.toStringAsFixed(1),
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (_pollutantHistory.length / 4).ceilToDouble(),
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i >= _pollutantHistory.length) return const SizedBox();
                final ts =
                    DateTime.parse(_pollutantHistory[i]['timestamp'].toString())
                        .toLocal();
                return Text(
                  DateFormat('ha').format(ts).toLowerCase(),
                  style:
                      const TextStyle(fontSize: 9, color: AppColors.textMuted),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF60A5FA),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF60A5FA).withOpacity(0.08),
            ),
          ),
        ],
        minY: 0,
        maxY: maxY * 1.2,
      ),
    );
  }

  Widget _buildError(BuildContext context, SharedDataService service) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, color: palette.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(service.error ?? 'An error occurred',
              style: TextStyle(color: palette.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => service.loadData(),
              child: Text(AppLocalizations.of(context).errorRetry)),
        ]),
      ),
    );
  }

  Widget _chartLegend(BuildContext context, Color color, String label) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(fontSize: 9, color: context.palette.textSecondary)),
    ]);
  }
}

// ─── Day Card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DayCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final aqi = (data['predicted_aqi'] as num).toInt();
    final level = getAqiLevel(aqi);
    final isToday = data['is_today'] == true;

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? level.color.withOpacity(0.15) : palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? level.color.withOpacity(0.4)
              : palette.border.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data['day_name'].toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isToday ? level.color : palette.textSecondary,
              )),
          const SizedBox(height: 8),
          Text('$aqi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: level.color,
              )),
          const SizedBox(height: 4),
          Text(data['condition'].toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: palette.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            '${data['aqi_min']}-${data['aqi_max']}',
            style: TextStyle(fontSize: 9, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
