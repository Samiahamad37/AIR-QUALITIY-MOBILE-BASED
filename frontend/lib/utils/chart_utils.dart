import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Ignore sudden near-zero dropouts after a healthy reading (sensor offline).
bool isMeaningfulReadingChange(double? previous, double next) {
  if (next <= 0) return false;
  if (previous == null) return true;
  if (previous >= 20 && next < previous * 0.15) return false;
  if (previous >= 5 && next < 1) return false;
  return true;
}

/// Dropout samples that should not replace a prior good reading.
bool isValidPollutantSample(String pollutant, double value) {
  if (value <= 0) return false;
  switch (pollutant) {
    case 'co2':
      // Sensor sends 0–2 when offline; real indoor CO₂ is much higher.
      return value >= 10;
    default:
      return true;
  }
}

double? averagePositiveValues(Iterable<double> values) {
  final nums = values.where((v) => v > 0).toList();
  if (nums.isEmpty) return null;
  return nums.reduce((a, b) => a + b) / nums.length;
}

/// Most recent reading in a time bucket (matches live dashboard value).
double? latestReadingInBucket(
  List<({DateTime ts, double? value})> bucket,
) {
  final valid = bucket.where((p) => p.value != null).toList();
  if (valid.isEmpty) return null;
  valid.sort((a, b) => b.ts.compareTo(a.ts));
  return valid.first.value;
}

/// Split spots so the line does not connect across missing time buckets.
List<List<FlSpot>> segmentSpots(List<FlSpot> spots, {double maxGap = 1.5}) {
  if (spots.isEmpty) return const [];
  final sorted = [...spots]..sort((a, b) => a.x.compareTo(b.x));
  final segments = <List<FlSpot>>[];
  var current = <FlSpot>[sorted.first];

  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i].x - sorted[i - 1].x > maxGap) {
      segments.add(current);
      current = <FlSpot>[];
    }
    current.add(sorted[i]);
  }
  segments.add(current);
  return segments;
}

List<LineChartBarData> segmentedLineBars(
  List<FlSpot> spots, {
  required Color color,
  double barWidth = 2.5,
  bool showDots = true,
  Color Function(FlSpot spot)? dotColor,
  bool showArea = false,
}) {
  if (spots.isEmpty) return const [];

  return segmentSpots(spots)
      .map(
        (seg) => LineChartBarData(
          spots: seg,
          isCurved: false,
          preventCurveOverShooting: true,
          color: color,
          barWidth: seg.length >= 2 ? barWidth : 0,
          dotData: FlDotData(
            show: showDots,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 4.5,
              color: dotColor?.call(spot) ?? color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: showArea && seg.length >= 2,
            color: color.withOpacity(0.08),
          ),
        ),
      )
      .toList();
}
