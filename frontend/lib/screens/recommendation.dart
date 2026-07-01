import 'package:flutter/material.dart';


// ─── Data Models ────────────────────────────────────────────────────────────

class AqiLevel {
  final int max;
  final String name;
  final Color color;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const AqiLevel({
    required this.max,
    required this.name,
    required this.color,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });
}

class PopulationGroup {
  final String id;
  final String label;
  final IconData icon;

  const PopulationGroup({
    required this.id,
    required this.label,
    required this.icon,
  });
}

// ─── Constants ──────────────────────────────────────────────────────────────

const List<AqiLevel> kAqiLevels = [
  AqiLevel(
    max: 50,
    name: 'Good',
    color: Color(0xFF4ADE80),
    bgColor: Color(0xFFF0FDF4),
    textColor: Color(0xFF166534),
    icon: Icons.sentiment_very_satisfied_rounded,
  ),
  AqiLevel(
    max: 100,
    name: 'Moderate',
    color: Color(0xFFFACC15),
    bgColor: Color(0xFFFEFCE8),
    textColor: Color(0xFF854D0E),
    icon: Icons.sentiment_neutral_rounded,
  ),
  AqiLevel(
    max: 150,
    name: 'Unhealthy (Sensitive)',
    color: Color(0xFFFB923C),
    bgColor: Color(0xFFFFF7ED),
    textColor: Color(0xFF9A3412),
    icon: Icons.warning_amber_rounded,
  ),
  AqiLevel(
    max: 200,
    name: 'Unhealthy',
    color: Color(0xFFF87171),
    bgColor: Color(0xFFFEF2F2),
    textColor: Color(0xFF991B1B),
    icon: Icons.sentiment_very_dissatisfied_rounded,
  ),
  AqiLevel(
    max: 300,
    name: 'Very Unhealthy',
    color: Color(0xFFC084FC),
    bgColor: Color(0xFFFAF5FF),
    textColor: Color(0xFF6B21A8),
    icon: Icons.dangerous_rounded,
  ),
  AqiLevel(
    max: 500,
    name: 'Hazardous',
    color: Color(0xFF9F1239),
    bgColor: Color(0xFFFFF1F2),
    textColor: Color(0xFF881337),
    icon: Icons.coronavirus_rounded,
  ),
];

const List<PopulationGroup> kGroups = [
  PopulationGroup(id: 'general',  label: 'General Public',       icon: Icons.groups_rounded),
  PopulationGroup(id: 'children', label: 'Children',             icon: Icons.child_care_rounded),
  PopulationGroup(id: 'elderly',  label: 'Elderly',              icon: Icons.elderly_rounded),
  PopulationGroup(id: 'pregnant', label: 'Pregnant',             icon: Icons.pregnant_woman_rounded),
  PopulationGroup(id: 'asthma',   label: 'Asthma / Respiratory', icon: Icons.air_rounded),
  PopulationGroup(id: 'outdoor',  label: 'Outdoor Workers',      icon: Icons.construction_rounded),
];

