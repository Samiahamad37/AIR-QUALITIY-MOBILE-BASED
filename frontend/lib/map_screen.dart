import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'air_quality_data.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'common_widget.dart';

// ─── Station Map Data ─────────────────────────────────────────────────────────

class StationMapData {
  final int id;
  final String name;
  final String district;
  final String city;
  final double latitude;
  final double longitude;
  final int aqi;
  final double pm25;
  final AqiLevel level;
  final DateTime updated;

  const StationMapData({
    required this.id, required this.name, required this.district,
    required this.city, required this.latitude, required this.longitude,
    required this.aqi, required this.pm25, required this.level,
    required this.updated,
  });

  factory StationMapData.fromApi(Map<String, dynamic> json) {
    final station = json['station'] as Map<String, dynamic>;
    final aqi     = json['aqi'] as int;
    return StationMapData(
      id:        station['id'] as int,
      name:      station['name'] as String,
      district:  station['district'] as String,
      city:      station['city'] as String,
      latitude:  (station['latitude'] as num).toDouble(),
      longitude: (station['longitude'] as num).toDouble(),
      aqi:       aqi,
      pm25:      (json['pm25'] as num).toDouble(),
      level:     getAqiLevel(aqi),
      updated:   DateTime.parse(json['updated'] as String),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<StationMapData> _stations = [];
  StationMapData? _selected;
  bool _loading = true;
  String? _error;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _load();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await api.fetchMapStations();
      setState(() {
        _stations = data.map((s) => StationMapData.fromApi(s)).toList();
        if (_stations.isNotEmpty) _selected = _stations.first;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = 'Server error ${e.statusCode}: ${e.message}'; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Cannot reach server.\n$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildContent();
  }

  Widget _buildLoading() => const Scaffold(
    backgroundColor: AppColors.bgDark,
    body: Center(child: CircularProgressIndicator(color: AppColors.good)),
  );

  Widget _buildError() => Scaffold(
    backgroundColor: AppColors.bgDark,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _load,
          icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.good, foregroundColor: Colors.black)),
      ]),
    )),
  );

  Widget _buildContent() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Column(children: [

          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(),

          Expanded(child: CustomScrollView(slivers: [

            // ── Simulated map ────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildMapView()),

            // ── Legend ───────────────────────────────────────────────────
            const SliverToBoxAdapter(child: SectionHeader(title: 'AQI Scale')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildLegend(),
            )),

            // ── Stations list ─────────────────────────────────────────────
            const SliverToBoxAdapter(child: SectionHeader(title: 'All Stations')),
            SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16,
                    i == _stations.length - 1 ? 0 : 10),
                child: _StationCard(
                  station: _stations[i],
                  isSelected: _selected?.id == _stations[i].id,
                  pulseAnim: _pulseAnim,
                  onTap: () => setState(() => _selected = _stations[i]),
                  index: i,
                ),
              ),
              childCount: _stations.length,
            )),

            // ── Selected station detail ────────────────────────────────────
            if (_selected != null) ...[
              const SliverToBoxAdapter(child: SectionHeader(title: 'Station Detail')),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _StationDetailCard(station: _selected!),
              )),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ])),
        ]),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final best = _stations.isEmpty ? null
        : _stations.reduce((a, b) => a.aqi < b.aqi ? a : b);
    final worst = _stations.isEmpty ? null
        : _stations.reduce((a, b) => a.aqi > b.aqi ? a : b);

    return Container(
      color: AppColors.bgCard,
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Air Quality Map',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            Row(children: [
              GestureDetector(
                onTap: _load,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.bgCardLight,
                      shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
            ]),
          ]),

          const SizedBox(height: 4),
          Text('${_stations.length} stations · Dar es Salaam',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),

          if (best != null && worst != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _headerStat(
                Icons.thumb_up_rounded, 'Cleanest Area',
                best.district, best.aqi, const Color(0xFF4ADE80))),
              const SizedBox(width: 10),
              Expanded(child: _headerStat(
                Icons.warning_rounded, 'Most Polluted',
                worst.district, worst.aqi, const Color(0xFFF87171))),
            ]),
          ],
        ]),
      )),
    );
  }

  Widget _headerStat(IconData icon, String label, String place, int aqi, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          Text(place, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ])),
        Text('$aqi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  // ─── Map View (visual representation) ────────────────────────────────────
  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(children: [
              // Map background grid
              CustomPaint(
                size: const Size(double.infinity, 220),
                painter: _MapGridPainter(),
              ),

              // Station dots plotted on the map
              ..._stations.map((s) => _MapStationDot(
                station: s,
                isSelected: _selected?.id == s.id,
                pulseAnim: _pulseAnim,
                onTap: () => setState(() => _selected = s),
                stations: _stations,
              )),

              // Map label
              Positioned(top: 10, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(children: [
                    Icon(Icons.map_rounded, size: 11, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Dar es Salaam Region',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                ),
              ),

              // Tap prompt
              if (_stations.isNotEmpty)
                Positioned(bottom: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Tap a station to select',
                        style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Legend ──────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    const levels = [
      ('Good', AppColors.good, '0-50'),
      ('Moderate', AppColors.moderate, '51-100'),
      ('Sensitive', AppColors.sensitiveGroups, '101-150'),
      ('Unhealthy', AppColors.unhealthy, '151-200'),
      ('Very', AppColors.veryUnhealthy, '201-300'),
      ('Hazardous', AppColors.hazardous, '300+'),
    ];

    return GlassCard(
      child: Row(
        children: levels.map((l) => Expanded(
          child: Column(children: [
            Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: l.$2, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 5),
            Text(l.$1, style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                textAlign: TextAlign.center),
            Text(l.$3, style: const TextStyle(fontSize: 7, color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ]),
        )).toList(),
      ),
    );
  }
}

// ─── Map Grid Painter ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0F1923));

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2D3D)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Simulated roads
    final roadPaint = Paint()
      ..color = const Color(0xFF1A2F42)
      ..strokeWidth = 2;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.65), roadPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.35, 0),
        Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.75, size.height), roadPaint);

    // Ocean hint (right side)
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.75, 0, size.width * 0.25, size.height),
      Paint()..color = const Color(0xFF0A1520),
    );

    // Water label
    const textStyle = TextStyle(color: Color(0xFF1E3A4A), fontSize: 11);
    final textSpan  = TextSpan(text: 'Indian Ocean', style: textStyle);
    final painter   = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, Offset(size.width * 0.77, size.height * 0.45));
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}

