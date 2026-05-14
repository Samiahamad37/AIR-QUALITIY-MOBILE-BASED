import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'air_quality_data.dart';
import 'api_service.dart';
import 'app_theme.dart';
import 'common_widget.dart';

// ─── Group Model ──────────────────────────────────────────────────────────────

class _Group {
  final String id;
  final String label;
  final IconData icon;

  const _Group({required this.id, required this.label, required this.icon});
}

const List<_Group> _kGroups = [
  _Group(id: 'general',         label: 'General',        icon: Icons.groups_rounded),
  _Group(id: 'children',        label: 'Children',       icon: Icons.child_care_rounded),
  _Group(id: 'elderly',         label: 'Elderly',        icon: Icons.elderly_rounded),
  _Group(id: 'pregnant',        label: 'Pregnant',       icon: Icons.pregnant_woman_rounded),
  _Group(id: 'asthma',          label: 'Asthma',         icon: Icons.air_rounded),
  _Group(id: 'outdoor_workers', label: 'Outdoor Work',   icon: Icons.construction_rounded),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int _aqi = 0;
  AqiLevel? _level;
  Map<String, List<String>> _recs = {};
  bool _loading = true;
  String? _error;
  final Set<String> _activeGroups = {'general'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Get current AQI first
      final current = await api.fetchCurrentAqi();
      _aqi = current['aqi'] as int;
      _level = getAqiLevel(_aqi);
      await _fetchRecs();
      setState(() => _loading = false);
    } on ApiException catch (e) {
      setState(() { _error = 'Server error ${e.statusCode}: ${e.message}'; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Cannot reach server.\n$e'; _loading = false; });
    }
  }

  Future<void> _fetchRecs() async {
    final data = await api.fetchRecommendations(
      aqi: _aqi,
      groups: _activeGroups.toList(),
    );
    final raw = data['recommendations'] as Map<String, dynamic>;
    setState(() {
      _recs = raw.map((k, v) => MapEntry(k, List<String>.from(v as List)));
    });
  }

  void _toggleGroup(String id) async {
    setState(() {
      if (_activeGroups.contains(id)) {
        if (_activeGroups.length > 1) _activeGroups.remove(id);
      } else {
        _activeGroups.add(id);
      }
    });
    if (!_loading) await _fetchRecs();
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.good, foregroundColor: Colors.black)),
      ]),
    )),
  );

  Widget _buildContent() {
    final level = _level!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: CustomScrollView(slivers: [

          // ── Hero header ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(level)),

          // ── Alert banner (shows when AQI > 100) ───────────────────────────
          if (_aqi > 100)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _AlertBanner(aqi: _aqi, level: level),
            )),

          // ── Group selector ─────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SectionHeader(title: 'Select Group')),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, runSpacing: 8,
              children: _kGroups.map((g) => _GroupChip(
                group: g,
                isActive: _activeGroups.contains(g.id),
                level: level,
                onTap: () => _toggleGroup(g.id),
              )).toList(),
            ),
          )),

          // ── Recommendation cards ───────────────────────────────────────────
          const SliverToBoxAdapter(child: SectionHeader(title: 'Health Guidance')),
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) {
              final groupId = _activeGroups.elementAt(i);
              final group   = _kGroups.firstWhere((g) => g.id == groupId);
              final recs    = _recs[groupId] ?? [];
              return Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16,
                    i == _activeGroups.length - 1 ? 0 : 12),
                child: _RecCard(
                  group: group, level: level,
                  aqi: _aqi, recommendations: recs, index: i,
                ),
              );
            },
            childCount: _activeGroups.length,
          )),

          // ── Tips footer ────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: SectionHeader(title: 'General Tips')),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: _TipsGrid(level: level),
          )),
        ]),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(AqiLevel level) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Health Guidance',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
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

          const SizedBox(height: 20),

          // AQI + level row
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Current AQI',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$_aqi',
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w800,
                        color: level.color, height: 1)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 6),
                  child: Text('AQI', style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: level.color.withOpacity(0.3)),
                ),
                child: Text(level.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: level.color)),
              ),
            ]),

            const Spacer(),

            // Circular progress
            SizedBox(
              width: 110, height: 110,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 110, height: 110,
                  child: CircularProgressIndicator(
                    value: (_aqi / 500).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: AppColors.bgCardLight,
                    valueColor: AlwaysStoppedAnimation(level.color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${((_aqi / 500) * 100).round()}%',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: level.color)),
                  const Text('of max', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ]),
              ]),
            ),
          ]),

          const SizedBox(height: 14),

          // Advice text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: level.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: level.color.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: level.textColor),
              const SizedBox(width: 8),
              Expanded(child: Text(level.advice,
                  style: TextStyle(fontSize: 12, color: level.textColor, height: 1.4))),
            ]),
          ),
        ]),
      )),
    );
  }
}

