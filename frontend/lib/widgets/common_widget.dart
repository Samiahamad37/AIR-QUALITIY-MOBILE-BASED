import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/screens/app_theme.dart';
import '/Data/air_quality_data.dart';
import 'package:air_quality_monitor/L10n/app_localizations.dart';
import '/utils/aqi_calculator.dart';
import '/utils/aqi_localization.dart';
import '/utils/time_utils.dart';

// ─── AQI Ring Widget ──────────────────────────────────────────────────────────

class AqiRing extends StatefulWidget {
  final int aqi;
  final double size;

  const AqiRing({super.key, required this.aqi, this.size = 180});

  @override
  State<AqiRing> createState() => _AqiRingState();
}

class _AqiRingState extends State<AqiRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final level = getAqiLevel(widget.aqi);
    final progress = (widget.aqi / 500).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress * _anim.value,
            color: level.color,
            bgColor: palette.cardLight,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(widget.aqi * _anim.value).round()}',
                  style: TextStyle(
                    fontSize: widget.size * 0.28,
                    fontWeight: FontWeight.w800,
                    color: level.color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AQI',
                  style: TextStyle(
                    fontSize: widget.size * 0.09,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - 12;
    const strokeW = 12.0;
    const startAngle = -3.14159 * 0.75;
    const sweepFull = 3.14159 * 1.5;

    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepFull,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepFull * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Pollutant Bar Row ────────────────────────────────────────────────────────

class PollutantBar extends StatefulWidget {
  final Pollutant pollutant;
  final int delayMs;

  const PollutantBar({super.key, required this.pollutant, this.delayMs = 0});

  @override
  State<PollutantBar> createState() => _PollutantBarState();
}

class _PollutantBarState extends State<PollutantBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
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
    final palette = context.palette;
    final p = widget.pollutant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              p.name,
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 6,
                color: palette.cardLight,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (p.ratio * _anim.value).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              '${p.value} ${p.unit}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: p.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AQI trend badge ───────────────────────────────────────────────────────────

class AqiTrendBadge extends StatelessWidget {
  final String? direction;

  const AqiTrendBadge({super.key, this.direction});

  @override
  Widget build(BuildContext context) {
    if (direction == null || direction!.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalized = direction!.toLowerCase();
    final isRising = normalized == 'rising';
    final isFalling = normalized == 'falling';

    final Color color;
    final IconData icon;
    final String label;

    if (isRising) {
      color = AppColors.unhealthy;
      icon = Icons.trending_up_rounded;
      label = 'AQI Rising';
    } else if (isFalling) {
      color = AppColors.good;
      icon = Icons.trending_down_rounded;
      label = 'AQI Falling';
    } else {
      color = AppColors.moderate;
      icon = Icons.trending_flat_rounded;
      label = 'AQI Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AQI Trend chart (shared by Home + Reports & Analysis) ───────────────────

class AqiTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  final String timeFormat;

  const AqiTrendChart({
    super.key,
    required this.readings,
    this.timeFormat = 'ha',
  });

  static Color _aqiColor(double aqi) {
    if (aqi <= 50) return AppColors.good;
    if (aqi <= 100) return AppColors.moderate;
    if (aqi <= 150) return AppColors.sensitiveGroups;
    if (aqi <= 200) return AppColors.unhealthy;
    if (aqi <= 300) return AppColors.veryUnhealthy;
    return AppColors.hazardous;
  }

  static int _readingAqi(Map<String, dynamic> reading) {
    return AqiCalculator.fromReading(reading) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context);
    if (readings.isEmpty) return const SizedBox.shrink();

    final ordered = readings.reversed.toList();
    final spots = ordered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _readingAqi(e.value).toDouble());
    }).toList();
    final maxY = spots.map((s) => s.y).reduce(max);
    final avgAqi = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
    final lineColor = _aqiColor(avgAqi);

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
                reservedSize: 22,
                interval: (ordered.length / 4).ceilToDouble().clamp(1, 9999),
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= ordered.length) {
                    return const SizedBox.shrink();
                  }
                  final ts = parseApiTimestamp(ordered[i]['timestamp']);
                  return Text(
                    DateFormat(timeFormat).format(ts).toLowerCase(),
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
              color: lineColor,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: (maxY * 1.2).clamp(50, double.infinity),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => palette.card,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final aqi = spot.y.toInt();
                  return LineTooltipItem(
                    l10n.reportAqiTooltip(aqi, localizedAqiName(l10n, aqi)),
                    TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: lineColor, strokeWidth: 2),
                  FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 6,
                      color: lineColor,
                      strokeWidth: 2,
                      strokeColor: palette.card,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ─── PM2.5 / PM10 dual-line forecast chart ───────────────────────────────────

class PmForecastDualChart extends StatefulWidget {
  final List<Map<String, dynamic>> forecast;

  const PmForecastDualChart({super.key, required this.forecast});

  @override
  State<PmForecastDualChart> createState() => _PmForecastDualChartState();
}

class _PmForecastDualChartState extends State<PmForecastDualChart> {
  static const _pm10Color = Color(0xFF2563EB);

  int? _touchedIndex;

  List<Map<String, dynamic>> get _points => widget.forecast
      .where((f) => f['pm25'] != null && f['pm10'] != null)
      .toList();

  @override
  void initState() {
    super.initState();
    if (_points.isNotEmpty) _touchedIndex = 0;
  }

  @override
  void didUpdateWidget(covariant PmForecastDualChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = _points.length;
    if (count == 0) {
      _touchedIndex = null;
    } else if (_touchedIndex == null || _touchedIndex! >= count) {
      _touchedIndex = 0;
    }
  }

  void _onTouchIndex(int? index) {
    if (index == null || index < 0 || index >= _points.length) return;
    if (_touchedIndex != index) {
      setState(() => _touchedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final points = _points;

    if (points.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'PM forecast unavailable',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final pm25Values =
        points.map((p) => (p['pm25'] as num).toDouble()).toList();
    final pm10Values =
        points.map((p) => (p['pm10'] as num).toDouble()).toList();

    final pm25Spots = pm25Values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final maxPm25 = pm25Values.reduce(max);
    final maxPm10 = pm10Values.reduce(max);
    final leftMax = max((maxPm25 * 1.25 / 5).ceil() * 5.0, 15.0);
    final rightMax = max((maxPm10 * 1.25 / 5).ceil() * 5.0, 20.0);
    final leftInterval = leftMax > 30 ? 10.0 : 5.0;

    final pm10Spots = pm10Values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value * leftMax / rightMax))
        .toList();

    String hourLabel(int i) {
      final ts =
          DateTime.parse(points[i]['timestamp'].toString()).toLocal();
      return DateFormat('ha').format(ts).toLowerCase();
    }

    final touched = _touchedIndex;
    final hasTouch = touched != null && touched >= 0 && touched < points.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PmChartLegend(color: AppColors.pm25Color, label: 'PM2.5'),
            const SizedBox(width: 28),
            _PmChartLegend(color: _pm10Color, label: 'PM10'),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasTouch
                ? palette.cardLight
                : palette.border.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasTouch ? palette.border : Colors.transparent,
            ),
          ),
          child: hasTouch
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      pm25Values[touched].toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pm25Color,
                      ),
                    ),
                    Text(
                      pm10Values[touched].toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _pm10Color,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Touch the line to see values',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: leftInterval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: palette.border.withOpacity(0.35),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'PM2.5 µg/m³',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pm25Color,
                    ),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: leftInterval,
                    getTitlesWidget: (val, _) => Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.pm25Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(
                  axisNameWidget: Text(
                    'PM10 µg/m³',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _pm10Color,
                    ),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: leftInterval,
                    getTitlesWidget: (val, _) {
                      final pm10Val = val * rightMax / leftMax;
                      return Text(
                        pm10Val.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 10,
                          color: _pm10Color,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (val, _) {
                      final i = val.round();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          hourLabel(i),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: palette.border.withOpacity(0.5)),
                  left: BorderSide(color: AppColors.pm25Color.withOpacity(0.5)),
                  right: BorderSide(color: _pm10Color.withOpacity(0.5)),
                ),
              ),
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: leftMax,
              lineBarsData: [
                LineChartBarData(
                  spots: pm25Spots,
                  isCurved: true,
                  color: AppColors.pm25Color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: hasTouch,
                    getDotPainter: (spot, _, __, ___) {
                      if (!hasTouch || spot.x.toInt() != touched) {
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 6,
                        color: AppColors.pm25Color,
                        strokeWidth: 2,
                        strokeColor: palette.card,
                      );
                    },
                  ),
                ),
                LineChartBarData(
                  spots: pm10Spots,
                  isCurved: true,
                  color: _pm10Color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: hasTouch,
                    getDotPainter: (spot, _, __, ___) {
                      if (!hasTouch || spot.x.toInt() != touched) {
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 6,
                        color: _pm10Color,
                        strokeWidth: 2,
                        strokeColor: palette.card,
                      );
                    },
                  ),
                ),
              ],
              extraLinesData: hasTouch
                  ? ExtraLinesData(
                      verticalLines: [
                        VerticalLine(
                          x: touched.toDouble(),
                          color: palette.textSecondary.withOpacity(0.45),
                          strokeWidth: 1.5,
                          dashArray: [5, 4],
                        ),
                      ],
                    )
                  : null,
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchSpotThreshold: 40,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (_) => [],
                ),
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final spots = response?.lineBarSpots;
                  if (spots != null && spots.isNotEmpty) {
                    _onTouchIndex(spots.first.spotIndex);
                  }
                },
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  final color = barData.color ?? AppColors.pm25Color;
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: palette.textSecondary.withOpacity(0.45),
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, i) =>
                            FlDotCirclePainter(
                          radius: 7,
                          color: color,
                          strokeWidth: 2.5,
                          strokeColor: palette.card,
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PmChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _PmChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 22, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Metric Chip (temp/humidity/wind) ────────────────────────────────────────

class MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const MetricChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary)),
            Text(label,
                style: TextStyle(fontSize: 9, color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const GlassCard({super.key, required this.child, this.padding, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: palette.border.withOpacity(0.5)),
      ),
      child: child,
    );
  }
}
