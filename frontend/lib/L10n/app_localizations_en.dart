// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AirWatch';

  @override
  String get navHome => 'Home';

  @override
  String get navForecast => 'Forecast';

  @override
  String get navHealth => 'Health';

  @override
  String get navMap => 'Map';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeYourLocation => 'Your Location';

  @override
  String homeUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get homeTodayTrend => 'Today\'s AQI Trend';

  @override
  String get homePollutants => 'Pollutant Breakdown';

  @override
  String get homeHealthAdvisory => 'Health Advisory';

  @override
  String get homeTemperature => 'Temperature';

  @override
  String get homeHumidity => 'Humidity';

  @override
  String get homeWind => 'Wind';

  @override
  String get homeLocation => 'Location';

  @override
  String get forecastTitle => 'AQI Forecast';

  @override
  String get forecastAiPowered => 'AI Powered';

  @override
  String get forecast7Day => '7-Day Forecast';

  @override
  String get forecastHourly => 'Hourly AQI — Today';

  @override
  String get forecastSelectedDay => 'Selected Day Detail';

  @override
  String get forecastInsights => 'Smart Insights';

  @override
  String get forecastMlModel => 'ML Prediction Model';

  @override
  String get forecastMlSub =>
      'Forecasts powered by your trained model · Updated every 3 hours';

  @override
  String get forecastMinToday => 'Min Today';

  @override
  String get forecastMaxToday => 'Max Today';

  @override
  String get forecastTrend => 'Trend';

  @override
  String get forecastImproving => '↓ Improving';

  @override
  String get forecastToday => 'Today';

  @override
  String get healthTitle => 'Health Guidance';

  @override
  String get healthSelectGroup => 'Select Group';

  @override
  String get healthGuidance => 'Health Guidance';

  @override
  String get healthGeneralTips => 'General Tips';

  @override
  String get healthCurrentAqi => 'Current AQI';

  @override
  String get healthTakePrec => 'Take precautions today';

  @override
  String get healthOfMax => 'of max';

  @override
  String get healthNoGuidance => 'No guidance available for this combination.';

  @override
  String get groupGeneral => 'General';

  @override
  String get groupChildren => 'Children';

  @override
  String get groupElderly => 'Elderly';

  @override
  String get groupPregnant => 'Pregnant';

  @override
  String get groupAsthma => 'Asthma';

  @override
  String get groupOutdoor => 'Outdoor Work';

  @override
  String get tipMaskTitle => 'Wear N95';

  @override
  String get tipMaskDesc => 'Use N95/KN95 masks outdoors when AQI > 100';

  @override
  String get tipPurifierTitle => 'Air Purifier';

  @override
  String get tipPurifierDesc => 'Run HEPA purifiers indoors on high settings';

  @override
  String get tipWindowsTitle => 'Close Windows';

  @override
  String get tipWindowsDesc =>
      'Keep windows sealed during peak pollution hours';

  @override
  String get tipHydrateTitle => 'Stay Hydrated';

  @override
  String get tipHydrateDesc => 'Drink plenty of water to flush pollutants';

  @override
  String get tipExerciseTitle => 'Exercise Timing';

  @override
  String get tipExerciseDesc => 'Exercise early morning when AQI is lowest';

  @override
  String get tipMonitorTitle => 'Monitor Health';

  @override
  String get tipMonitorDesc =>
      'Watch for breathing issues; see a doctor promptly';

  @override
  String get mapTitle => 'Air Quality Map';

  @override
  String mapStations(int count) {
    return '$count stations · Dar es Salaam';
  }

  @override
  String get mapCleanest => 'Cleanest Area';

  @override
  String get mapWorst => 'Most Polluted';

  @override
  String get mapAllStations => 'All Stations';

  @override
  String get mapStationDetail => 'Station Detail';

  @override
  String get mapAqiScale => 'AQI Scale';

  @override
  String get mapTapStation => 'Tap a station to select';

  @override
  String get mapDemoData => 'Demo data — API offline';

  @override
  String get mapSearch => 'Search areas in Dar es Salaam…';

  @override
  String get aqiGood => 'Good';

  @override
  String get aqiModerate => 'Moderate';

  @override
  String get aqiSensitive => 'Unhealthy for Sensitive Groups';

  @override
  String get aqiUnhealthy => 'Unhealthy';

  @override
  String get aqiVeryUnhealthy => 'Very Unhealthy';

  @override
  String get aqiHazardous => 'Hazardous';

  @override
  String get aqiAdviceGood =>
      'Air quality is satisfactory. Enjoy your day outside!';

  @override
  String get aqiAdviceModerate =>
      'Acceptable quality. Sensitive individuals should limit exertion.';

  @override
  String get aqiAdviceSensitive =>
      'Sensitive groups should reduce outdoor activities.';

  @override
  String get aqiAdviceUnhealthy =>
      'Everyone should reduce prolonged outdoor exertion.';

  @override
  String get aqiAdviceVery =>
      'Health alert! Everyone should avoid outdoor activity.';

  @override
  String get aqiAdviceHazardous =>
      'Emergency conditions. Stay indoors immediately.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeSub => 'App appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifSub => 'AQI alerts & updates';

  @override
  String get settingsBiometric => 'Biometric Unlock';

  @override
  String get settingsBiometricSub => 'Fingerprint / Face ID';

  @override
  String get settingsCloudSync => 'Cloud Sync';

  @override
  String get settingsCloudSyncSub => 'Sync data across devices';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsRegion => 'Region';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAirQuality => 'Air Quality';

  @override
  String get settingsDefaultStation => 'Default Station';

  @override
  String get settingsAqiThreshold => 'AQI Alert Threshold';

  @override
  String get settingsRefreshInterval => 'Refresh Interval';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPrivacy => 'Privacy & Security';

  @override
  String get settingsHelp => 'Help & Support';

  @override
  String get settingsRate => 'Rate the App';

  @override
  String get settingsGuestName => 'Guest User';

  @override
  String get settingsGuestSub => 'Sign in to sync your data';

  @override
  String get settingsSignIn => 'Sign In';

  @override
  String get settingsCreateAccount => 'Create an account';

  @override
  String get settingsCtaSub =>
      'Save your stations, history\nand personalized alerts.';

  @override
  String get settingsGetStarted => 'Get Started';

  @override
  String get settingsFooter => 'AirWatch v1.0.0 · Dar es Salaam';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsClearCache => 'Clear Cache';

  @override
  String get settingsDone => 'Done';

  @override
  String get settingsClose => 'Close';

  @override
  String get settingsOn => 'ON';

  @override
  String get settingsOff => 'OFF';

  @override
  String get errorCannotReach =>
      'Cannot reach server.\nCheck your IP in api_service.dart';

  @override
  String get errorRetry => 'Retry';

  @override
  String get loadingFetching => 'Fetching air quality…';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get forecastNext24Hours => 'Next 24 Hours';

  @override
  String get forecastHistoricalTrends => 'Historical Trends';

  @override
  String get forecastNoData => 'No data available';

  @override
  String get forecastMlNotice =>
      'ML predictions coming soon — showing estimated forecast based on current conditions.';

  @override
  String get aqiScaleGood => 'Good (0-50)';

  @override
  String get aqiScaleModerate => 'Moderate (51-100)';

  @override
  String get aqiScaleSensitive => 'Sensitive (101-150)';

  @override
  String get aqiScaleUnhealthy => 'Unhealthy (151-200)';

  @override
  String get aqiScaleVeryUnhealthy => 'Very Unhealthy (201+)';

  @override
  String get mapRetry => 'Retry';

  @override
  String get settingsDarkModeOn => 'Dark mode on';

  @override
  String get settingsDarkModeOff => 'Dark mode off';

  @override
  String get settingsNotifOn => 'Notifications on';

  @override
  String get settingsNotifOff => 'Notifications off';

  @override
  String get settingsBiometricOn => 'Biometric on';

  @override
  String get settingsBiometricOff => 'Biometric off';

  @override
  String get settingsCloudSyncOn => 'Cloud sync on';

  @override
  String get settingsCloudSyncOff => 'Cloud sync off';

  @override
  String settingsLanguageSelected(String language) {
    return 'Language: $language';
  }

  @override
  String settingsRegionSelected(String region) {
    return 'Region: $region';
  }

  @override
  String settingsStationSelected(String station) {
    return 'Station: $station';
  }

  @override
  String settingsThresholdSelected(String threshold) {
    return 'Threshold: $threshold';
  }

  @override
  String settingsRefreshSelected(String interval) {
    return 'Refresh: $interval';
  }

  @override
  String get settingsRateThanks => '⭐ Thank you!';

  @override
  String get settingsAboutContent =>
      'Air Quality Monitoring App\nVersion 1.0.0\n\nMonitoring Dar es Salaam\'s air quality\nin real time using IoT sensors and ML-powered forecasting.';

  @override
  String get alertHazardous =>
      'HAZARDOUS — health emergency. Stay indoors immediately.';

  @override
  String get alertVeryUnhealthy =>
      'Very unhealthy — avoid all outdoor exposure. Use air purifiers.';

  @override
  String get alertUnhealthy =>
      'Unhealthy air — everyone should reduce outdoor activity now.';

  @override
  String get alertSensitive =>
      'Sensitive groups should take extra precautions outdoors.';

  @override
  String get healthTips => 'tips';

  @override
  String get healthRetry => 'Retry';

  @override
  String get signIn => 'Ingia';

  @override
  String get createAccount => 'Unda Akaunti';
}
