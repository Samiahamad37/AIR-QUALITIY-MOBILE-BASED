import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'dart:async';
import 'dart:convert';
import '/Data/air_quality_data.dart';
import '/services/api_service.dart';
import '/screens/app_theme.dart';
import '/widgets/common_widget.dart';
import '/services/auth_service.dart';
import '/services/shared_data_service.dart';
import '/L10n/app_localizations.dart';
import '/utils/device_labels.dart';
import '/utils/aqi_calculator.dart';
import '/utils/time_utils.dart';
import '/utils/report_exporter.dart';
import '/utils/aqi_localization.dart';



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
  String? _trackedDevice;
  String? _downloadSuccessFormat;
  Timer? _downloadSuccessTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  void _showDownloadSuccess(String format) {
    _downloadSuccessTimer?.cancel();
    setState(() => _downloadSuccessFormat = format);
    _downloadSuccessTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _downloadSuccessFormat = null);
    });
  }

  String _reportFilename(String extension) {
    final device = context.read<SharedDataService>().selectedDevice;
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'air_quality_${device}_$_period$stamp.$extension'
        .replaceAll(RegExp(r'[^\w.\-]+'), '_');
  }

  Future<List<int>> _buildPdfBytes() async {
    final device = context.read<SharedDataService>().selectedDevice;
    final deviceLabel = deviceDisplayName(device);
    final pdf = pw.Document();
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
              pw.Text('Device: $deviceLabel'),
              pw.Text('Period: $_period'),
              pw.Text(
                'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Summary Statistics',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Average AQI: $avgAqi (${level.name})'),
              pw.Text('Maximum AQI: $maxAqi'),
              pw.Text('Minimum AQI: $minAqi'),
              pw.Text('Total Readings: ${_readings.length}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'AQI Level: ${level.name}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Advice: ${level.advice}'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<List<int>> _buildCsvBytes() async {
    final device = context.read<SharedDataService>().selectedDevice;
    final deviceLabel = deviceDisplayName(device);
    final rows = <List<dynamic>>[
      ['Air Quality Report'],
      ['Device', deviceLabel],
      ['Period', _period],
      ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      [],
      ['Summary Statistics'],
      [
        'Average AQI',
        _readings.map(_quickAqi).isEmpty
            ? 0
            : _avg(_readings.map(_quickAqi)).round(),
      ],
      [
        'Maximum AQI',
        _readings.map(_quickAqi).isEmpty
            ? 0
            : _readings.map(_quickAqi).reduce((a, b) => a > b ? a : b),
      ],
      [
        'Minimum AQI',
        _readings.map(_quickAqi).isEmpty
            ? 0
            : _readings.map(_quickAqi).reduce((a, b) => a < b ? a : b),
      ],
      ['Total Readings', _readings.length],
      [],
      ['Timestamp', 'PM2.5', 'PM10', 'NOx', 'VOC', 'CO2', 'AQI'],
    ];

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

    return utf8.encode(const ListToCsvConverter().convert(rows));
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isExportingPdf = true;
      _downloadSuccessFormat = null;
    });

    try {
      final bytes = await _buildPdfBytes();
      final filename = _reportFilename('pdf');
      await saveReportFile(filename: filename, bytes: bytes);
      if (!mounted) return;
      _showDownloadSuccess('pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).reportExportError('$e'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExportingCsv = true;
      _downloadSuccessFormat = null;
    });

    try {
      final bytes = await _buildCsvBytes();
      final filename = _reportFilename('csv');
      await saveReportFile(filename: filename, bytes: bytes);
      if (!mounted) return;
      _showDownloadSuccess('csv');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).reportExportError('$e'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  bool get _isExporting => _isExportingPdf || _isExportingCsv;

  bool get _canDownload => !_isLoading && _readings.isNotEmpty && !_isExporting;

  @override
  void dispose() {
    _downloadSuccessTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final device = context.read<SharedDataService>().selectedDevice;
    _trackedDevice = device;
    await Future.wait([
      _load(device: device),
      _loadDeviceComparison(),
      context.read<SharedDataService>().loadData(background: true),
    ]);
  }

  Future<void> _load({String? device}) async {
    final selectedDevice =
        device ?? context.read<SharedDataService>().selectedDevice;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final readings = await api.fetchDeviceReadings(
        deviceId: selectedDevice,
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

  Future<void> _loadDeviceComparison() async {
    setState(() {
      _isLoadingComparison = true;
    });
    try {
      final devices = await api.fetchDevices();
      final hours = _periods[_period]!;
      final results = await Future.wait(
        devices.map((device) async {
          try {
            final readings = await api.fetchDeviceReadings(
              deviceId: device,
              hours: hours,
            );
            return MapEntry(device, readings);
          } catch (_) {
            return MapEntry(device, <Map<String, dynamic>>[]);
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _deviceReadings = Map.fromEntries(results);
        _isLoadingComparison = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingComparison = false;
      });
    }
  }

  // ── AQI helpers (consistent with SharedDataService) ──────────────────────────

  int _quickAqi(Map<String, dynamic> r) {
    return AqiCalculator.fromReading(r) ?? 0;
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
    final shared = context.watch<SharedDataService>();
    final l10n = AppLocalizations.of(context);

    if (_trackedDevice != shared.selectedDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.reportTitle),
        foregroundColor: palette.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading && _isLoadingComparison ? null : _loadAll,
            tooltip: l10n.errorRetry,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
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
                const SizedBox(height: 16),
                _downloadSection(palette, l10n),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
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
                const SizedBox(height: 24),
                _sectionTitle(palette, l10n.reportDeviceComparison),
                const SizedBox(height: 12),
                _deviceComparisonCard(palette, shared.selectedDevice),
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
          auth.username != null
              ? l10n.reportGreeting(auth.username!)
              : l10n.reportGreetingGuest,
          style: TextStyle(
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${l10n.reportTitle} — ${deviceDisplayName(device)}',
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

  Widget _downloadSection(AppPalette palette, AppLocalizations l10n) {
    final successLabel = _downloadSuccessFormat == 'pdf'
        ? l10n.reportDownloadPdfReady
        : _downloadSuccessFormat == 'csv'
            ? l10n.reportDownloadCsvReady
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: successLabel != null
              ? AppColors.good.withOpacity(0.5)
              : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download_rounded, color: palette.textPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reportExport,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (successLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.good.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.good.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.good, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        successLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.good,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isExporting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.good,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.reportExporting,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canDownload && !_isExportingCsv ? _exportPdf : null,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(l10n.reportExportPdf),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.good,
                    side: BorderSide(
                      color: _canDownload
                          ? AppColors.good.withOpacity(0.5)
                          : palette.border,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canDownload && !_isExportingPdf ? _exportCsv : null,
                  icon: const Icon(Icons.table_view_rounded, size: 18),
                  label: Text(l10n.reportExportCsv),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.good,
                    side: BorderSide(
                      color: _canDownload
                          ? AppColors.good.withOpacity(0.5)
                          : palette.border,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                _loadAll();
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
                  localizedAqiName(l10n, avg), level.color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(palette, l10n.reportBestDay, '$min',
                  localizedAqiName(l10n, min), getAqiLevel(min).color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(palette, l10n.reportWorstDay, '$max',
                  localizedAqiName(l10n, max), getAqiLevel(max).color),
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
    return AqiTrendChart(
      readings: _readings,
      timeFormat: _period == '24H' ? 'ha' : 'd/M',
    );
  }

  double get avgAqi {
    if (_readings.isEmpty) return 0;
    return _avg(_readings.map(_quickAqi));
  }

  Widget _pollutantCard(AppPalette palette, Map<String, double> averages) {
    final l10n = AppLocalizations.of(context);
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
    const apiKeys = {
      'PM2.5': 'pm25',
      'PM10': 'pm10',
      'CO2': 'co2',
      'NOx': 'nox',
      'VOC': 'voc',
    };
    final pollutantStats = <String, Map<String, double>>{};
    for (final entry in apiKeys.entries) {
      final values = _readings
          .map((r) => (r[entry.value] as num?)?.toDouble() ?? 0)
          .toList();
      if (values.isNotEmpty) {
        pollutantStats[entry.key] = {
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
          'avg': averages[entry.key] ?? 0,
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
                    _tableCell(l10n.reportPollutant, palette.textPrimary, true),
                    _tableCell(l10n.reportMin, palette.textSecondary, true),
                    _tableCell(l10n.reportMax, palette.textSecondary, true),
                    _tableCell(l10n.reportAvg, palette.textSecondary, true),
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
      final ts = parseApiTimestamp(reading['timestamp']);
      final hour = ts.hour;
      final aqi = _quickAqi(reading).toDouble();
      hourlyAqi.putIfAbsent(hour, () => []).add(aqi);
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

  Widget _deviceComparisonCard(AppPalette palette, String selectedDevice) {
    final shared = context.watch<SharedDataService>();
    final l10n = AppLocalizations.of(context);

    if (_isLoadingComparison && _deviceReadings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.good,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.reportLoadingComparison,
              style: TextStyle(fontSize: 13, color: palette.textSecondary),
            ),
          ],
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
              l10n.reportNoDeviceData,
              style: TextStyle(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final deviceStats = <String, Map<String, dynamic>>{};
    for (final entry in _deviceReadings.entries) {
      final device = entry.key;
      final readings = entry.value;
      if (readings.isEmpty) {
        deviceStats[device] = {'empty': true};
        continue;
      }
      final aqis = readings.map(_quickAqi).toList();
      final latestTs = parseApiTimestamp(readings.first['timestamp']);
      deviceStats[device] = {
        'avgAqi': _avg(aqis).round(),
        'maxAqi': aqis.reduce((a, b) => a > b ? a : b),
        'count': readings.length,
        'updated': formatTimeAgo(latestTs),
      };
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
          Text(
            l10n.reportLiveAqiHint(_period),
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reportTapStationReport,
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          ...deviceStats.entries.map((entry) {
            final deviceId = entry.key;
            final stats = entry.value;
            final isSelected = deviceId == selectedDevice;
            final liveAqi = shared.aqiForDevice(deviceId);
            final liveLevel = getAqiLevel(liveAqi);

            if (stats['empty'] == true) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.good : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 18, color: palette.textMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          deviceDisplayName(deviceId),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        l10n.reportNoDataShort,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final avgAqi = stats['avgAqi'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await context
                        .read<SharedDataService>()
                        .setSelectedDevice(deviceId);
                    if (!mounted) return;
                    await _loadAll();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.good.withOpacity(0.08)
                          : palette.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.good : palette.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: liveLevel.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    deviceDisplayName(deviceId),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.good.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.reportActive,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.good,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.reportLiveStats(
                                  stats['count'] as int,
                                  _period,
                                  avgAqi,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textSecondary,
                                ),
                              ),
                              if (stats['updated'] != null)
                                Text(
                                  l10n.reportLatestReading(
                                    stats['updated'] as String,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: palette.textMuted,
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
                              '$liveAqi',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: liveLevel.color,
                              ),
                            ),
                            Text(
                              localizedAqiName(l10n, liveAqi),
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
                ),
              ),
            );
          }),
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
    final l10n = AppLocalizations.of(context);
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

    final summary = l10n.reportSummary(
      avg,
      localizedAqiName(l10n, avg),
      max,
      dominant,
      localizedAqiAdvice(l10n, avg),
    );

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
                  localizedAqiName(l10n, avg),
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
                onPressed: _loadAll,
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
