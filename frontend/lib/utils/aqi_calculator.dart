import 'dart:math';

/// EPA-style AQI calculation — mirrors backend `AQICalculator`.
class AqiCalculator {
  static const _aqiRanges = [
    (0, 50),
    (51, 100),
    (101, 150),
    (151, 200),
    (201, 300),
    (301, 500),
  ];

  static const _pm25Conc = [
    (0.0, 12.0),
    (12.1, 35.4),
    (35.5, 55.4),
    (55.5, 150.4),
    (150.5, 250.4),
    (250.5, 500.0),
  ];

  static const _no2Conc = [
    (0.0, 53.0),
    (54.0, 100.0),
    (101.0, 360.0),
    (361.0, 649.0),
    (650.0, 1249.0),
    (1250.0, 2049.0),
  ];

  static double _interpolate(
    double aqiLo,
    double aqiHi,
    double concLo,
    double concHi,
    double concentration,
  ) {
    return ((aqiHi - aqiLo) / (concHi - concLo)) * (concentration - concLo) +
        aqiLo;
  }

  static int? _aqiFromBreakpoints(
    double concentration,
    List<(double, double)> concBreakpoints,
  ) {
    for (var i = 0; i < concBreakpoints.length; i++) {
      final (lo, hi) = concBreakpoints[i];
      if (concentration >= lo && concentration <= hi) {
        final (aqiLo, aqiHi) = _aqiRanges[i];
        return _interpolate(
          aqiLo.toDouble(),
          aqiHi.toDouble(),
          lo,
          hi,
          concentration,
        ).round();
      }
    }
    return concentration > concBreakpoints.last.$2 ? 500 : null;
  }

  static int? pm25Aqi(double? pm25) {
    if (pm25 == null || pm25 <= 0) return null;
    return _aqiFromBreakpoints(pm25, _pm25Conc);
  }

  /// Converts sensor NOx (often ppm) to NO₂ ppb for EPA breakpoints.
  static double? no2Ppb(double? nox) {
    if (nox == null || nox < 0) return null;
    return nox < 1 ? nox * 1000 : nox;
  }

  static int? no2Aqi(double? nox) {
    final ppb = no2Ppb(nox);
    if (ppb == null || ppb <= 0) return null;
    return _aqiFromBreakpoints(ppb, _no2Conc);
  }

  /// Overall AQI = max pollutant sub-index (same as backend `/device/aqi/`).
  static int? overallAqi({double? pm25, double? nox}) {
    final values = <int>[];
    final pm25Index = pm25Aqi(pm25);
    final no2Index = no2Aqi(nox);
    if (pm25Index != null) values.add(pm25Index);
    if (no2Index != null) values.add(no2Index);
    if (values.isEmpty) return null;
    return values.reduce(max);
  }

  static int? fromReading(Map<String, dynamic> reading) {
    return overallAqi(
      pm25: (reading['pm25'] as num?)?.toDouble(),
      nox: (reading['nox'] as num?)?.toDouble() ??
          (reading['no2'] as num?)?.toDouble(),
    );
  }

  static double? _avgField(List<Map<String, dynamic>> rows, String key) {
    final values = rows
        .map((r) => (r[key] as num?)?.toDouble())
        .whereType<double>()
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Mean AQI across readings in a bucket (each reading converted to AQI first).
  static int? averageAqiFromBucket(List<Map<String, dynamic>> bucket) {
    final aqis = <int>[];
    for (final row in bucket) {
      final aqi = fromReading(row);
      if (aqi != null && aqi > 0) aqis.add(aqi);
    }
    if (aqis.isEmpty) return null;
    return (aqis.reduce((a, b) => a + b) / aqis.length).round();
  }

  /// AQI from hourly bucket: average concentrations first, then convert.
  static int? fromReadingBucket(List<Map<String, dynamic>> bucket) {
    if (bucket.isEmpty) return null;
    return overallAqi(
      pm25: _avgField(bucket, 'pm25'),
      nox: _avgField(bucket, 'nox') ?? _avgField(bucket, 'no2'),
    );
  }
}