// ─── Map Station Dot ──────────────────────────────────────────────────────────

class _MapStationDot extends StatelessWidget {
  final StationMapData station;
  final bool isSelected;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  final List<StationMapData> stations;

  const _MapStationDot({
    required this.station, required this.isSelected, required this.pulseAnim,
    required this.onTap, required this.stations,
  });

  // Map lat/lng to pixel position within the map view
  Offset _toPixel(Size size) {
    if (stations.isEmpty) return Offset(size.width / 2, size.height / 2);

    final lats = stations.map((s) => s.latitude);
    final lngs = stations.map((s) => s.longitude);
    final minLat = lats.reduce((a, b) => a < b ? a : b) - 0.03;
    final maxLat = lats.reduce((a, b) => a > b ? a : b) + 0.03;
    final minLng = lngs.reduce((a, b) => a < b ? a : b) - 0.03;
    final maxLng = lngs.reduce((a, b) => a > b ? a : b) + 0.03;

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    final x = ((station.longitude - minLng) / lngRange) * (size.width * 0.72) + size.width * 0.04;
    final y = ((maxLat - station.latitude) / latRange) * (size.height * 0.8) + size.height * 0.1;

    return Offset(x.clamp(20, size.width - 20), y.clamp(20, size.height - 20));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final size   = Size(constraints.maxWidth, 220);
      final offset = _toPixel(size);

      return Positioned(
        left: offset.dx - 20,
        top:  offset.dy - 20,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(width: 40, height: 40,
            child: AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, child) {
                return Stack(alignment: Alignment.center, children: [
                  if (isSelected)
                    Container(
                      width: 36 + (pulseAnim.value * 8),
                      height: 36 + (pulseAnim.value * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: station.level.color.withOpacity(0.2 * (1 - pulseAnim.value)),
                      ),
                    ),
                  child!,
                ]);
              },
              child: Container(
                width: isSelected ? 36 : 28,
                height: isSelected ? 36 : 28,
                decoration: BoxDecoration(
                  color: station.level.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : station.level.color.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [BoxShadow(
                    color: station.level.color.withOpacity(0.5),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 2 : 0,
                  )],
                ),
                child: Center(child: Text('${station.aqi}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: Colors.white))),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Station Card ─────────────────────────────────────────────────────────────

class _StationCard extends StatefulWidget {
  final StationMapData station;
  final bool isSelected;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;
  final int index;

  const _StationCard({
    required this.station, required this.isSelected, required this.pulseAnim,
    required this.onTap, required this.index,
  });

  @override
  State<_StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<_StationCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _slide = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s     = widget.station;
    final level = s.level;

    return SlideTransition(
      position: _slide,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected ? level.bgColor : AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected ? level.color.withOpacity(0.5) : AppColors.border.withOpacity(0.4),
              width: widget.isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(children: [
            // Color dot with pulse
            AnimatedBuilder(
              animation: widget.pulseAnim,
              builder: (_, __) => Container(
                width: widget.isSelected ? 14 : 10,
                height: widget.isSelected ? 14 : 10,
                decoration: BoxDecoration(
                  color: level.color,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected ? [BoxShadow(
                    color: level.color.withOpacity(0.5 * widget.pulseAnim.value),
                    blurRadius: 8, spreadRadius: 2)] : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Station info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.district,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: widget.isSelected ? level.textColor : Colors.white)),
              Text(s.name,
                  style: TextStyle(fontSize: 11,
                      color: widget.isSelected ? level.textColor.withOpacity(0.7) : AppColors.textSecondary)),
            ])),

            // AQI badge
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${s.aqi}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: level.color)),
              Text(level.shortName,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ]),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18,
                color: widget.isSelected ? level.color : AppColors.textMuted),
          ]),
        ),
      ),
    );
  }
}

