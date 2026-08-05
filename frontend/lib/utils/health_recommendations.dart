enum _AqiTier { good, moderate, sensitive, unhealthy, hazardous }

_AqiTier _tierForAqi(int aqi) {
  if (aqi <= 50) return _AqiTier.good;
  if (aqi <= 100) return _AqiTier.moderate;
  if (aqi <= 150) return _AqiTier.sensitive;
  if (aqi <= 200) return _AqiTier.unhealthy;
  return _AqiTier.hazardous;
}

bool _isSwahili(String languageCode) => languageCode == 'sw';

const _fallbackEn = {
  _AqiTier.good: 'No specific guidance needed.',
  _AqiTier.moderate: 'Limit prolonged outdoor activity.',
  _AqiTier.sensitive: 'Sensitive groups should take precautions.',
  _AqiTier.unhealthy: 'Reduce outdoor activity significantly.',
  _AqiTier.hazardous: 'Emergency conditions. Stay indoors immediately.',
};

const _fallbackSw = {
  _AqiTier.good: 'Hakuna mwongozo maalum unaohitajika.',
  _AqiTier.moderate: 'Punguza shughuli za muda mrefu nje.',
  _AqiTier.sensitive: 'Makundi nyeti yanapaswa kuchukua tahadhari.',
  _AqiTier.unhealthy: 'Punguza shughuli za nje kwa kiasi kikubwa.',
  _AqiTier.hazardous: 'Hali ya dharura. Kaa ndani mara moja.',
};

const _recsEn = {
  _AqiTier.good: {
    'general': [
      'Air quality is satisfactory.',
      'Enjoy outdoor activities freely.',
      'Open windows for fresh air.',
    ],
    'children': [
      'Safe for outdoor play.',
      'No restrictions needed.',
    ],
    'elderly': [
      'Safe for outdoor walks.',
      'Normal activities recommended.',
    ],
    'pregnant': [
      'Safe for light outdoor activity.',
      'Fresh air is beneficial.',
    ],
    'asthma': [
      'Low risk today.',
      'Keep rescue inhaler handy as always.',
    ],
    'outdoor_workers': [
      'Safe working conditions.',
      'Stay hydrated.',
    ],
  },
  _AqiTier.moderate: {
    'general': [
      'Air quality is acceptable.',
      'Unusually sensitive people should limit prolonged outdoor exertion.',
    ],
    'children': [
      'Outdoor play is generally safe.',
      'Watch for any unusual symptoms.',
    ],
    'elderly': [
      'Light outdoor activity is fine.',
      'Avoid prolonged strenuous exercise.',
    ],
    'pregnant': [
      'Light walks are safe.',
      'Avoid heavy outdoor exertion.',
    ],
    'asthma': [
      'Monitor symptoms closely.',
      'Limit prolonged outdoor exertion.',
      'Keep inhaler accessible.',
    ],
    'outdoor_workers': [
      'Take regular breaks indoors.',
      'Stay hydrated throughout the day.',
    ],
  },
  _AqiTier.sensitive: {
    'general': [
      'Sensitive groups should reduce outdoor activity.',
      'Others can continue normal activities.',
    ],
    'children': [
      'Reduce prolonged outdoor exertion.',
      'Avoid outdoor sports.',
      'Keep outdoor time short.',
    ],
    'elderly': [
      'Limit outdoor activity.',
      'Stay indoors during peak hours.',
      'Monitor for breathing difficulty.',
    ],
    'pregnant': [
      'Reduce outdoor activity.',
      'Avoid areas with heavy traffic.',
      'Consult doctor if concerned.',
    ],
    'asthma': [
      'Avoid outdoor exertion.',
      'Use air purifier indoors.',
      'Have rescue medication ready.',
      'Seek medical help if symptoms worsen.',
    ],
    'outdoor_workers': [
      'Wear N95 mask.',
      'Increase rest breaks.',
      'Move heavy tasks indoors if possible.',
    ],
  },
  _AqiTier.unhealthy: {
    'general': [
      'Everyone should reduce prolonged outdoor exertion.',
      'Take more breaks during outdoor activities.',
      'Wear a mask outdoors.',
    ],
    'children': [
      'Avoid all outdoor exertion.',
      'Cancel outdoor sports.',
      'Keep windows closed.',
    ],
    'elderly': [
      'Stay indoors.',
      'Run air purifier.',
      'Avoid all strenuous activity.',
    ],
    'pregnant': [
      'Stay indoors as much as possible.',
      'Use air purifier.',
      'Contact doctor if experiencing symptoms.',
    ],
    'asthma': [
      'Stay indoors.',
      'Use air purifier on high.',
      'Avoid all outdoor activity.',
      'Have emergency contacts ready.',
    ],
    'outdoor_workers': [
      'Wear N95/KN95 mask at all times.',
      'Request to work indoors.',
      'Limit outdoor exposure to minimum.',
    ],
  },
  _AqiTier.hazardous: {
    'general': [
      'Avoid all outdoor activity.',
      'Stay indoors with windows closed.',
      'Use air purifier if available.',
    ],
    'children': [
      'Do not go outside.',
      'Keep all windows and doors closed.',
      'Use HEPA air purifier.',
    ],
    'elderly': [
      'Emergency conditions.',
      'Stay indoors immediately.',
      'Seek medical help if experiencing symptoms.',
    ],
    'pregnant': [
      'Stay indoors immediately.',
      'Call doctor if experiencing any symptoms.',
      'Use air purifier.',
    ],
    'asthma': [
      'Do not go outside under any circumstances.',
      'Use air purifier on maximum.',
      'Have emergency medications ready.',
      'Call doctor proactively.',
    ],
    'outdoor_workers': [
      'Stop all outdoor work immediately.',
      'Evacuate to indoor shelter.',
      'Seek medical attention if symptomatic.',
    ],
  },
};

