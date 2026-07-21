import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/Data/air_quality_data.dart';
import '/services/api_service.dart';
import '/screens/app_theme.dart';
import '/services/notification_service.dart';
import '/widgets/common_widget.dart';
import '/L10n/app_localizations.dart';
import '/services/shared_data_service.dart';

// Group Model

class _Group {
  final String id;
  final String label;
  final IconData icon;

  const _Group({required this.id, required this.label, required this.icon});
}

List<_Group> _kGroups(BuildContext context) => [
      _Group(
          id: 'general',
          label: AppLocalizations.of(context).groupGeneral,
          icon: Icons.groups_rounded),
      _Group(
          id: 'children',
          label: AppLocalizations.of(context).groupChildren,
          icon: Icons.child_care_rounded),
      _Group(
          id: 'elderly',
          label: AppLocalizations.of(context).groupElderly,
          icon: Icons.elderly_rounded),
      _Group(
          id: 'pregnant',
          label: AppLocalizations.of(context).groupPregnant,
          icon: Icons.pregnant_woman_rounded),
      _Group(
          id: 'asthma',
          label: AppLocalizations.of(context).groupAsthma,
          icon: Icons.air_rounded),
      _Group(
          id: 'outdoor_workers',
          label: AppLocalizations.of(context).groupOutdoor,
          icon: Icons.construction_rounded),
    ];

// Screen

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
  bool _isExpanded = false;
  String? _error;
  DateTime? _lastUpdated;
  final Set<String> _activeGroups = {'general'};
  String? _aiAdvice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Future<void> _load() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //   try {
  //     final recData = await api.fetchRecommendations();
  //     _aqi = (recData['aqi'] as num?)?.toInt() ?? 0;
  //     _level = getAqiLevel(_aqi);
  //     _aiAdvice = recData['advice'] as String?;
  //     _buildRecs();
  //     _lastUpdated = DateTime.now();
  //     setState(() => _loading = false);
  //     await notificationService.maybeNotifyAqiAlert(_aqi);
  //   } on ApiException catch (e) {
  //     setState(() {
  //       _error = 'Server error ${e.statusCode}: ${e.message}';
  //       _loading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _error = 'Cannot reach server.\n$e';
  //       _loading = false;
  //     });
  //   }
  // }