// ─── Alert Banner ─────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final int aqi;
  final AqiLevel level;

  const _AlertBanner({required this.aqi, required this.level});

  String get _message {
    if (aqi > 300) return 'HAZARDOUS — health emergency. Stay indoors immediately.';
    if (aqi > 200) return 'Very unhealthy — avoid all outdoor exposure. Use air purifiers.';
    if (aqi > 150) return 'Unhealthy air — everyone should reduce outdoor activity now.';
    return 'Sensitive groups should take extra precautions outdoors.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: level.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.color.withOpacity(0.5)),
      ),
      child: Row(children: [
        Icon(Icons.warning_rounded, color: level.textColor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(_message,
            style: TextStyle(fontSize: 13, color: level.textColor,
                fontWeight: FontWeight.w500, height: 1.4))),
      ]),
    );
  }
}

// ─── Group Chip ───────────────────────────────────────────────────────────────

class _GroupChip extends StatelessWidget {
  final _Group group;
  final bool isActive;
  final AqiLevel level;
  final VoidCallback onTap;

  const _GroupChip({
    required this.group, required this.isActive,
    required this.level, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1D4ED8).withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive ? const Color(0xFF3B82F6) : AppColors.border.withOpacity(0.5),
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(group.icon, size: 15,
              color: isActive ? const Color(0xFF60A5FA) : AppColors.textMuted),
          const SizedBox(width: 6),
          Text(group.label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF60A5FA) : AppColors.textSecondary,
              )),
        ]),
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecCard extends StatefulWidget {
  final _Group group;
  final AqiLevel level;
  final int aqi;
  final List<String> recommendations;
  final int index;

  const _RecCard({
    required this.group, required this.level, required this.aqi,
    required this.recommendations, required this.index,
  });

  @override
  State<_RecCard> createState() => _RecCardState();
}

class _RecCardState extends State<_RecCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Card header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: widget.level.bgColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: widget.level.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.group.icon, color: widget.level.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.group.label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: widget.level.textColor)),
                  const SizedBox(height: 1),
                  Text('AQI ${widget.aqi} · ${widget.level.shortName}',
                      style: TextStyle(fontSize: 11,
                          color: widget.level.textColor.withOpacity(0.7))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.level.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${widget.recommendations.length} tips',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: widget.level.textColor)),
                ),
              ]),
            ),

            // Recommendations list
            if (widget.recommendations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No guidance available for this combination.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: widget.recommendations.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: widget.level.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${e.key + 1}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: widget.level.color))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.value,
                            style: const TextStyle(fontSize: 13,
                                color: AppColors.textSecondary, height: 1.5))),
                      ]),
                    );
                  }).toList(),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ─── Tips Grid ────────────────────────────────────────────────────────────────

class _TipsGrid extends StatelessWidget {
  final AqiLevel level;

  const _TipsGrid({required this.level});

  static const _tips = [
    (Icons.masks_rounded,         'Wear N95',        'Use N95/KN95 masks outdoors when AQI > 100'),
    (Icons.wind_power_rounded,    'Air Purifier',    'Run HEPA purifiers indoors on high settings'),
    (Icons.window_rounded,        'Close Windows',   'Keep windows sealed during peak pollution hours'),
    (Icons.local_drink_rounded,   'Stay Hydrated',   'Drink plenty of water to flush pollutants'),
    (Icons.directions_run_rounded,'Exercise Timing', 'Exercise early morning when AQI is lowest'),
    (Icons.monitor_heart_rounded, 'Monitor Health',  'Watch for breathing issues; see a doctor promptly'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: _tips.asMap().entries.map((e) {
        return _TipCard(icon: e.value.$1, title: e.value.$2,
            desc: e.value.$3, level: level, index: e.key);
      }).toList(),
    );
  }
}

class _TipCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final AqiLevel level;
  final int index;

  const _TipCard({required this.icon, required this.title,
    required this.desc, required this.level, required this.index});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: 200 + widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: widget.level.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(widget.icon, color: widget.level.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(widget.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 3),
          Text(widget.desc,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}