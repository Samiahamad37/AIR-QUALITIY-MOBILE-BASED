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
  int _selectedHours = 24;

  // Real data from API
  List<Map<String, dynamic>> _pollutantHistory = [];
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];
  Map<String, dynamic>? _predictionData;

  final List<String> _pollutants = ['co2', 'nox', 'voc', 'pm25', 'pm10'];
  final List<int> _hourOptions = [24, 48, 168];

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
        api.fetchPredictions(),
      ]);

      final history = results[0] as List<Map<String, dynamic>>;
      final predictionResponse = results[1] as Map<String, dynamic>;
      final hourlyForecast = _buildHourlyForecastFromApi(predictionResponse);
      final dailyForecast = _buildDailyForecastFromHourly(hourlyForecast);

      setState(() {
        _pollutantHistory = history;
        _forecast = hourlyForecast;
        _dailyForecast = dailyForecast;
        _predictionData = predictionResponse;
      });
    } catch (e) {
      // Error handled by main UI
    }
  }

  List<Map<String, dynamic>> _buildHourlyForecastFromApi(
    Map<String, dynamic> data,
  ) {
    final forecast6h = List<dynamic>.from(data['forecast_6h'] as List? ?? []);
    final timestamp = DateTime.parse(data['timestamp'] as String);

    return forecast6h.asMap().entries.map((entry) {
      final hourOffset = entry.key + 1;
      return {
        'timestamp': timestamp.add(Duration(hours: hourOffset)).toIso8601String(),
        'predicted_aqi': entry.value as num,
        'confidence': data['trend_confidence'] ?? 0.0,
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

                            // ── 6h Hourly Forecast ──────────────────────────
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

                            // ── Current Parameters ─────────────────────────────
                            if (_predictionData != null)
                              SliverToBoxAdapter(
                                child: SectionHeader(title: 'Current Parameters'),
                              ),
                            if (_predictionData != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  child: GlassCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Current AQI',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: palette.textSecondary)),
                                            Text(
                                                '${(_predictionData!['current_aqi'] as num).toStringAsFixed(1)}',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: palette.textPrimary)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Trend',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: palette.textSecondary)),
                                            Row(
                                              children: [
                                                Icon(
                                                  (_predictionData!['trend_direction'] == 'rising')
                                                      ? Icons.trending_up
                                                      : Icons.trending_down,
                                                  size: 16,
                                                  color: (_predictionData!['trend_direction'] == 'rising')
                                                      ? AppColors.unhealthy
                                                      : AppColors.good,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                    '${_predictionData!['trend_direction']}',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: palette.textPrimary)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Confidence',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: palette.textSecondary)),
                                            Text(
                                                '${(_predictionData!['trend_confidence'] as num).toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: palette.textPrimary)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 12),
                                        Text('Pollutants',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: palette.textPrimary)),
                                        const SizedBox(height: 12),
                                        _buildPollutantGrid(_predictionData!['pollutants'] as Map<String, dynamic>?),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // // ── 6-Day Forecast ───────────────────────────────
                            // SliverToBoxAdapter(
                            //   child: SectionHeader(
                            //       title: AppLocalizations.of(context)
                            //           .forecast7Day),
                            // ),
                            // SliverToBoxAdapter(
                            //   child: SizedBox(
                            //     height: 130,
                            //     child: ListView.builder(
                            //       scrollDirection: Axis.horizontal,
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 16),
                            //       itemCount: _dailyForecast.length,
                            //       itemBuilder: (_, i) =>
                            //           _DayCard(data: _dailyForecast[i]),
                            //     ),
                            //   ),
                            // ),

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
                                      onTap: () {
                                        setState(() => _selectedHours = h);
                                        _loadPollutantData();
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
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

  Widget _buildPollutantGrid(Map<String, dynamic>? pollutants) {
    if (pollutants == null) return const SizedBox();

    final pollutantLabels = {
      'pm25': 'PM2.5',
      'pm10': 'PM10',
      'co2': 'CO2',
      'no2': 'NO2',
      'voc': 'VOC',
      'humidity': 'Humidity',
      'temperature': 'Temperature',
    };

    final pollutantUnits = {
      'pm25': 'µg/m³',
      'pm10': 'µg/m³',
      'co2': 'PPM',
      'no2': 'PPM',
      'voc': 'PPM',
      'humidity': '%',
      'temperature': '°C',
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, index) {
        final key = pollutants.keys.elementAt(index);
        final value = pollutants[key];
        final label = pollutantLabels[key] ?? key.toUpperCase();
        final unit = pollutantUnits[key] ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.palette.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.border.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textSecondary)),
              const SizedBox(height: 4),
              Text(
                  value is num ? '${value.toStringAsFixed(1)} $unit' : '$value',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary)),
            ],
          ),
        );
      },
    );
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
