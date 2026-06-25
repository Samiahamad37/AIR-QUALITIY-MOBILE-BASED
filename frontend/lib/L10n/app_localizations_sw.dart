// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'AirWatch';

  @override
  String get navHome => 'Nyumbani';

  @override
  String get navForecast => 'Utabiri';

  @override
  String get navHealth => 'Afya';

  @override
  String get navMap => 'Ramani';

  @override
  String get navSettings => 'Mipangilio';

  @override
  String get homeYourLocation => 'Mahali Pako';

  @override
  String homeUpdated(String time) {
    return 'Imesasishwa $time';
  }

  @override
  String get homeTodayTrend => 'Mwenendo wa AQI Leo';

  @override
  String get homePollutants => 'Uchambuzi wa Vichafuzi';

  @override
  String get homeHealthAdvisory => 'Ushauri wa Afya';

  @override
  String get homeTemperature => 'Joto';

  @override
  String get homeHumidity => 'Unyevu';

  @override
  String get homeWind => 'Upepo';

  @override
  String get homeLocation => 'Mahali';

  @override
  String get forecastTitle => 'Utabiri wa AQI';

  @override
  String get forecastAiPowered => 'Inayoendeshwa na AI';

  @override
  String get forecast7Day => 'Utabiri wa Siku 7';

  @override
  String get forecastHourly => 'AQI kwa Saa — Leo';

  @override
  String get forecastSelectedDay => 'Maelezo ya Siku Iliyochaguliwa';

  @override
  String get forecastInsights => 'Maarifa ya Akili';

  @override
  String get forecastMlModel => 'Mfano wa Utabiri wa ML';

  @override
  String get forecastMlSub =>
      'Utabiri unaotumia mfano wako ulioelekezwa · Unasasishwa kila masaa 3';

  @override
  String get forecastMinToday => 'Kiwango cha Chini Leo';

  @override
  String get forecastMaxToday => 'Kiwango cha Juu Leo';

  @override
  String get forecastTrend => 'Mwenendo';

  @override
  String get forecastImproving => '↓ Inaboreska';

  @override
  String get forecastToday => 'Leo';

  @override
  String get healthTitle => 'Mwongozo wa Afya';

  @override
  String get healthSelectGroup => 'Chagua Kundi';

  @override
  String get healthGuidance => 'Mwongozo wa Afya';

  @override
  String get healthGeneralTips => 'Vidokezo vya Jumla';

  @override
  String get healthCurrentAqi => 'AQI ya Sasa';

  @override
  String get healthTakePrec => 'Chukua tahadhari leo';

  @override
  String get healthOfMax => 'ya kiwango cha juu';

  @override
  String get healthNoGuidance =>
      'Hakuna mwongozo unaopatikana kwa mchanganyiko huu.';

  @override
  String get groupGeneral => 'Umma';

  @override
  String get groupChildren => 'Watoto';

  @override
  String get groupElderly => 'Wazee';

  @override
  String get groupPregnant => 'Wajawazito';

  @override
  String get groupAsthma => 'Pumu';

  @override
  String get groupOutdoor => 'Wafanyakazi wa Nje';

  @override
  String get tipMaskTitle => 'Vaa N95';

  @override
  String get tipMaskDesc => 'Tumia barakoa za N95/KN95 nje wakati AQI > 100';

  @override
  String get tipPurifierTitle => 'Kitakasishaji Hewa';

  @override
  String get tipPurifierDesc =>
      'Endesha vitakasishaji vya HEPA ndani kwa nguvu ya juu';

  @override
  String get tipWindowsTitle => 'Funga Madirisha';

  @override
  String get tipWindowsDesc => 'Funga madirisha wakati wa kilele cha uchafuzi';

  @override
  String get tipHydrateTitle => 'Kunywa Maji';

  @override
  String get tipHydrateDesc => 'Kunywa maji mengi ili kusafisha vichafuzi';

  @override
  String get tipExerciseTitle => 'Wakati wa Mazoezi';

  @override
  String get tipExerciseDesc =>
      'Fanya mazoezi asubuhi mapema wakati AQI ni ya chini';

  @override
  String get tipMonitorTitle => 'Fuatilia Afya';

  @override
  String get tipMonitorDesc =>
      'Angalia matatizo ya kupumua; tembelea daktari haraka';

  @override
  String get mapTitle => 'Ramani ya Ubora wa Hewa';

  @override
  String mapStations(int count) {
    return 'Vituo $count · Dar es Salaam';
  }

  @override
  String get mapCleanest => 'Eneo Safi Zaidi';

  @override
  String get mapWorst => 'Eneo Lenye Uchafuzi Zaidi';

  @override
  String get mapAllStations => 'Vituo Vyote';

  @override
  String get mapStationDetail => 'Maelezo ya Kituo';

  @override
  String get mapAqiScale => 'Kipimo cha AQI';

  @override
  String get mapTapStation => 'Gusa kituo kuchagua';

  @override
  String get mapDemoData => 'Data ya mfano — API haifanyi kazi';

  @override
  String get mapSearch => 'Tafuta maeneo katika Dar es Salaam…';

  @override
  String get aqiGood => 'Nzuri';

  @override
  String get aqiModerate => 'Ya Wastani';

  @override
  String get aqiSensitive => 'Mbaya kwa Makundi Nyeti';

  @override
  String get aqiUnhealthy => 'Mbaya';

  @override
  String get aqiVeryUnhealthy => 'Mbaya Sana';

  @override
  String get aqiHazardous => 'Hatari';

  @override
  String get aqiAdviceGood => 'Ubora wa hewa ni mzuri. Furahia siku yako nje!';

  @override
  String get aqiAdviceModerate =>
      'Ubora unaokubalika. Watu nyeti wanapaswa kupunguza juhudi.';

  @override
  String get aqiAdviceSensitive => 'Makundi nyeti yapunguze shughuli za nje.';

  @override
  String get aqiAdviceUnhealthy =>
      'Kila mtu apunguze shughuli za muda mrefu nje.';

  @override
  String get aqiAdviceVery =>
      'Tahadhari ya afya! Kila mtu aepuke shughuli za nje.';

  @override
  String get aqiAdviceHazardous => 'Hali ya dharura. Kaa ndani mara moja.';

  @override
  String get settingsTitle => 'Mipangilio';

  @override
  String get settingsPreferences => 'Mapendeleo';

  @override
  String get settingsDarkMode => 'Hali ya Giza';

  @override
  String get settingsDarkModeSub => 'Mwonekano wa programu';

  @override
  String get settingsNotifications => 'Arifa';

  @override
  String get settingsNotifSub => 'Tahadhari na masasisho ya AQI';

  @override
  String get settingsBiometric => 'Ufunguzi wa Kibiolojia';

  @override
  String get settingsBiometricSub => 'Alama ya vidole / Uso';

  @override
  String get settingsCloudSync => 'Usawazishaji wa Wingu';

  @override
  String get settingsCloudSyncSub => 'Sawazisha data kwenye vifaa';

  @override
  String get settingsGeneral => 'Jumla';

  @override
  String get settingsLanguage => 'Lugha';

  @override
  String get settingsRegion => 'Mkoa';

  @override
  String get settingsStorage => 'Hifadhi';

  @override
  String get settingsAbout => 'Kuhusu';

  @override
  String get settingsAirQuality => 'Ubora wa Hewa';

  @override
  String get settingsDefaultStation => 'Kituo cha Msingi';

  @override
  String get settingsAqiThreshold => 'Kiwango cha Tahadhari cha AQI';

  @override
  String get settingsRefreshInterval => 'Kipindi cha Kusasisha';

  @override
  String get settingsAccount => 'Akaunti';

  @override
  String get settingsPrivacy => 'Faragha na Usalama';

  @override
  String get settingsHelp => 'Msaada na Usaidizi';

  @override
  String get settingsRate => 'Kadiria Programu';

  @override
  String get settingsGuestName => 'Mtumiaji wa Mgeni';

  @override
  String get settingsGuestSub => 'Ingia ili kusawazisha data yako';

  @override
  String get settingsSignIn => 'Ingia';

  @override
  String get settingsCreateAccount => 'Fungua akaunti';

  @override
  String get settingsCtaSub => 'Hifadhi vituo, historia\nna tahadhari maalum.';

  @override
  String get settingsGetStarted => 'Anza';

  @override
  String get settingsFooter => 'AirWatch v1.0.0 · Dar es Salaam';

  @override
  String get settingsCacheCleared => 'Kache imefutwa';

  @override
  String get settingsClearCache => 'Futa Kache';

  @override
  String get settingsDone => 'Imekamilika';

  @override
  String get settingsClose => 'Funga';

  @override
  String get settingsOn => 'IMEWASHWA';

  @override
  String get settingsOff => 'IMEZIMWA';

  @override
  String get errorCannotReach =>
      'Haiwezi kufikia seva.\nAngalia IP yako katika api_service.dart';

  @override
  String get errorRetry => 'Jaribu Tena';

  @override
  String get loadingFetching => 'Inapata ubora wa hewa…';

  @override
  String get timeJustNow => 'sasa hivi';

  @override
  String timeMinutesAgo(int minutes) {
    return 'dakika $minutes zilizopita';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'masaa $hours yaliyopita';
  }

  @override
  String get forecastNext24Hours => 'Masaa 24 Yajayo';

  @override
  String get forecastHistoricalTrends => 'Mwenendo wa Kihistoria';

  @override
  String get forecastNoData => 'Hakuna data inayopatikana';

  @override
  String get forecastMlNotice =>
      'Utabiri wa ML unakuja hivi karibuni — unaonyesha utabiri uliokadirika kulingana na hali za sasa.';

  @override
  String get aqiScaleGood => 'Nzuri (0-50)';

  @override
  String get aqiScaleModerate => 'Ya Wastani (51-100)';

  @override
  String get aqiScaleSensitive => 'Nyeti (101-150)';

  @override
  String get aqiScaleUnhealthy => 'Mbaya (151-200)';

  @override
  String get aqiScaleVeryUnhealthy => 'Mbaya Sana (201+)';

  @override
  String get mapRetry => 'Jaribu Tena';

  @override
  String get settingsDarkModeOn => 'Hali ya giza imewashwa';

  @override
  String get settingsDarkModeOff => 'Hali ya giza imezimwa';

  @override
  String get settingsNotifOn => 'Arifa zimefungwa';

  @override
  String get settingsNotifOff => 'Arifa zimezimwa';

  @override
  String get settingsBiometricOn => 'Kibiolojia imewashwa';

  @override
  String get settingsBiometricOff => 'Kibiolojia imezimwa';

  @override
  String get settingsCloudSyncOn => 'Usawazishaji wa wingu umewashwa';

  @override
  String get settingsCloudSyncOff => 'Usawazishaji wa wingu umezimwa';

  @override
  String settingsLanguageSelected(String language) {
    return 'Lugha: $language';
  }

  @override
  String settingsRegionSelected(String region) {
    return 'Mkoa: $region';
  }

  @override
  String settingsStationSelected(String station) {
    return 'Kituo: $station';
  }

  @override
  String settingsThresholdSelected(String threshold) {
    return 'Kiwango: $threshold';
  }

  @override
  String settingsRefreshSelected(String interval) {
    return 'Kusasisha: $interval';
  }

  @override
  String get settingsRateThanks => '⭐ Asante!';

  @override
  String get settingsAboutContent =>
      'Programu ya Ufuatiliaji wa Ubora wa Hewa\nToleo 1.0.0\n\nInafuatilia ubora wa hewa wa Dar es Salaam\nkwa wakati halisi kwa kutumia vituo vya IoT na utabiri unaotumia ML.';

  @override
  String get alertHazardous => 'HATARI — dharura ya afya. Kaa ndani mara moja.';

  @override
  String get alertVeryUnhealthy =>
      'Mbaya sana — epuke mawasiliano yote ya nje. Tumia vitakasishaji vya hewa.';

  @override
  String get alertUnhealthy =>
      'Hewa mbaya — kila mtu apunguze shughuli za nje sasa.';

  @override
  String get alertSensitive => 'Makundi nyeti yachukue tahadhari za ziada nje.';

  @override
  String get healthTips => 'vidokezo';

  @override
  String get healthRetry => 'Jaribu Tena';
}
