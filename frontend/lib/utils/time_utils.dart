import 'package:intl/intl.dart';

/// Parse API/Influx timestamps (UTC with or without Z suffix).
DateTime parseApiTimestamp(dynamic value) {
  if (value == null) return DateTime.now();
  final raw = value.toString().trim();
  if (raw.isEmpty) return DateTime.now();

  final parsed = DateTime.parse(raw);
  if (parsed.isUtc || raw.endsWith('Z') || raw.contains('+')) {
    return parsed.toLocal();
  }
  // Naive server timestamps are UTC.
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).toLocal();
}

String formatTimeAgo(DateTime dt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(dt);
  if (diff.isNegative || diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 48) return '${diff.inHours}h ago';
  return DateFormat('MMM d, HH:mm').format(dt);
}