// rec key bands: 0=Good, 50=Moderate, 100=USG, 150=Unhealthy, 200=Very, 300=Hazardous
const Map<String, Map<int, List<String>>> kRecommendations = {
  'general': {
    0:   ['Enjoy outdoor activities freely.', 'Great time for exercise outdoors.', 'No restrictions needed.'],
    50:  ['Sensitive individuals should limit prolonged outdoor exertion.', 'Air quality is acceptable for most.', 'Monitor if you feel any irritation.'],
    100: ['Reduce prolonged outdoor activities.', 'Take breaks indoors if you feel discomfort.', 'Check local air quality updates.'],
    150: ['Avoid heavy outdoor exertion.', 'Wear a mask (N95/KN95) outdoors.', 'Keep windows closed during peak hours.'],
    200: ['Avoid all outdoor activities if possible.', 'Run air purifiers indoors.', 'Seal gaps around doors and windows.'],
    300: ['Stay indoors — all outdoor activities dangerous.', 'Use HEPA air purifiers on highest setting.', 'Seek medical advice if symptoms appear.'],
  },
  'children': {
    0:   ['Safe for outdoor play and sports.', 'Encourage outdoor activities.', 'Normal school outdoor activities allowed.'],
    50:  ['Generally safe; watch for any coughing.', 'Limit outdoor play if child has allergies.', 'Keep recess durations moderate.'],
    100: ['Shorten outdoor play sessions.', 'Move strenuous activities indoors.', 'Watch for coughing or breathing difficulty.'],
    150: ['Cancel outdoor sports and activities.', 'Keep children indoors during peak hours.', 'Use N95 masks if going outside is unavoidable.'],
    200: ['Children must stay indoors.', 'No outdoor recess or activities.', 'Consult pediatrician if child has breathing issues.'],
    300: ['Keep children strictly indoors.', 'Schools should suspend all outdoor activity.', 'Seek emergency care if breathing worsens.'],
  },
  'elderly': {
    0:   ['Safe to enjoy outdoor leisure activities.', 'Gentle walks and outdoor recreation are fine.', 'No special precautions needed.'],
    50:  ['Monitor how you feel during outdoor activity.', 'Limit strenuous outdoor exertion.', 'Stay hydrated and take breaks.'],
    100: ['Reduce outdoor time — especially midday.', 'Keep medications (e.g., inhalers) accessible.', 'Choose indoor exercise alternatives.'],
    150: ['Avoid all non-essential outdoor trips.', 'Wear N95 mask if you must go out.', 'Keep indoor air quality high with purifiers.'],
    200: ['Stay indoors completely.', 'Avoid any physical exertion, even indoors.', 'Call your doctor if you notice symptoms.'],
    300: ['Hazardous — do not go outside.', 'Monitor blood pressure and breathing frequently.', 'Have emergency contacts ready.'],
  },
  'pregnant': {
    0:   ['Safe for gentle outdoor walks.', 'Normal activities allowed.', 'Stay hydrated and rest as needed.'],
    50:  ['Limit vigorous outdoor activity.', 'Take shade during peak heat + pollution hours.', 'Stay well hydrated.'],
    100: ['Reduce outdoor time significantly.', 'Avoid busy roads and traffic areas.', 'Consult your OB if you notice any discomfort.'],
    150: ['Avoid outdoor exposure entirely.', 'Use HEPA purifiers indoors.', 'Wear N95 mask if going outside is necessary.'],
    200: ['Stay home — air quality poses serious risks.', 'Avoid any outdoor activity.', 'Contact healthcare provider immediately if unwell.'],
    300: ['Do not leave indoors under any circumstances.', 'Seek immediate medical attention if breathing is affected.', 'Follow emergency health authority guidance.'],
  },
  'asthma': {
    0:   ['Safe to exercise outdoors.', 'Keep rescue inhaler accessible as routine.', 'Monitor for any unusual symptoms.'],
    50:  ['Keep inhaler accessible at all times.', 'Avoid outdoor exercise during pollen peaks.', 'Reduce exposure to dust and allergens.'],
    100: ['Use preventive inhaler before going out.', 'Avoid outdoor exercise.', 'Stay indoors during high-traffic hours.'],
    150: ['Do not go outdoors without N95 mask.', 'Use nebulizer or inhaler before any exposure.', 'Have emergency medication ready.'],
    200: ['Stay completely indoors.', 'Use air purifiers with HEPA filter.', 'Call doctor if breathing symptoms worsen.'],
    300: ['Hazardous — risk of severe asthma attack.', 'Do not go outside under any circumstances.', 'Seek emergency care immediately if symptoms appear.'],
  },
  'outdoor': {
    0:   ['Normal work activities with no restrictions.', 'Stay hydrated during physical work.', 'No protective equipment needed for air.'],
    50:  ['Take regular shade breaks.', 'Stay hydrated — drink water every 30 min.', 'Monitor for any signs of discomfort.'],
    100: ['Wear a mask (at minimum surgical, N95 preferred).', 'Reduce pace of strenuous tasks.', 'Take breaks indoors every hour.'],
    150: ['Mandatory N95/P100 respirator.', 'Limit outdoor work hours.', 'Report breathing discomfort to supervisor immediately.'],
    200: ['Reschedule non-urgent outdoor work.', 'Only essential work outdoors with full PPE.', 'Rotate workers to minimize total exposure.'],
    300: ['Suspend all outdoor work.', 'Emergency tasks only — full respirator required.', 'Workers have right to refuse unsafe conditions.'],
  },
};

// ─── Helpers ────────────────────────────────────────────────────────────────

AqiLevel getAqiLevel(int aqi) {
  for (final level in kAqiLevels) {
    if (aqi <= level.max) return level;
  }
  return kAqiLevels.last;
}

int getRecKey(int aqi) {
  if (aqi <= 50) return 0;
  if (aqi <= 100) return 50;
  if (aqi <= 150) return 100;
  if (aqi <= 200) return 150;
  if (aqi <= 300) return 200;
  return 300;
}

// ─── Main Page ───────────────────────────────────────────────────────────────

class Recommendation extends StatefulWidget {
  /// Pass a real AQI value from your data source; defaults to 85 for demo.
  final int initialAqi;