const _recsSw = {
  _AqiTier.good: {
    'general': [
      'Ubora wa hewa uko wa kuridhisha.',
      'Furahia shughuli za nje kwa uhuru.',
      'Fungua madirisha kwa hewa safi.',
    ],
    'children': [
      'Salama kwa michezo ya nje.',
      'Hakuna vizuizi vinavyohitajika.',
    ],
    'elderly': [
      'Salama kwa matembezi ya nje.',
      'Shughuli za kawaida zinapendekezwa.',
    ],
    'pregnant': [
      'Salama kwa shughuli nyepesi za nje.',
      'Hewa safi ina manufaa.',
    ],
    'asthma': [
      'Hatari ndogo leo.',
      'Weka kifaa cha kuvuta dawa karibu kama kawaida.',
    ],
    'outdoor_workers': [
      'Hali salama za kufanya kazi.',
      'Kunywa maji ya kutosha.',
    ],
  },
  _AqiTier.moderate: {
    'general': [
      'Ubora wa hewa unakubalika.',
      'Watu wenye usiokua wa kawaida wanapaswa kupunguza juhudi za muda mrefu nje.',
    ],
    'children': [
      'Michezo ya nje kwa ujumla ni salama.',
      'Angalia dalili zozote zisizo za kawaida.',
    ],
    'elderly': [
      'Shughuli nyepesi za nje ni sawa.',
      'Epuka mazoezi mazito ya muda mrefu.',
    ],
    'pregnant': [
      'Matembezi mepesi ni salama.',
      'Epuka juhudi nzito za nje.',
    ],
    'asthma': [
      'Fuatilia dalili kwa karibu.',
      'Punguza juhudi za muda mrefu nje.',
      'Weka kifaa cha kuvuta dawa mahali pa kufikia.',
    ],
    'outdoor_workers': [
      'Pumzika mara kwa mara ndani.',
      'Kunywa maji ya kutosha siku nzima.',
    ],
  },
  _AqiTier.sensitive: {
    'general': [
      'Makundi nyeti yanapaswa kupunguza shughuli za nje.',
      'Wengine wanaweza kuendelea na shughuli za kawaida.',
    ],
    'children': [
      'Punguza juhudi za muda mrefu nje.',
      'Epuka michezo ya nje.',
      'Weka muda wa nje mfupi.',
    ],
    'elderly': [
      'Punguza shughuli za nje.',
      'Kaa ndani wakati wa saa za kilele.',
      'Angalia ugumu wa kupumua.',
    ],
    'pregnant': [
      'Punguza shughuli za nje.',
      'Epuka maeneo yenye trafiki nyingi.',
      'Wasiliana na daktari ikiwa una wasiwasi.',
    ],
    'asthma': [
      'Epuka juhudi za nje.',
      'Tumia kifaa cha kusafisha hewa ndani.',
      'Kuwa na dawa ya dharura tayari.',
      'Tafuta msaada wa matibabu ikiwa dalili zinaongezeka.',
    ],
    'outdoor_workers': [
      'Vaa barakoa ya N95.',
      'Ongeza mapumziko.',
      'Hamisha kazi nzito ndani ikiwezekana.',
    ],
  },
  _AqiTier.unhealthy: {
    'general': [
      'Kila mtu anapaswa kupunguza juhudi za muda mrefu nje.',
      'Chukua mapumziko zaidi wakati wa shughuli za nje.',
      'Vaa barakoa nje.',
    ],
    'children': [
      'Epuka juhudi zote za nje.',
      'Ghairi michezo ya nje.',
      'Weka madirisha yamefungwa.',
    ],
    'elderly': [
      'Kaa ndani.',
      'Washa kifaa cha kusafisha hewa.',
      'Epuka shughuli zote nzito.',
    ],
    'pregnant': [
      'Kaa ndani kadri iwezekanavyo.',
      'Tumia kifaa cha kusafisha hewa.',
      'Wasiliana na daktari ikiwa una dalili.',
    ],
    'asthma': [
      'Kaa ndani.',
      'Tumia kifaa cha kusafisha hewa kwa nguvu.',
      'Epuka shughuli zote za nje.',
      'Kuwa na nambari za dharura tayari.',
    ],
    'outdoor_workers': [
      'Vaa barakoa ya N95/KN95 kila wakati.',
      'Omba kufanya kazi ndani.',
      'Punguza muda wa nje kwa kiwango cha chini.',
    ],
  },
  _AqiTier.hazardous: {
    'general': [
      'Epuka shughuli zote za nje.',
      'Kaa ndani na madirisha yamefungwa.',
      'Tumia kifaa cha kusafisha hewa ikiwa kinapatikana.',
    ],
    'children': [
      'Usitoke nje.',
      'Weka madirisha na milango yote yamefungwa.',
      'Tumia kifaa cha kusafisha hewa cha HEPA.',
    ],
    'elderly': [
      'Hali ya dharura.',
      'Kaa ndani mara moja.',
      'Tafuta msaada wa matibabu ikiwa una dalili.',
    ],
    'pregnant': [
      'Kaa ndani mara moja.',
      'Piga simu daktari ikiwa una dalili yoyote.',
      'Tumia kifaa cha kusafisha hewa.',
    ],
    'asthma': [
      'Usitoke nje kwa hali yoyote.',
      'Tumia kifaa cha kusafisha hewa kwa kiwango cha juu.',
      'Kuwa na dawa za dharura tayari.',
      'Piga simu daktari mapema.',
    ],
    'outdoor_workers': [
      'Acha kazi zote za nje mara moja.',
      'Hamia mahali pa kujikinga ndani.',
      'Tafuta matibabu ikiwa una dalili.',
    ],
  },
};

List<String> healthRecsForGroup(String languageCode, String groupId, int aqi) {
  final tier = _tierForAqi(aqi);
  final recs = _isSwahili(languageCode) ? _recsSw : _recsEn;
  return List<String>.from(
    recs[tier]?[groupId] ?? [healthRecsFallback(languageCode, aqi)],
  );
}

String healthRecsFallback(String languageCode, int aqi) {
  final tier = _tierForAqi(aqi);
  return _isSwahili(languageCode) ? _fallbackSw[tier]! : _fallbackEn[tier]!;
}