// ─── Station Detail Card ──────────────────────────────────────────────────────

class _StationDetailCard extends StatelessWidget {
  final StationMapData station;

  const _StationDetailCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final level = station.level;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: level.color.withOpacity(0.3)),
      ),
      child: Column(children: [

        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: level.bgColor,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sensors_rounded, color: level.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(station.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: level.textColor)),
              Text('${station.district} · ${station.city}',
                  style: TextStyle(fontSize: 11, color: level.textColor.withOpacity(0.7))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${station.aqi}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: level.color)),
              Text('AQI', style: TextStyle(fontSize: 11, color: level.textColor.withOpacity(0.7))),
            ]),
          ]),
        ),

        // Metrics grid
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              _detailMetric('PM2.5', '${station.pm25.round()} µg/m³', AppColors.pm25Color),
              const SizedBox(width: 10),
              _detailMetric('Status', level.shortName, level.color),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _detailMetric('Latitude',  '${station.latitude.toStringAsFixed(4)}°', AppColors.o3Color),
              const SizedBox(width: 10),
              _detailMetric('Longitude', '${station.longitude.toStringAsFixed(4)}°', AppColors.o3Color),
            ]),
            const SizedBox(height: 14),

            // Status bar
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Air Quality Index',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('${station.aqi}/500',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: level.color)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (station.aqi / 500).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.bgCardLight,
                valueColor: AlwaysStoppedAnimation(level.color),
              ),
            ),
            const SizedBox(height: 12),

            // Last updated
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.update_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Updated ${_timeAgo(station.updated)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _detailMetric(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}