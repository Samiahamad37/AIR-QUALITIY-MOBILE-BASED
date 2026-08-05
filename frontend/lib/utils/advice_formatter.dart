class AdviceSection {
  final String title;
  final String body;

  const AdviceSection({required this.title, required this.body});
}

/// Parses AI advice like `**Section Title**\nBody text...` into clean sections.
List<AdviceSection> parseAdviceSections(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return [];

  final headerPattern = RegExp(r'\*\*(.+?)\*\*');
  final matches = headerPattern.allMatches(text).toList();

  if (matches.isEmpty) {
    return [
      AdviceSection(title: 'Summary', body: cleanAdviceMarkdown(text)),
    ];
  }

  final sections = <AdviceSection>[];
  for (var i = 0; i < matches.length; i++) {
    final title = cleanAdviceMarkdown(matches[i].group(1)!);
    final start = matches[i].end;
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final body = cleanAdviceMarkdown(text.substring(start, end));
    if (title.isNotEmpty && body.isNotEmpty) {
      sections.add(AdviceSection(title: title, body: body));
    }
  }

  return sections;
}

/// Removes markdown markers and normalizes whitespace.
String cleanAdviceMarkdown(String input) {
  return input
      .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
      .replaceAll(RegExp(r'__(.+?)__'), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
      .replaceAll(RegExp(r'_(.+?)_'), r'$1')
      .replaceAll(RegExp(r'`(.+?)`'), r'$1')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Maps common English AI section titles to Swahili when [languageCode] is `sw`.
String localizedAdviceTitle(String languageCode, String title) {
  if (languageCode != 'sw') return title;

  final key = title.toLowerCase();
  const swTitles = {
    'summary': 'Muhtasari',
    'health effect': 'Athari za Afya',
    'who is at risk': 'Nani yuko Hatari',
    'at risk': 'Walioko Hatari',
    'protective action': 'Hatua za Kujilinda',
    'what to avoid': 'Nini Epukwe',
    'avoid': 'Epuka',
    'forecast': 'Utabiri',
    'hourly': 'Kwa Saa',
    'recommendation': 'Mapendekezo',
    'general advice': 'Ushauri wa Jumla',
    'outdoor activity': 'Shughuli za Nje',
    'indoor': 'Ndani',
  };

  for (final entry in swTitles.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return title;
}
