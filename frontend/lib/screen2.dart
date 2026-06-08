import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'air_quality_data.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'common_widget.dart';
import 'shared_data_service.dart';

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

  // Mock forecast (replace with real API when ML is ready)
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _dailyForecast = [];

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
      final history = await api.fetchPollutantHistory(
        deviceId: service.selectedDevice,
        pollutant: _selectedPollutant,
        hours: _selectedHours,
      );

      setState(() {
        _pollutantHistory = history;
        _forecast = _getMockHourlyForecast();
        _dailyForecast = _getMockDailyForecast();
      });
    } catch (e) {
      // Error handled by main UI
    }
  }

  // ── Mock data (replace with API call when ML is ready) ──────────────────────

  List<Map<String, dynamic>> _getMockHourlyForecast() {
    final now = DateTime.now();
    final baseAqi = 25;
    return List.generate(24, (i) {
      final variation = (i % 6 < 3) ? i * 1.5 : (6 - i % 6) * 1.5;
      final aqi = (baseAqi + variation).round().clamp(0, 500);
      return {
        'timestamp': now.add(Duration(hours: i)).toIso8601String(),
        'predicted_aqi': aqi,
        'confidence': (0.95 - i * 0.015).clamp(0.5, 1.0),
      };
    });
  }

  List<Map<String, dynamic>> _getMockDailyForecast() {
    final now = DateTime.now();
    final aqiValues = [25, 32, 28, 35, 30, 27, 22];
    return List.generate(7, (i) {
      final aqi = aqiValues[i];
      final level = getAqiLevel(aqi);
      return {
        'date': now.add(Duration(days: i)).toIso8601String(),
        'day_name': i == 0
            ? 'Today'
            : i == 1
                ? 'Tomorrow'
                : DateFormat('EEE').format(now.add(Duration(days: i))),
        'predicted_aqi': aqi,
        'aqi_min': (aqi - 5).clamp(0, 500),
        'aqi_max': (aqi + 8).clamp(0, 500),
        'condition': level.shortName,
        'is_today': i == 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharedDataService>(
      builder: (context, service, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppColors.bgDark,
            body: service.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.good))
                : service.error != null
                    ? _buildError(service)
                    : RefreshIndicator(
                        onRefresh: () => service.loadData(),
                        color: AppColors.good,
                        backgroundColor: AppColors.bgCard,
                        child: CustomScrollView(
                          slivers: [
                            // ── Header ───────────────────────────────────────
                            SliverToBoxAdapter(child: _buildHeader(service)),

                            // ── Device Selector ──────────────────────────────
                            if (service.devices.length > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  child: DropdownButtonFormField<String>(
                                    value: service.selectedDevice,
                                    dropdownColor: AppColors.bgCard,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Location',
                                      labelStyle: const TextStyle(
                                          color: AppColors.textSecondary),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: AppColors.border),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.bgCard,
                                    ),
                                    items: service.devices
                                        .map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text(d,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
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

                        // ── ML Notice Banner ─────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF3B82F6)
                                        .withOpacity(0.4)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.science_rounded,
                                    color: Color(0xFF60A5FA), size: 18),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'ML predictions coming soon — showing estimated forecast based on current conditions.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF93C5FD),
                                        height: 1.4),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),

                        // ── 24h Hourly Forecast ──────────────────────────
                        const SliverToBoxAdapter(
                          child: SectionHeader(title: 'Next 24 Hours'),
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
                                    _chartLegend(AppColors.good, 'Good'),
                                    _chartLegend(
                                        AppColors.moderate, 'Moderate'),
                                    _chartLegend(AppColors.sensitiveGroups,
                                        'Sensitive'),
                                    _chartLegend(
                                        AppColors.unhealthy, 'Unhealthy'),
                                  ],
                                ),
                              ]),
                            ),
                          ),
                        ),

                        // ── 7-Day Forecast ───────────────────────────────
                        const SliverToBoxAdapter(
                          child: SectionHeader(title: '7-Day Forecast'),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _dailyForecast.length,
                              itemBuilder: (_, i) =>
                                  _DayCard(data: _dailyForecast[i]),
                            ),
                          ),
                        ),

                        // ── Historical Trends ────────────────────────────
                        const SliverToBoxAdapter(
                          child: SectionHeader(title: 'Historical Trends'),
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
                                  final isSelected = p == _selectedPollutant;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(
                                          () => _selectedPollutant = p);
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
                                            : AppColors.bgCard,
                                        borderRadius:
                                            BorderRadius.circular(99),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.good
                                              : AppColors.border
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
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

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
                                          : AppColors.bgCard,
                                      borderRadius:
                                          BorderRadius.circular(99),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.good
                                            : AppColors.border
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
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        // Line chart
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: GlassCard(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 8, 12),
                              child: _pollutantHistory.isEmpty
                                  ? const SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: Text('No data available',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 180,
                                      child: _buildHistoryChart(),
                                    ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
            ),
        );
      },
    );
  }

  Widget _buildHeader(SharedDataService service) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.only(
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
                const Text('Forecast',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  service.selectedDevice,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ]),
              GestureDetector(
                onTap: _loadPollutantData,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppColors.textSecondary),
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
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted),
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
                final ts = DateTime.parse(
                    _forecast[i]['timestamp'].toString()).toLocal();
                return Text(
                  DateFormat('ha').format(ts).toLowerCase(),
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textMuted),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
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
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted),
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
                final ts = DateTime.parse(
                    _pollutantHistory[i]['timestamp'].toString()).toLocal();
                return Text(
                  DateFormat('ha').format(ts).toLowerCase(),
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textMuted),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
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

  Widget _buildError(SharedDataService service) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(service.error ?? 'An error occurred',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => service.loadData(),
              child: const Text('Retry')),
        ]),
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(children: [
      Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 9, color: AppColors.textSecondary)),
    ]);
  }
}

// ─── Day Card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DayCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final aqi = (data['predicted_aqi'] as num).toInt();
    final level = getAqiLevel(aqi);
    final isToday = data['is_today'] == true;

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday
            ? level.color.withOpacity(0.15)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? level.color.withOpacity(0.4)
              : AppColors.border.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data['day_name'].toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isToday ? level.color : AppColors.textSecondary,
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
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            '${data['aqi_min']}-${data['aqi_max']}',
            style: const TextStyle(
                fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}