Future<void> _load() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    // ✅ Get AQI from SharedDataService
    final service = context.read<SharedDataService>();
    final currentAqi = service.currentData?.aqi;

    if (currentAqi == null) {
      throw Exception("AQI not available from SharedDataService");
    }

    // ✅ Fetch recommendations using AQI
    final recData = await api.fetchRecommendations(aqi: currentAqi);

    setState(() {
      _aqi = currentAqi;
      _level = getAqiLevel(_aqi);
      _aiAdvice = recData['advice'] as String?;
      _isExpanded = false;
      _buildRecs();
      _lastUpdated = DateTime.now();
      _loading = false;
    });

    await notificationService.evaluateAqi(
      currentAqi,
      location: service.currentData?.district,
    );

  } on ApiException catch (e) {
    setState(() {
      _error = 'Server error ${e.statusCode}: ${e.message}';
      _loading = false;
    });
  } catch (e) {
    setState(() {
      _error = 'Cannot reach server.\n$e';
      _loading = false;
    });
  }
}
 

  void _buildRecs() {
    final Map<String, List<String>> recs = {};
    for (final groupId in _activeGroups) {
      recs[groupId] = _getRecsForGroup(groupId, _aqi);
    }
    setState(() => _recs = recs);
  }

  List<String> _getRecsForGroup(String groupId, int aqi) {
    if (aqi <= 50) {
      return {
            'general': [
              'Air quality is satisfactory.',
              'Enjoy outdoor activities freely.',
              'Open windows for fresh air.'
            ],
            'children': ['Safe for outdoor play.', 'No restrictions needed.'],
            'elderly': [
              'Safe for outdoor walks.',
              'Normal activities recommended.'
            ],
            'pregnant': [
              'Safe for light outdoor activity.',
              'Fresh air is beneficial.'
            ],
            'asthma': [
              'Low risk today.',
              'Keep rescue inhaler handy as always.'
            ],
            'outdoor_workers': ['Safe working conditions.', 'Stay hydrated.'],
          }[groupId] ??
          ['No specific guidance needed.'];
    } else if (aqi <= 100) {
      return {
            'general': [
              'Air quality is acceptable.',
              'Unusually sensitive people should limit prolonged outdoor exertion.'
            ],
            'children': [
              'Outdoor play is generally safe.',
              'Watch for any unusual symptoms.'
            ],
            'elderly': [
              'Light outdoor activity is fine.',
              'Avoid prolonged strenuous exercise.'
            ],
            'pregnant': [
              'Light walks are safe.',
              'Avoid heavy outdoor exertion.'
            ],
            'asthma': [
              'Monitor symptoms closely.',
              'Limit prolonged outdoor exertion.',
              'Keep inhaler accessible.'
            ],
            'outdoor_workers': [
              'Take regular breaks indoors.',
              'Stay hydrated throughout the day.'
            ],
          }[groupId] ??
          ['Limit prolonged outdoor activity.'];
    } else if (aqi <= 150) {
      return {
            'general': [
              'Sensitive groups should reduce outdoor activity.',
              'Others can continue normal activities.'
            ],
            'children': [
              'Reduce prolonged outdoor exertion.',
              'Avoid outdoor sports.',
              'Keep outdoor time short.'
            ],
            'elderly': [
              'Limit outdoor activity.',
              'Stay indoors during peak hours.',
              'Monitor for breathing difficulty.'
            ],
            'pregnant': [
              'Reduce outdoor activity.',
              'Avoid areas with heavy traffic.',
              'Consult doctor if concerned.'
            ],
            'asthma': [
              'Avoid outdoor exertion.',
              'Use air purifier indoors.',
              'Have rescue medication ready.',
              'Seek medical help if symptoms worsen.'
            ],
            'outdoor_workers': [
              'Wear N95 mask.',
              'Increase rest breaks.',
              'Move heavy tasks indoors if possible.'
            ],
          }[groupId] ??
          ['Sensitive groups should take precautions.'];
    } else if (aqi <= 200) {
      return {
            'general': [
              'Everyone should reduce prolonged outdoor exertion.',
              'Take more breaks during outdoor activities.',
              'Wear a mask outdoors.'
            ],
            'children': [
              'Avoid all outdoor exertion.',
              'Cancel outdoor sports.',
              'Keep windows closed.'
            ],
            'elderly': [
              'Stay indoors.',
              'Run air purifier.',
              'Avoid all strenuous activity.'
            ],
            'pregnant': [
              'Stay indoors as much as possible.',
              'Use air purifier.',
              'Contact doctor if experiencing symptoms.'
            ],
            'asthma': [
              'Stay indoors.',
              'Use air purifier on high.',
              'Avoid all outdoor activity.',
              'Have emergency contacts ready.'
            ],
            'outdoor_workers': [
              'Wear N95/KN95 mask at all times.',
              'Request to work indoors.',
              'Limit outdoor exposure to minimum.'
            ],
          }[groupId] ??
          ['Reduce outdoor activity significantly.'];
    } else {
      return {
            'general': [
              'Avoid all outdoor activity.',
              'Stay indoors with windows closed.',
              'Use air purifier if available.'
            ],
            'children': [
              'Do not go outside.',
              'Keep all windows and doors closed.',
              'Use HEPA air purifier.'
            ],
            'elderly': [
              'Emergency conditions.',
              'Stay indoors immediately.',
              'Seek medical help if experiencing symptoms.'
            ],
            'pregnant': [
              'Stay indoors immediately.',
              'Call doctor if experiencing any symptoms.',
              'Use air purifier.'
            ],
            'asthma': [
              'Do not go outside under any circumstances.',
              'Use air purifier on maximum.',
              'Have emergency medications ready.',
              'Call doctor proactively.'
            ],
            'outdoor_workers': [
              'Stop all outdoor work immediately.',
              'Evacuate to indoor shelter.',
              'Seek medical attention if symptomatic.'
            ],
          }[groupId] ??
          ['Emergency conditions. Stay indoors immediately.'];
    }
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_activeGroups.contains(id)) {
        if (_activeGroups.length > 1) _activeGroups.remove(id);
      } else {
        _activeGroups.add(id);
      }
    });
    _buildRecs();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading(context);
    if (_error != null) return _buildError(context);
    return _buildContent(context);
  }

  Widget _buildLoading(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.good)),
      );

  Widget _buildError(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: palette.textMuted),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary, height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.healthRetry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.good,
                  foregroundColor: Colors.black),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final palette = context.palette;
    final level = _level!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.appOverlayStyle,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, level)),

          // Alert banner (shows when AQI > 100)
          if (_aqi > 100)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _AlertBanner(aqi: _aqi, level: level),
              ),
            ),

          // AI Advice Section