  const Recommendation({super.key, this.initialAqi = 85});

  @override
  State<Recommendation> createState() => _RecommendationState();
}

class _RecommendationState extends State<Recommendation> {
  late int _aqi;
  final Set<String> _activeGroups = {'general'};
  late final TextEditingController _aqiController;

  @override
  void initState() {
    super.initState();
    _aqi = widget.initialAqi.clamp(0, 500);
    _aqiController = TextEditingController(text: _aqi.toString());
  }

  @override
  void dispose() {
    _aqiController.dispose();
    super.dispose();
  }

  void _onAqiChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      setState(() => _aqi = parsed.clamp(0, 500));
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
  }

  @override
  Widget build(BuildContext context) {
    final level = getAqiLevel(_aqi);
    final recKey = getRecKey(_aqi);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Health Recommendations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AqiInputCard(
            aqi: _aqi,
            level: level,
            controller: _aqiController,
            onChanged: _onAqiChanged,
          ),
          const SizedBox(height: 12),
          _AqiSpectrumBar(aqi: _aqi),
          const SizedBox(height: 12),
          if (_aqi > 100) ...[
            _AlertBanner(aqi: _aqi, level: level),
            const SizedBox(height: 12),
          ],
          _GroupSelector(
            groups: kGroups,
            activeGroups: _activeGroups,
            onToggle: _toggleGroup,
          ),
          const SizedBox(height: 16),
          ..._activeGroups.map((gid) {
            final group = kGroups.firstWhere((g) => g.id == gid);
            final recs = kRecommendations[gid]?[recKey] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendationCard(
                group: group,
                level: level,
                aqi: _aqi,
                recommendations: recs,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── AQI Input Card ──────────────────────────────────────────────────────────

class _AqiInputCard extends StatelessWidget {
  final int aqi;
  final AqiLevel level;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AqiInputCard({
    required this.aqi,
    required this.level,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT AQI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: level.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: level.color.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Icon(level.icon, color: level.textColor, size: 22),
                const SizedBox(height: 4),
                Text(
                  level.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: level.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spectrum Bar ────────────────────────────────────────────────────────────

class _AqiSpectrumBar extends StatelessWidget {
  final int aqi;

  const _AqiSpectrumBar({required this.aqi});

  @override
  Widget build(BuildContext context) {
    final colors = kAqiLevels.map((l) => l.color).toList();
    final pct = (aqi.clamp(0, 500) / 500).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: colors
                    .map((c) => Expanded(child: Container(color: c)))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (ctx, constraints) {
            final needleX = constraints.maxWidth * pct;
            return Stack(
              children: [
                const SizedBox(height: 16, width: double.infinity),
                Positioned(
                  left: (needleX - 1).clamp(0, constraints.maxWidth - 2),
                  child: Container(
                    width: 2,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0', '50', '100', '150', '200', '300', '500']
                .map((l) => Text(l,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF))))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Banner ────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final int aqi;
  final AqiLevel level;

  const _AlertBanner({required this.aqi, required this.level});

  String get _message {
    if (aqi > 300) return 'HAZARDOUS — health emergency level. Stay indoors immediately.';
    if (aqi > 200) return 'Very unhealthy — avoid outdoor exposure. Use air purifiers.';
    if (aqi > 150) return 'Unhealthy air — all groups should reduce outdoor activity.';
    return 'Sensitive groups should take precautions at this AQI level.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: level.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: level.color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: level.textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message,
              style: TextStyle(
                fontSize: 13,
                color: level.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Group Selector ──────────────────────────────────────────────────────────

class _GroupSelector extends StatelessWidget {
  final List<PopulationGroup> groups;
  final Set<String> activeGroups;
  final ValueChanged<String> onToggle;

  const _GroupSelector({
    required this.groups,
    required this.activeGroups,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WHO NEEDS GUIDANCE?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.map((g) {
            final isActive = activeGroups.contains(g.id);
            return GestureDetector(
              onTap: () => onToggle(g.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFEFF6FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      g.icon,
                      size: 15,
                      color: isActive
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      g.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Recommendation Card ─────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final PopulationGroup group;
  final AqiLevel level;
  final int aqi;
  final List<String> recommendations;

  const _RecommendationCard({
    required this.group,
    required this.level,
    required this.aqi,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: level.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(group.icon, color: level.textColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AQI $aqi — ${level.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: level.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          // Recommendations list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: recommendations.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: level.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.check, size: 11, color: level.textColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Demo Entry Point ─────────────────────────────────────────────────────────

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Recommendation(initialAqi: 85),
  ));
}