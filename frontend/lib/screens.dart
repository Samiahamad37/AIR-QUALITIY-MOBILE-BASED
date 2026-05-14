import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'air_quality_data.dart';
import 'app_theme.dart';
import 'common_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AirQualityData _data;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _data = getMockAirQualityData();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    // TODO: replace with real API call
    setState(() {
      _data = getMockAirQualityData();
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = _data.level;
    final maxHourlyAqi = _data.hourlyData.map((h) => h.aqi).reduce((a, b) => a > b ? a : b);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: level.color,
          backgroundColor: AppColors.bgCard,
          child: CustomScrollView(
            slivers: [
              // ─── Hero Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHero(level),
              ),

              // ─── Pollutant Metrics Strip ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      MetricChip(
                        icon: Icons.thermostat_rounded,
                        value: '${_data.temperature.toStringAsFixed(1)}°C',
                        label: 'Temperature',
                        color: const Color(0xFFFB923C),
                      ),
                      const SizedBox(width: 8),
                      MetricChip(
                        icon: Icons.water_drop_rounded,
                        value: '${_data.humidity.round()}%',
                        label: 'Humidity',
                        color: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 8),
                      MetricChip(
                        icon: Icons.air_rounded,
                        value: '${_data.windSpeed.toStringAsFixed(1)} km/h',
                        label: 'Wind',
                        color: const Color(0xFF34D399),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Today's AQI Trend ──────────────────────────────────────
              const SliverToBoxAdapter(
                child: SectionHeader(title: "Today's AQI Trend"),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 110,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _data.hourlyData.asMap().entries.map((e) {
                              return HourlyChartBar(
                                data: e.value,
                                maxAqi: maxHourlyAqi,
                                delayMs: e.key * 60,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Pollutants Breakdown ───────────────────────────────────
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Pollutant Breakdown'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    child: Column(
                      children: _data.pollutants.asMap().entries.map((e) {
                        return PollutantBar(
                          pollutant: e.value,
                          delayMs: e.key * 80,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ─── Health Advisory Card ───────────────────────────────────
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Health Advisory'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: level.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: level.color.withOpacity(0.3)),
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
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              color: level.color,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.shortName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: level.textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                level.advice,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: level.textColor.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
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
  }

  Widget _buildHero(AqiLevel level) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
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
                          Text(
                            'Your Location',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _data.city,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _data.district,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_isRefreshing)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: level.color,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _refresh,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.bgCardLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                size: 18, color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AQI Ring
            AqiRing(aqi: _data.aqi, size: 190),

            const SizedBox(height: 12),

            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: level.color.withOpacity(0.3)),
              ),
              child: Text(
                level.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: level.color,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Updated ${_timeAgo(_data.updatedAt)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),

            const SizedBox(height: 20),

            // Quick PM stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  _quickStat('PM2.5', '${_data.pollutants[0].value.round()} µg/m³',
                      AppColors.pm25Color),
                  _divider(),
                  _quickStat('PM10', '${_data.pollutants[1].value.round()} µg/m³',
                      AppColors.pm10Color),
                  _divider(),
                  _quickStat('O₃', '${_data.pollutants[2].value.round()} ppb',
                      AppColors.o3Color),
                  _divider(),
                  _quickStat('NO₂', '${_data.pollutants[3].value.round()} ppb',
                      AppColors.no2Color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.border.withOpacity(0.5),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}