if (_aiAdvice != null && _aiAdvice!.isNotEmpty)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    color: level.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Recommendation",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Personalized advice based on current AQI",
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                _aiAdvice!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: palette.textSecondary,
                ),
              ),
              secondChild: Text(
                _aiAdvice!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: palette.textSecondary,
                ),
              ),
            ),

            if (_aiAdvice!.length > 180)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _isExpanded ? "Read less" : "Read more",
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  ),


          // Group selector
          SliverToBoxAdapter(
              child: SectionHeader(
                  title: AppLocalizations.of(context).healthSelectGroup)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kGroups(context)
                    .map((g) => _GroupChip(
                          group: g,
                          isActive: _activeGroups.contains(g.id),
                          level: level,
                          onTap: () => _toggleGroup(g.id),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Recommendation cards
          SliverToBoxAdapter(
              child: SectionHeader(
                  title: AppLocalizations.of(context).healthGuidance)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final groupId = _activeGroups.elementAt(i);
                final group =
                    _kGroups(context).firstWhere((g) => g.id == groupId);
                final recs = _recs[groupId] ?? [];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, i == _activeGroups.length - 1 ? 0 : 12),
                  child: _RecCard(
                    group: group,
                    level: level,
                    aqi: _aqi,
                    recommendations: recs,
                    index: i,
                  ),
                );
              },
              childCount: _activeGroups.length,
            ),
          ),

          // Tips footer
          SliverToBoxAdapter(
              child: SectionHeader(
                  title: AppLocalizations.of(context).healthGeneralTips)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: _TipsGrid(level: level),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AqiLevel level) {
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).healthTitle,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Data: airquality-ai.tlms.live',
                      style: TextStyle(
                          fontSize: 11, color: palette.textSecondary)),
                  const SizedBox(width: 8),
                  if (_lastUpdated != null)
                    Text(
                        'Updated: ${_lastUpdated!.toLocal().toString().split(".").first}',
                        style: TextStyle(
                            fontSize: 11, color: palette.textSecondary)),
                ])
              ]),
              GestureDetector(
                onTap: _load,
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
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context).healthCurrentAqi,
                    style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$_aqi',
                      style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: level.color,
                          height: 1)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 6),
                    child: Text('AQI',
                        style: TextStyle(
                            fontSize: 14,
                            color: palette.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: level.color.withOpacity(0.3)),
                  ),
                  child: Text(level.name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: level.color)),
                ),
              ]),
              const Spacer(),
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: (_aqi / 500).clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: palette.cardLight,
                      valueColor: AlwaysStoppedAnimation(level.color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${((_aqi / 500) * 100).round()}%',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: level.color)),
                    Text(AppLocalizations.of(context).healthOfMax,
                        style:
                            TextStyle(fontSize: 9, color: palette.textMuted)),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: level.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: level.color.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: level.textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(level.advice,
                      style: TextStyle(
                          fontSize: 12, color: level.textColor, height: 1.4)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// Alert Banner

class _AlertBanner extends StatelessWidget {
  final int aqi;
  final AqiLevel level;

  const _AlertBanner({required this.aqi, required this.level});

  String _message(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (aqi > 300) return l10n.alertHazardous;
    if (aqi > 200) return l10n.alertVeryUnhealthy;
    if (aqi > 150) return l10n.alertUnhealthy;
    return l10n.alertSensitive;
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
        Expanded(
          child: Text(_message(context),
              style: TextStyle(
                  fontSize: 13,
                  color: level.textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.4)),
        ),
      ]),
    );
  }
}

