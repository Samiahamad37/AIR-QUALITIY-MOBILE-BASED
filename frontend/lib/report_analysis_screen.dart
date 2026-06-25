import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'air_quality_data.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'shared_data_service.dart';

/// Reports & Analysis screen — only reachable by signed-in users.
///
/// Summarizes recent air-quality readings for the selected device: average /
/// min / max AQI, dominant pollutant, an AQI trend chart and per-pollutant
/// averages, plus a short written assessment.
class ReportAnalysisScreen extends StatefulWidget {
  const ReportAnalysisScreen({super.key});

  @override
  State<ReportAnalysisScreen> createState() => _ReportAnalysisScreenState();
}

class _ReportAnalysisScreenState extends State<ReportAnalysisScreen> {
  static const _periods = <String, int>{'24H': 24, '7D': 168, '30D': 720};

  String _period = '24H';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _readings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final device = context.read<SharedDataService>().selectedDevice;
      final readings = await api.fetchDeviceReadings(
        deviceId: device,
        hours: _periods[_period]!,
      );
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── AQI helpers (consistent with SharedDataService) ──────────────────────────

  int _quickAqi(Map<String, dynamic> r) {
    final pm25 = (r['pm25'] as num?)?.toDouble() ?? 0;
    final pm10 = (r['pm10'] as num?)?.toDouble() ?? 0;
    final nox = (r['nox'] as num?)?.toDouble() ?? 0;
    final a = (pm25 / 35 * 100).round().clamp(0, 500);
    final b = (pm10 / 150 * 100).round().clamp(0, 500);
    final c = (nox / 0.1 * 100).round().clamp(0, 500);
    return [a, b, c].reduce((x, y) => x > y ? x : y);
  }

  double _avg(Iterable<num> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reports & Analysis'),
        foregroundColor: palette.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.good,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _greeting(palette, auth),
                const SizedBox(height: 16),
                _periodSelector(palette),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.good),
                    ),
                  )
                else if (_error != null)
                  _errorView(palette)
                else if (_readings.isEmpty)
                  _emptyView(palette)
                else
                  ..._report(palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _greeting(AppPalette palette, AuthService auth) {
    final device = context.watch<SharedDataService>().selectedDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi ${auth.username ?? 'there'},',
          style: TextStyle(
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Air quality report — $device',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _periodSelector(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: _periods.keys.map((p) {
          final selected = p == _period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (p == _period) return;
                setState(() => _period = p);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.good : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : palette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _report(AppPalette palette) {
    final aqis = _readings.map(_quickAqi).toList();
    final avgAqi = _avg(aqis).round();
    final maxAqi = aqis.reduce((a, b) => a > b ? a : b);
    final minAqi = aqis.reduce((a, b) => a < b ? a : b);
    final level = getAqiLevel(avgAqi);

    final pollutantAverages = <String, double>{
      'PM2.5': _avg(_readings.map((r) => (r['pm25'] as num?)?.toDouble() ?? 0)),
      'PM10': _avg(_readings.map((r) => (r['pm10'] as num?)?.toDouble() ?? 0)),
      'CO2': _avg(_readings.map((r) => (r['co2'] as num?)?.toDouble() ?? 0)),
      'NOx': _avg(_readings.map((r) => (r['nox'] as num?)?.toDouble() ?? 0)),
      'VOC': _avg(_readings.map((r) => (r['voc'] as num?)?.toDouble() ?? 0)),
    };

    return [
      _summaryGrid(palette, avgAqi, maxAqi, minAqi, level),
      const SizedBox(height: 24),
      _sectionTitle(palette, 'AQI Trend'),
      const SizedBox(height: 12),
      _chartCard(palette),
      const SizedBox(height: 24),
      _sectionTitle(palette, 'Pollutant Averages'),
      const SizedBox(height: 12),
      _pollutantCard(palette, pollutantAverages),
      const SizedBox(height: 24),
      _sectionTitle(palette, 'Analysis'),
      const SizedBox(height: 12),
      _analysisCard(palette, avgAqi, maxAqi, level, pollutantAverages),
    ];
  }

  Widget _summaryGrid(
    AppPalette palette,
    int avg,
    int max,
    int min,
    AqiLevel level,
  ) {
    return Row(
      children: [
        Expanded(
          child: _statCard(palette, 'Average AQI', '$avg', level.shortName,
              level.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(palette, 'Peak AQI', '$max',
              getAqiLevel(max).shortName, getAqiLevel(max).color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(palette, 'Lowest AQI', '$min',
              getAqiLevel(min).shortName, getAqiLevel(min).color),
        ),
      ],
    );
  }

  Widget _statCard(
    AppPalette palette,
    String label,
    String value,
    String tag,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: palette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(AppPalette palette) {
    final ordered = _readings.reversed.toList();
    final spots = ordered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _quickAqi(e.value).toDouble());
    }).toList();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: palette.border.withOpacity(0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (val, _) => Text(
                  val.toInt().toString(),
                  style: TextStyle(fontSize: 9, color: palette.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (ordered.length / 4).ceilToDouble().clamp(1, 9999),
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= ordered.length) return const SizedBox();
                  final ts =
                      DateTime.tryParse(ordered[i]['timestamp'].toString())
                          ?.toLocal();
                  if (ts == null) return const SizedBox();
                  final fmt = _period == '24H' ? 'ha' : 'd/M';
                  return Text(
                    DateFormat(fmt).format(ts).toLowerCase(),
                    style: TextStyle(fontSize: 9, color: palette.textMuted),
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
                color: AppColors.good.withOpacity(0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: (maxY * 1.2).clamp(50, double.infinity),
        ),
      ),
    );
  }

  Widget _pollutantCard(AppPalette palette, Map<String, double> averages) {
    const maxSafe = <String, double>{
      'PM2.5': 35,
      'PM10': 150,
      'CO2': 1000,
      'NOx': 0.1,
      'VOC': 1.0,
    };
    const colors = <String, Color>{
      'PM2.5': AppColors.pm25Color,
      'PM10': AppColors.pm10Color,
      'CO2': AppColors.o3Color,
      'NOx': AppColors.no2Color,
      'VOC': AppColors.so2Color,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: averages.entries.map((e) {
          final ratio = (e.value / (maxSafe[e.key] ?? 1)).clamp(0.0, 1.0);
          final color = colors[e.key] ?? AppColors.good;
          final precision = e.value < 10 ? 2 : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      e.value.toStringAsFixed(precision),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: palette.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _analysisCard(
    AppPalette palette,
    int avg,
    int max,
    AqiLevel level,
    Map<String, double> averages,
  ) {
    final dominant = averages.entries
        .map((e) => MapEntry(
            e.key,
            e.value /
                (const {
                      'PM2.5': 35.0,
                      'PM10': 150.0,
                      'CO2': 1000.0,
                      'NOx': 0.1,
                      'VOC': 1.0,
                    }[e.key] ??
                    1)))
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final summary =
        'Over the selected period the average AQI was $avg (${level.name}), '
        'peaking at $max. The dominant pollutant was $dominant. ${level.advice}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: level.color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppPalette palette, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
          letterSpacing: -0.3,
        ),
      );

  Widget _errorView(AppPalette palette) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: palette.textMuted),
              const SizedBox(height: 12),
              Text(
                'Could not load report data',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView(AppPalette palette) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: palette.textMuted),
              const SizedBox(height: 12),
              Text(
                'No readings for this period',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      );
}
