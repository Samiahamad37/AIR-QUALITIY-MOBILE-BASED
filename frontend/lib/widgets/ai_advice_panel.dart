import 'package:flutter/material.dart';
import '/screens/app_theme.dart';
import '/utils/advice_formatter.dart';

class AiAdvicePanel extends StatefulWidget {
  final String advice;
  final Color accentColor;
  final String? category;

  const AiAdvicePanel({
    super.key,
    required this.advice,
    required this.accentColor,
    this.category,
  });

  @override
  State<AiAdvicePanel> createState() => _AiAdvicePanelState();
}

class _AiAdvicePanelState extends State<AiAdvicePanel> {
  bool _expanded = false;

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('health effect')) return Icons.monitor_heart_outlined;
    if (lower.contains('at risk') || lower.contains('who is')) {
      return Icons.groups_outlined;
    }
    if (lower.contains('protective') || lower.contains('action')) {
      return Icons.shield_outlined;
    }
    if (lower.contains('avoid')) return Icons.block_outlined;
    if (lower.contains('forecast') || lower.contains('hour')) {
      return Icons.timeline_outlined;
    }
    return Icons.tips_and_updates_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sections = parseAdviceSections(widget.advice);
    if (sections.isEmpty) return const SizedBox.shrink();

    final visible = _expanded ? sections : sections.take(2).toList();
    final hiddenCount = sections.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.psychology_alt_rounded,
                color: widget.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Health Insight',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Personalized guidance from live sensor data',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.category != null && widget.category!.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  widget.category!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...visible.asMap().entries.map(
              (entry) => _AdviceSectionTile(
                section: entry.value,
                icon: _iconForTitle(entry.value.title),
                accentColor: widget.accentColor,
                isLast: entry.key == visible.length - 1 && hiddenCount == 0,
              ),
            ),
        if (hiddenCount > 0 || _expanded)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _expanded
                    ? 'Show less'
                    : 'Show $hiddenCount more section${hiddenCount == 1 ? '' : 's'}',
              ),
            ),
          ),
      ],
    );
  }
}

class _AdviceSectionTile extends StatelessWidget {
  final AdviceSection section;
  final IconData icon;
  final Color accentColor;
  final bool isLast;

  const _AdviceSectionTile({
    required this.section,
    required this.icon,
    required this.accentColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: palette.cardLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border.withOpacity(0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
