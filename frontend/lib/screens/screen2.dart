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
import '/utils/device_labels.dart';
import '/utils/time_utils.dart';
import '/utils/chart_utils.dart';
import 'package:air_quality_monitor/L10n/app_localizations.dart';

const String defaultDevice = 'lands-building';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  String _selectedPollutant = 'co2';
  int _selectedHours = 24;
  String? _trackedDevice;

  // Real data from API
  List<Map<String, dynamic>> _pollutantHistory = [];
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];
  String? _forecastError;
  String? _trendDirection;

  // Cached pollutant series — switching pollutant is instant (no extra API call).
  String? _cachedHistoryDevice;
  int? _cachedHistoryHours;
  Map<String, List<Map<String, dynamic>>> _pollutantsCache = {};

  final List<String> _pollutants = ['co2', 'nox', 'voc', 'pm25', 'pm10'];
  final List<int> _hourOptions = [24, 48, 168];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  void _applyCachedPollutant() {
    _pollutantHistory =
        List<Map<String, dynamic>>.from(_pollutantsCache[_selectedPollutant] ?? []);
  }

  bool get _historyCacheValid {
    final service = context.read<SharedDataService>();
    return _cachedHistoryDevice == service.selectedDevice &&
        _cachedHistoryHours == _selectedHours &&
        _pollutantsCache.containsKey(_selectedPollutant);
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadForecast(), _loadHistory()]);
  }

  Future<void> _loadHistory() async {
    final service = context.read<SharedDataService>();
    final deviceId = service.selectedDevice;

    try {
      final data = await api.fetchAllPollutants(
        deviceId: deviceId,
        hours: _selectedHours,
      );
      final raw = data['pollutants'];
      final parsed = <String, List<Map<String, dynamic>>>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value is List) {
            parsed[key.toString()] =
                List<Map<String, dynamic>>.from(value.cast<Map>());
          }
        });
      }

      if (!mounted) return;
      setState(() {
        _pollutantsCache = parsed;
        _cachedHistoryDevice = deviceId;
        _cachedHistoryHours = _selectedHours;
        _applyCachedPollutant();
      });
    } catch (e) {
      debugPrint('Failed to load pollutant history: $e');
      if (!mounted) return;
      setState(() {
        _forecastError ??= e.toString();
      });
    }
  }

  Future<void> _loadForecast() async {
    final service = context.read<SharedDataService>();
    final deviceId = service.selectedDevice;

    try {
      final predictionResponse = await api.fetchPredictions(deviceId: deviceId);
      final hourlyForecast =
          _buildHourlyForecastFromApi(predictionResponse);
      final dailyForecast = _buildDailyForecastFromHourly(hourlyForecast);

      if (!mounted) return;
      setState(() {
        _forecast = hourlyForecast;
        _dailyForecast = dailyForecast;
        _trendDirection = predictionResponse['trend_direction'] as String?;
      });
    } catch (e) {
      debugPrint('Failed to load predictions: $e');
      if (!mounted) return;
      setState(() {
        _forecastError ??= e.toString();
      });
    }
  }

  void _selectPollutant(String pollutant) {
    if (pollutant == _selectedPollutant) return;
    setState(() {
      _selectedPollutant = pollutant;
      if (_historyCacheValid) {
        _applyCachedPollutant();
      }
    });
    if (!_historyCacheValid) {
      _loadHistory();
    }
  }

  void _selectHours(int hours) {
    if (hours == _selectedHours) return;
    setState(() => _selectedHours = hours);
    _loadHistory();
  }

  List<Map<String, dynamic>> _buildHourlyForecastFromApi(
    Map<String, dynamic> data,
  ) {
    final forecast6h = List<dynamic>.from(data['forecast_6h'] as List? ?? []);
    final pm25Forecast =
        List<dynamic>.from(data['pm25_forecast_6h'] as List? ?? []);
    final pm10Forecast =
        List<dynamic>.from(data['pm10_forecast_6h'] as List? ?? []);
    final timestamp = DateTime.parse(data['timestamp'] as String).toLocal();
    final now = DateTime.now();

    return forecast6h.asMap().entries.map((entry) {
      final hourOffset = entry.key + 1;
      final forecastTime = timestamp.add(Duration(hours: hourOffset));
      if (!forecastTime.isAfter(now)) return null;

      final pm25 = entry.key < pm25Forecast.length
          ? (pm25Forecast[entry.key] as num?)?.toDouble()
          : null;
      final pm10 = entry.key < pm10Forecast.length
          ? (pm10Forecast[entry.key] as num?)?.toDouble()
          : null;

      final predictedAqi = (pm25 != null && pm10 != null)
          ? _aqiFromPm(pm25, pm10).toDouble()
          : (entry.value as num).toDouble();

      return {
        'timestamp': forecastTime.toIso8601String(),
        'predicted_aqi': predictedAqi,
        'pm25': pm25,
        'pm10': pm10,
      };
    }).whereType<Map<String, dynamic>>().toList();
  }

  int _aqiFromPm(double pm25, double pm10) {
    final fromPm25 = (pm25 / 35 * 100).round().clamp(0, 500);
    final fromPm10 = (pm10 / 150 * 100).round().clamp(0, 500);
    return fromPm25 > fromPm10 ? fromPm25 : fromPm10;
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
        if (_trackedDevice != service.selectedDevice) {
          _trackedDevice = service.selectedDevice;
          _pollutantsCache = {};
          _cachedHistoryDevice = null;
          _cachedHistoryHours = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadAll();
          });
        }

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

                            // ── 6h Hourly Forecast ──────────────────────────
                            if (_forecast.isEmpty && _forecastError != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.moderate.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.moderate.withOpacity(0.35),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).forecastMlNotice,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: context.palette.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: SectionHeader(
                                  title: '6-Hour Forecast'),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GlassCard(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                  child: Column(children: [
                                    AqiTrendBadge(direction: _trendDirection),
                                    if (_trendDirection != null)
                                      const SizedBox(height: 12),
                                    SizedBox(
                                      height: 200,
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

                            // ── PM2.5 / PM10 Forecast ───────────────────────
                            SliverToBoxAdapter(
                              child: SectionHeader(
                                title: 'PM2.5 & PM10 Forecast',
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GlassCard(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 16, 12, 12),
                                  child: PmForecastDualChart(forecast: _forecast),
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
                                        onTap: () => _selectPollutant(p),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 100),
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

                            // Hours selector
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: _hourOptions.map((h) {
                                    final isSelected = h == _selectedHours;
                                    final label = h == 24
                                        ? '24h'
                                        : h == 48
                                            ? '48h'
                                            : '7d';
                                    return GestureDetector(
                                      onTap: () => _selectHours(h),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 100),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.good.withOpacity(0.15)
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
                                          label,
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
                                  child: SizedBox(
                                    height: 220,
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.forecastTitle,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      deviceDisplayName(service.selectedDevice),
                      style:
                          TextStyle(fontSize: 13, color: palette.textSecondary),
                    ),
                  ]),
                  GestureDetector(
                    onTap: _loadAll,
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
              if (service.devices.length > 1) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: service.selectedDevice,
                  dropdownColor: palette.card,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.homeLocation,
                    labelStyle: TextStyle(color: palette.textSecondary),
                    prefixIcon: Icon(Icons.location_searching_rounded,
                        size: 20, color: palette.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.good, width: 1.5),
                    ),
                    filled: true,
                    fillColor: palette.cardLight,
                  ),
                  items: service.devices
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(deviceDisplayName(d),
                                style:
                                    TextStyle(color: palette.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      service.setSelectedDevice(val);
                      _pollutantsCache = {};
                      _cachedHistoryDevice = null;
                      _cachedHistoryHours = null;
                      _loadAll();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyChart() {
    if (_forecast.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).forecastMlNotice,
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final spots = _forecast.asMap().entries.map((e) {
      final aqi = (e.value['predicted_aqi'] as num).toDouble();
      return FlSpot(e.key.toDouble(), aqi);
    }).toList();

    final maxAqi = spots.map((s) => s.y).reduce(max).clamp(50.0, 300.0);
    final palette = context.palette;
    final maxX = (_forecast.length - 1).toDouble();

    String hourLabel(int i) {
      final ts =
          DateTime.parse(_forecast[i]['timestamp'].toString()).toLocal();
      return DateFormat('ha').format(ts).toLowerCase();
    }

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxAqi > 100 ? 50 : 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxAqi > 100 ? 50 : 25,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (val, _) {
                final i = val.round();
                if (i < 0 || i >= _forecast.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    hourLabel(i),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
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
        minX: 0,
        maxX: maxX,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.good,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.good.withOpacity(0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: maxAqi.toDouble(),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchSpotThreshold: 30,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              final aqi = barData.spots[index].y.toInt();
              return TouchedSpotIndicatorData(
                FlLine(
                  color: palette.textSecondary.withOpacity(0.45),
                  strokeWidth: 1.5,
                  dashArray: [5, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, i) =>
                      FlDotCirclePainter(
                    radius: 7,
                    color: getAqiLevel(aqi).color,
                    strokeWidth: 2.5,
                    strokeColor: palette.card,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => palette.cardLight,
            tooltipBorder: BorderSide(color: palette.border),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final i = spot.spotIndex;
                if (i < 0 || i >= _forecast.length) {
                  return const LineTooltipItem('', TextStyle());
                }
                final aqi =
                    (_forecast[i]['predicted_aqi'] as num?)?.toInt() ?? 0;
                final level = getAqiLevel(aqi);
                return LineTooltipItem(
                  '$aqi',
                  TextStyle(
                    color: level.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatHistoryHour(DateTime dt) {
    final h = dt.hour;
    final meridiem = h < 12 ? 'am' : 'pm';
    final hourDisplay = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hourDisplay$meridiem';
  }

  String _historyTimeLabel(DateTime slotStart, {required bool isCurrent}) {
    if (isCurrent) return 'Now';
    if (_selectedHours >= 168) {
      return DateFormat('EEE').format(slotStart);
    }
    if (_selectedHours >= 48) {
      return '${DateFormat('EEE').format(slotStart)} ${_formatHistoryHour(slotStart)}';
    }
    return _formatHistoryHour(slotStart);
  }

  List<int> _historyAxisTickIndices(int maxX) {
    if (_selectedHours >= 168) {
      return List.generate(maxX + 1, (i) => i);
    }
    if (_selectedHours >= 48) {
      return [0, maxX ~/ 4, maxX ~/ 2, (maxX * 3) ~/ 4, maxX];
    }
    return [0, 6, 12, 18, maxX];
  }

  List<_HistorySlot> _bucketPollutantHistory() {
    final now = DateTime.now();
    final currentHourStart = DateTime(now.year, now.month, now.day, now.hour);
    final todayStart = DateTime(now.year, now.month, now.day);
    final isWeekly = _selectedHours >= 168;
    final slotCount = isWeekly ? 7 : _selectedHours;
    final maxX = slotCount - 1;

    final windowStart = isWeekly
        ? todayStart.subtract(Duration(days: maxX))
        : currentHourStart.subtract(Duration(hours: maxX));

    final raw = _pollutantHistory
        .map((r) {
          final ts = parseApiTimestamp(r['timestamp']);
          final value = (r['value'] as num?)?.toDouble();
          return (ts: ts, value: value);
        })
        .where(
          (p) =>
              !p.ts.isBefore(windowStart) &&
              !p.ts.isAfter(now) &&
              p.value != null &&
              isValidPollutantSample(_selectedPollutant, p.value!),
        )
        .toList();

    final slots = <_HistorySlot>[];
    double? lastValue;

    for (var i = 0; i < slotCount; i++) {
      final slotStart = isWeekly
          ? todayStart.subtract(Duration(days: maxX - i))
          : currentHourStart.subtract(Duration(hours: maxX - i));
      final slotEnd = isWeekly
          ? (i == maxX ? now : slotStart.add(const Duration(days: 1)))
          : (i == maxX ? now : slotStart.add(const Duration(hours: 1)));
      final isCurrent = i == maxX;

      final bucket = raw.where((p) {
        if (p.ts.isBefore(slotStart)) return false;
        if (isCurrent) return !p.ts.isAfter(now);
        return p.ts.isBefore(slotEnd);
      }).toList();

      double? value;
      var carriedForward = false;

      if (bucket.isNotEmpty) {
        final latest = latestReadingInBucket(bucket);
        if (latest != null &&
            isMeaningfulReadingChange(lastValue, latest)) {
          value = latest;
        }
      }

      if (value == null && isCurrent && raw.isNotEmpty) {
        final latestOverall = latestReadingInBucket(raw);
        if (latestOverall != null &&
            isMeaningfulReadingChange(lastValue, latestOverall)) {
          value = latestOverall;
        }
      }

      if (value == null && lastValue != null) {
        value = lastValue;
        carriedForward = true;
      }

      if (value == null) continue;

      if (!carriedForward) {
        lastValue = value;
      }

      slots.add(
        _HistorySlot(
          index: i,
          start: slotStart,
          value: value,
          isCurrent: isCurrent,
          timeLabel: _historyTimeLabel(slotStart, isCurrent: isCurrent),
          carriedForward: carriedForward,
        ),
      );
    }

    return slots;
  }

  int _historyMaxX() {
    if (_selectedHours >= 168) return 6;
    return _selectedHours - 1;
  }

  DateTime _historySlotStartForIndex(int index) {
    final now = DateTime.now();
    final currentHourStart = DateTime(now.year, now.month, now.day, now.hour);
    final todayStart = DateTime(now.year, now.month, now.day);
    final maxX = _historyMaxX();

    if (_selectedHours >= 168) {
      return todayStart.subtract(Duration(days: maxX - index));
    }
    return currentHourStart.subtract(Duration(hours: maxX - index));
  }

  double _defaultHistoryMaxY(String pollutant) {
    switch (pollutant) {
      case 'co2':
        return 100;
      case 'pm25':
        return 50;
      case 'pm10':
        return 100;
      case 'nox':
      case 'voc':
        return 1;
      default:
        return 100;
    }
  }

  Widget _buildHistoryChart() {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);

    final slots = _pollutantHistory.isEmpty
        ? <_HistorySlot>[]
        : _bucketPollutantHistory();
    final hasData = slots.isNotEmpty;

    final maxX = _historyMaxX();
    final tickIndices = _historyAxisTickIndices(maxX);
    final tickIndexSet = tickIndices.toSet();

    final spots = hasData
        ? slots.map((s) => FlSpot(s.index.toDouble(), s.value)).toList()
        : <FlSpot>[];
    final maxY = hasData
        ? spots.map((s) => s.y).reduce(max) * 1.2
        : _defaultHistoryMaxY(_selectedPollutant);
    final yInterval = maxY / 4;

    final chart = LineChart(
      key: ValueKey('history-$_selectedHours-$_selectedPollutant-$hasData'),
      duration: Duration.zero,
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: _selectedHours >= 168 ? 1 : 6,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withOpacity(0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: AppColors.border.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (val, _) => Text(
                val.toStringAsFixed(val == val.roundToDouble() ? 0 : 1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (val, _) {
                final index = val.round();
                if (!tickIndexSet.contains(index)) {
                  return const SizedBox.shrink();
                }

                final label = _historyTimeLabel(
                  _historySlotStartForIndex(index),
                  isCurrent: index == maxX,
                );

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
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
        minX: 0,
        maxX: maxX.toDouble(),
        minY: 0,
        maxY: maxY,
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: maxX.toDouble(),
              color: AppColors.good.withOpacity(0.85),
              strokeWidth: 2,
            ),
          ],
        ),
        lineBarsData: hasData
            ? segmentedLineBars(
                spots,
                color: const Color(0xFF60A5FA),
                barWidth: 2.5,
                showArea: false,
              )
            : const [],
        lineTouchData: LineTouchData(
          enabled: hasData,
          handleBuiltInTouches: hasData,
          touchSpotThreshold: 24,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            if (!hasData) return const <TouchedSpotIndicatorData>[];
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: palette.textSecondary.withOpacity(0.45),
                  strokeWidth: 1.5,
                  dashArray: [5, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, i) =>
                      FlDotCirclePainter(
                    radius: 6,
                    color: const Color(0xFF60A5FA),
                    strokeWidth: 2,
                    strokeColor: palette.card,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => palette.cardLight,
            tooltipBorder: BorderSide(color: palette.border),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                if (idx < 0 || idx >= slots.length) {
                  return const LineTooltipItem('', TextStyle());
                }
                final slot = slots[idx];
                return LineTooltipItem(
                  slot.value.toStringAsFixed(2),
                  TextStyle(
                    color: const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );

    if (!hasData) {
      return Stack(
        alignment: Alignment.center,
        children: [
          chart,
          Text(
            l10n.forecastNoData,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return chart;
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

// ─── History chart bucket ─────────────────────────────────────────────────────

class _HistorySlot {
  final int index;
  final DateTime start;
  final double value;
  final bool isCurrent;
  final String timeLabel;
  final bool carriedForward;

  const _HistorySlot({
    required this.index,
    required this.start,
    required this.value,
    required this.isCurrent,
    required this.timeLabel,
    this.carriedForward = false,
  });
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
