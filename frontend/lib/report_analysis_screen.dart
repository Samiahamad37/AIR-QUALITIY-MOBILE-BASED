import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'air_quality_data.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'shared_data_service.dart';
import 'L10n/app_localizations.dart';



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
  Map<String, List<Map<String, dynamic>>> _deviceReadings = {};
  bool _isLoadingComparison = true;
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _loadDeviceComparison();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final device = context.read<SharedDataService>().selectedDevice;
      print('Loading data for device: $device, hours: ${_periods[_period]}');
      final readings = await api.fetchDeviceReadings(
        deviceId: device,
        hours: _periods[_period]!,
      );
      print('Received ${readings.length} readings');
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceComparison() async {
    setState(() {
      _isLoadingComparison = true;
    });
    try {
      final devices = await api.fetchDevices();
      final readingsMap = <String, List<Map<String, dynamic>>>{};
      
      for (final device in devices) {
        try {
          final readings = await api.fetchDeviceReadings(
            deviceId: device,
            hours: _periods[_period]!,
          );
          readingsMap[device] = readings;
        } catch (e) {
          print('Error loading data for device $device: $e');
          readingsMap[device] = [];
        }
      }
      
      if (!mounted) return;
      setState(() {
        _deviceReadings = readingsMap;
        _isLoadingComparison = false;
      });
    } catch (e) {
      print('Error loading device comparison: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingComparison = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExportingPdf = true;
    });
    
    try {
      final device = context.read<SharedDataService>().selectedDevice;
      
      final pdf = pw.Document();
      
      // Calculate statistics
      final aqis = _readings.map(_quickAqi).toList();
      final avgAqi = aqis.isEmpty ? 0 : _avg(aqis).round();
      final maxAqi = aqis.isEmpty ? 0 : aqis.reduce((a, b) => a > b ? a : b);
      final minAqi = aqis.isEmpty ? 0 : aqis.reduce((a, b) => a < b ? a : b);
      final level = getAqiLevel(avgAqi);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  title: 'Air Quality Report',
                  child: pw.Text('Air Quality Report'),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Device: $device'),
                pw.Text('Period: $_period'),
                pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 20),
                pw.Text('Summary Statistics', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Average AQI: $avgAqi (${level.name})'),
                pw.Text('Maximum AQI: $maxAqi'),
                pw.Text('Minimum AQI: $minAqi'),
                pw.Text('Total Readings: ${_readings.length}'),
                pw.SizedBox(height: 20),
                pw.Text('AQI Level: ${level.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Advice: ${level.advice}'),
              ],
            );
          },
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/air_quality_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to $path')),
      );
    } catch (e) {
      print('Error exporting PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExportingPdf = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExportingCsv = true;
    });
    
    try {
      final device = context.read<SharedDataService>().selectedDevice;
      
      // Create CSV data
      final List<List<dynamic>> rows = [
        ['Air Quality Report'],
        ['Device', device],
        ['Period', _period],
        ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
        [],
        ['Summary Statistics'],
        ['Average AQI', _readings.map(_quickAqi).isEmpty ? 0 : _avg(_readings.map(_quickAqi)).round()],
        ['Maximum AQI', _readings.map(_quickAqi).isEmpty ? 0 : _readings.map(_quickAqi).reduce((a, b) => a > b ? a : b)],
        ['Minimum AQI', _readings.map(_quickAqi).isEmpty ? 0 : _readings.map(_quickAqi).reduce((a, b) => a < b ? a : b)],
        ['Total Readings', _readings.length],
        [],
        ['Timestamp', 'PM2.5', 'PM10', 'NOx', 'VOC', 'CO2', 'AQI'],
      ];
      
      // Add reading data
      for (final reading in _readings) {
        rows.add([
          reading['timestamp']?.toString() ?? '',
          reading['pm25']?.toString() ?? '0',
          reading['pm10']?.toString() ?? '0',
          reading['nox']?.toString() ?? '0',
          reading['voc']?.toString() ?? '0',
          reading['co2']?.toString() ?? '0',
          _quickAqi(reading),
        ]);
      }
      
      final csvData = const ListToCsvConverter().convert(rows);
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/air_quality_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to $path')),
      );
    } catch (e) {
      print('Error exporting CSV: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isExportingCsv = false;
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
    return list.fold<num>(0, (a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final auth = context.watch<AuthService>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.reportTitle),
        foregroundColor: palette.textPrimary,
        actions: [
          IconButton(
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.good,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _isExportingPdf || _isExportingCsv || _isLoading || _readings.isEmpty
                ? null
                : _exportPdf,
            tooltip: l10n.reportExportPdf,
          ),
          IconButton(
            icon: _isExportingCsv
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.good,
                    ),
                  )
                : const Icon(Icons.table_view_rounded),
            onPressed: _isExportingCsv || _isExportingPdf || _isLoading || _readings.isEmpty
                ? null
                : _exportCsv,
            tooltip: l10n.reportExportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _load,
            tooltip: l10n.errorRetry,
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
                  _errorView(palette, l10n)
                else if (_readings.isEmpty)
                  _emptyView(palette, l10n)
                else
                  ..._report(palette, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _greeting(AppPalette palette, AuthService auth) {
    final device = context.watch<SharedDataService>().selectedDevice;
    final l10n = AppLocalizations.of(context);
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
          '${l10n.reportTitle} — $device',
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
                _loadDeviceComparison();
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

  List<Widget> _report(AppPalette palette, AppLocalizations l10n) {
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
      _summaryGrid(palette, avgAqi, maxAqi, minAqi, level, _readings.length),
      const SizedBox(height: 24),
      _sectionTitle(palette, l10n.reportAqiTrend),
      const SizedBox(height: 12),
      _chartCard(palette),
      const SizedBox(height: 24),
      _sectionTitle(palette, l10n.reportPollutantAverages),
      const SizedBox(height: 12),
      _pollutantCard(palette, pollutantAverages),
      const SizedBox(height: 24),
      _sectionTitle(palette, l10n.reportTimeOfDay),
      const SizedBox(height: 12),
      _timeOfDayCard(palette),
      const SizedBox(height: 24),
      _sectionTitle(palette, l10n.reportDeviceComparison),
      const SizedBox(height: 12),
      _deviceComparisonCard(palette),
      const SizedBox(height: 24),
      _sectionTitle(palette, l10n.reportAnalysis),
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
    int totalReadings,
  ) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(palette, l10n.reportTotalReadings, '$totalReadings',
                  '', AppColors.good),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(palette, l10n.reportAverageAqi, '$avg',
                  level.shortName, level.color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(palette, l10n.reportBestDay, '$min',
                  getAqiLevel(min).shortName, getAqiLevel(min).color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(palette, l10n.reportWorstDay, '$max',
                  getAqiLevel(max).shortName, getAqiLevel(max).color),
            ),
          ],
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
    final avgAqi = _avg(spots.map((s) => s.y));

    // Color based on AQI level
    Color _getAqiColor(double aqi) {
      if (aqi <= 50) return AppColors.good;
      if (aqi <= 100) return AppColors.moderate;
      if (aqi <= 150) return AppColors.sensitiveGroups;
      if (aqi <= 200) return AppColors.unhealthy;
      if (aqi <= 300) return AppColors.veryUnhealthy;
      return AppColors.hazardous;
    }

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
              color: _getAqiColor(avgAqi),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: _getAqiColor(avgAqi).withOpacity(0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: (maxY * 1.2).clamp(50, double.infinity),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => palette.card,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final aqi = spot.y.toInt();
                  final level = getAqiLevel(aqi);
                  return LineTooltipItem(
                    'AQI: $aqi\n${level.name}',
                    TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double get avgAqi {
    if (_readings.isEmpty) return 0;
    return _avg(_readings.map(_quickAqi));
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

    // Calculate min/max for each pollutant
    final pollutantStats = <String, Map<String, double>>{};
    for (var pollutant in ['PM2.5', 'PM10', 'CO2', 'NOx', 'VOC']) {
      final key = pollutant.toLowerCase();
      final values = _readings.map((r) => (r[key] as num?)?.toDouble() ?? 0).toList();
      if (values.isNotEmpty) {
        pollutantStats[pollutant] = {
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
          'avg': averages[pollutant] ?? 0,
        };
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          // Bar chart
          ...averages.entries.map((e) {
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
          const SizedBox(height: 16),
          // Stats table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.cardLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.border.withOpacity(0.3)),
                    ),
                  ),
                  children: [
                    _tableCell('Pollutant', palette.textPrimary, true),
                    _tableCell('Min', palette.textSecondary, true),
                    _tableCell('Max', palette.textSecondary, true),
                    _tableCell('Avg', palette.textSecondary, true),
                  ],
                ),
                ...pollutantStats.entries.map((entry) {
                  final stats = entry.value;
                  final color = colors[entry.key] ?? AppColors.good;
                  final precision = stats['avg']! < 10 ? 2 : 0;
                  return TableRow(
                    children: [
                      _tableCell(entry.key, color, true),
                      _tableCell(stats['min']!.toStringAsFixed(precision), palette.textSecondary, false),
                      _tableCell(stats['max']!.toStringAsFixed(precision), palette.textSecondary, false),
                      _tableCell(stats['avg']!.toStringAsFixed(precision), color, false),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, Color color, bool isBold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _timeOfDayCard(AppPalette palette) {
    // Group readings by hour of day (0-23)
    final hourlyAqi = <int, List<double>>{};
    for (var reading in _readings) {
      final ts = DateTime.tryParse(reading['timestamp'].toString())?.toLocal();
      if (ts != null) {
        final hour = ts.hour;
        final aqi = _quickAqi(reading).toDouble();
        hourlyAqi.putIfAbsent(hour, () => []).add(aqi);
      }
    }

    // Calculate average AQI per hour
    final hourlyAvg = <int, double>{};
    for (var entry in hourlyAqi.entries) {
      hourlyAvg[entry.key] = _avg(entry.value);
    }

    // Find best and worst hours
    final sortedHours = hourlyAvg.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bestHours = sortedHours.take(3).map((e) => e.key).toList();
    final worstHours = sortedHours.reversed.take(3).map((e) => e.key).toList();

    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best hours
          _hourlyRecommendation(palette, l10n.reportBestHours, bestHours, AppColors.good),
          const SizedBox(height: 12),
          // Worst hours
          _hourlyRecommendation(palette, l10n.reportWorstHours, worstHours, AppColors.unhealthy),
        ],
      ),
    );
  }

  Widget _hourlyRecommendation(AppPalette palette, String title, List<int> hours, Color color) {
    final hourStr = hours.map((h) => '${h.toString().padLeft(2, '0')}:00').join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hourStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceComparisonCard(AppPalette palette) {
    if (_isLoadingComparison) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.good),
        ),
      );
    }

    if (_deviceReadings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.devices_rounded, color: palette.textMuted, size: 32),
            const SizedBox(height: 12),
            Text(
              'No device data available',
              style: TextStyle(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate average AQI for each device
    final deviceStats = <String, Map<String, dynamic>>{};
    for (final entry in _deviceReadings.entries) {
      final device = entry.key;
      final readings = entry.value;
      if (readings.isNotEmpty) {
        final aqis = readings.map(_quickAqi).toList();
        final avgAqi = _avg(aqis).round();
        final maxAqi = aqis.reduce((a, b) => a > b ? a : b);
        final level = getAqiLevel(avgAqi);
        deviceStats[device] = {
          'avgAqi': avgAqi,
          'maxAqi': maxAqi,
          'level': level,
          'count': readings.length,
        };
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...deviceStats.entries.map((entry) {
            final stats = entry.value;
            final level = stats['level'] as AqiLevel;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.cardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: level.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats['count']} readings',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${stats['avgAqi']}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: level.color,
                          ),
                        ),
                        Text(
                          level.shortName,
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
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

  Widget _errorView(AppPalette palette, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: palette.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.reportLoadError,
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
                child: Text(l10n.reportRetry),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView(AppPalette palette, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: palette.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.reportNoData,
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      );
}