//  Group Chip

class _GroupChip extends StatelessWidget {
  final _Group group;
  final bool isActive;
  final AqiLevel level;
  final VoidCallback onTap;

  const _GroupChip({
    required this.group,
    required this.isActive,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1D4ED8).withOpacity(0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive
                ? const Color(0xFF3B82F6)
                : AppColors.border.withOpacity(0.5),
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(group.icon,
              size: 15,
              color: isActive ? const Color(0xFF60A5FA) : AppColors.textMuted),
          const SizedBox(width: 6),
          Text(group.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF60A5FA)
                    : AppColors.textSecondary,
              )),
        ]),
      ),
    );
  }
}

//  Recommendation Card

class _RecCard extends StatefulWidget {
  final _Group group;
  final AqiLevel level;
  final int aqi;
  final List<String> recommendations;
  final int index;

  const _RecCard({
    required this.group,
    required this.level,
    required this.aqi,
    required this.recommendations,
    required this.index,
  });

  @override
  State<_RecCard> createState() => _RecCardState();
}

class _RecCardState extends State<_RecCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: widget.level.bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.level.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.group.icon,
                      color: widget.level.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.group.label,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.level.textColor)),
                        const SizedBox(height: 1),
                        Text('AQI ${widget.aqi} · ${widget.level.shortName}',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    widget.level.textColor.withOpacity(0.7))),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.level.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      '${widget.recommendations.length} ${AppLocalizations.of(context).healthTips}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.level.textColor)),
                ),
              ]),
            ),
            if (widget.recommendations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppLocalizations.of(context).healthNoGuidance,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: widget.recommendations.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: widget.level.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${e.key + 1}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: widget.level.color)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.5)),
                            ),
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

// Tips Grid

class _TipsGrid extends StatelessWidget {
  final AqiLevel level;
  const _TipsGrid({required this.level});

  List<(IconData, String, String)> _tips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      (Icons.masks_rounded, l10n.tipMaskTitle, l10n.tipMaskDesc),
      (Icons.wind_power_rounded, l10n.tipPurifierTitle, l10n.tipPurifierDesc),
      (Icons.window_rounded, l10n.tipWindowsTitle, l10n.tipWindowsDesc),
      (Icons.local_drink_rounded, l10n.tipHydrateTitle, l10n.tipHydrateDesc),
      (
        Icons.directions_run_rounded,
        l10n.tipExerciseTitle,
        l10n.tipExerciseDesc
      ),
      (Icons.monitor_heart_rounded, l10n.tipMonitorTitle, l10n.tipMonitorDesc),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: _tips(context).asMap().entries.map((e) {
        return _TipCard(
          icon: e.value.$1,
          title: e.value.$2,
          desc: e.value.$3,
          level: level,
          index: e.key,
        );
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

  const _TipCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.level,
    required this.index,
  });

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: 200 + widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.level.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(widget.icon, color: widget.level.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(widget.title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 3),
          Text(widget.desc,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
