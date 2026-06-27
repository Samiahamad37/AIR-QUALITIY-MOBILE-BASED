import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'L10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw')
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'AirWatch'**
  String get appTitle;

  /// Bottom nav - Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav - Forecast
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get navForecast;

  /// Bottom nav - Health
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// Bottom nav - Map
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Bottom nav - Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Location label on home screen
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get homeYourLocation;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeUpdated(String time);

  /// Section header for today's trend chart
  ///
  /// In en, this message translates to:
  /// **'Today\'s AQI Trend'**
  String get homeTodayTrend;

  /// Section header for pollutants
  ///
  /// In en, this message translates to:
  /// **'Pollutant Breakdown'**
  String get homePollutants;

  /// Section header for health advisory
  ///
  /// In en, this message translates to:
  /// **'Health Advisory'**
  String get homeHealthAdvisory;

  /// Temperature label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get homeTemperature;

  /// Humidity label
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get homeHumidity;

  /// Wind label
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get homeWind;

  /// Location label on dropdown
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get homeLocation;

  /// Forecast screen title
  ///
  /// In en, this message translates to:
  /// **'AQI Forecast'**
  String get forecastTitle;

  /// AI badge on forecast screen
  ///
  /// In en, this message translates to:
  /// **'AI Powered'**
  String get forecastAiPowered;

  /// 7-day forecast section header
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get forecast7Day;

  /// Hourly chart section header
  ///
  /// In en, this message translates to:
  /// **'Hourly AQI — Today'**
  String get forecastHourly;

  /// Selected day section header
  ///
  /// In en, this message translates to:
  /// **'Selected Day Detail'**
  String get forecastSelectedDay;

  /// Insights section header
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get forecastInsights;

  /// ML model footer label
  ///
  /// In en, this message translates to:
  /// **'ML Prediction Model'**
  String get forecastMlModel;

  /// ML model footer subtitle
  ///
  /// In en, this message translates to:
  /// **'Forecasts powered by your trained model · Updated every 3 hours'**
  String get forecastMlSub;

  /// Min AQI label
  ///
  /// In en, this message translates to:
  /// **'Min Today'**
  String get forecastMinToday;

  /// Max AQI label
  ///
  /// In en, this message translates to:
  /// **'Max Today'**
  String get forecastMaxToday;

  /// Trend label
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get forecastTrend;

  /// Improving trend label
  ///
  /// In en, this message translates to:
  /// **'↓ Improving'**
  String get forecastImproving;

  /// Today label on forecast strip
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get forecastToday;

  /// Health screen title
  ///
  /// In en, this message translates to:
  /// **'Health Guidance'**
  String get healthTitle;

  /// Group selector section header
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get healthSelectGroup;

  /// Recommendations section header
  ///
  /// In en, this message translates to:
  /// **'Health Guidance'**
  String get healthGuidance;

  /// Tips section header
  ///
  /// In en, this message translates to:
  /// **'General Tips'**
  String get healthGeneralTips;

  /// Current AQI label
  ///
  /// In en, this message translates to:
  /// **'Current AQI'**
  String get healthCurrentAqi;

  /// Precaution subtitle
  ///
  /// In en, this message translates to:
  /// **'Take precautions today'**
  String get healthTakePrec;

  /// Percentage of max label
  ///
  /// In en, this message translates to:
  /// **'of max'**
  String get healthOfMax;

  /// Empty state for recommendations
  ///
  /// In en, this message translates to:
  /// **'No guidance available for this combination.'**
  String get healthNoGuidance;

  /// General public group
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get groupGeneral;

  /// Children group
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get groupChildren;

  /// Elderly group
  ///
  /// In en, this message translates to:
  /// **'Elderly'**
  String get groupElderly;

  /// Pregnant group
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get groupPregnant;

  /// Asthma group
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get groupAsthma;

  /// Outdoor workers group
  ///
  /// In en, this message translates to:
  /// **'Outdoor Work'**
  String get groupOutdoor;

  /// Tip 1 title
  ///
  /// In en, this message translates to:
  /// **'Wear N95'**
  String get tipMaskTitle;

  /// Tip 1 description
  ///
  /// In en, this message translates to:
  /// **'Use N95/KN95 masks outdoors when AQI > 100'**
  String get tipMaskDesc;

  /// Tip 2 title
  ///
  /// In en, this message translates to:
  /// **'Air Purifier'**
  String get tipPurifierTitle;

  /// Tip 2 description
  ///
  /// In en, this message translates to:
  /// **'Run HEPA purifiers indoors on high settings'**
  String get tipPurifierDesc;

  /// Tip 3 title
  ///
  /// In en, this message translates to:
  /// **'Close Windows'**
  String get tipWindowsTitle;

  /// Tip 3 description
  ///
  /// In en, this message translates to:
  /// **'Keep windows sealed during peak pollution hours'**
  String get tipWindowsDesc;

  /// Tip 4 title
  ///
  /// In en, this message translates to:
  /// **'Stay Hydrated'**
  String get tipHydrateTitle;

  /// Tip 4 description
  ///
  /// In en, this message translates to:
  /// **'Drink plenty of water to flush pollutants'**
  String get tipHydrateDesc;

  /// Tip 5 title
  ///
  /// In en, this message translates to:
  /// **'Exercise Timing'**
  String get tipExerciseTitle;

  /// Tip 5 description
  ///
  /// In en, this message translates to:
  /// **'Exercise early morning when AQI is lowest'**
  String get tipExerciseDesc;

  /// Tip 6 title
  ///
  /// In en, this message translates to:
  /// **'Monitor Health'**
  String get tipMonitorTitle;

  /// Tip 6 description
  ///
  /// In en, this message translates to:
  /// **'Watch for breathing issues; see a doctor promptly'**
  String get tipMonitorDesc;

  /// Map screen title
  ///
  /// In en, this message translates to:
  /// **'Air Quality Map'**
  String get mapTitle;

  /// Station count label
  ///
  /// In en, this message translates to:
  /// **'{count} stations · Dar es Salaam'**
  String mapStations(int count);

  /// Cleanest area label
  ///
  /// In en, this message translates to:
  /// **'Cleanest Area'**
  String get mapCleanest;

  /// Most polluted label
  ///
  /// In en, this message translates to:
  /// **'Most Polluted'**
  String get mapWorst;

  /// All stations section header
  ///
  /// In en, this message translates to:
  /// **'All Stations'**
  String get mapAllStations;

  /// Station detail section header
  ///
  /// In en, this message translates to:
  /// **'Station Detail'**
  String get mapStationDetail;

  /// AQI scale legend label
  ///
  /// In en, this message translates to:
  /// **'AQI Scale'**
  String get mapAqiScale;

  /// Map tap hint
  ///
  /// In en, this message translates to:
  /// **'Tap a station to select'**
  String get mapTapStation;

  /// Offline fallback badge
  ///
  /// In en, this message translates to:
  /// **'Demo data — API offline'**
  String get mapDemoData;

  /// Map search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search areas in Dar es Salaam…'**
  String get mapSearch;

  /// AQI level - Good
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get aqiGood;

  /// AQI level - Moderate
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get aqiModerate;

  /// AQI level - Sensitive
  ///
  /// In en, this message translates to:
  /// **'Unhealthy for Sensitive Groups'**
  String get aqiSensitive;

  /// AQI level - Unhealthy
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get aqiUnhealthy;

  /// AQI level - Very Unhealthy
  ///
  /// In en, this message translates to:
  /// **'Very Unhealthy'**
  String get aqiVeryUnhealthy;

  /// AQI level - Hazardous
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get aqiHazardous;

  /// Advice for Good AQI
  ///
  /// In en, this message translates to:
  /// **'Air quality is satisfactory. Enjoy your day outside!'**
  String get aqiAdviceGood;

  /// Advice for Moderate AQI
  ///
  /// In en, this message translates to:
  /// **'Acceptable quality. Sensitive individuals should limit exertion.'**
  String get aqiAdviceModerate;

  /// Advice for Sensitive AQI
  ///
  /// In en, this message translates to:
  /// **'Sensitive groups should reduce outdoor activities.'**
  String get aqiAdviceSensitive;

  /// Advice for Unhealthy AQI
  ///
  /// In en, this message translates to:
  /// **'Everyone should reduce prolonged outdoor exertion.'**
  String get aqiAdviceUnhealthy;

  /// Advice for Very Unhealthy AQI
  ///
  /// In en, this message translates to:
  /// **'Health alert! Everyone should avoid outdoor activity.'**
  String get aqiAdviceVery;

  /// Advice for Hazardous AQI
  ///
  /// In en, this message translates to:
  /// **'Emergency conditions. Stay indoors immediately.'**
  String get aqiAdviceHazardous;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Preferences section
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// Dark mode subtitle
  ///
  /// In en, this message translates to:
  /// **'App appearance'**
  String get settingsDarkModeSub;

  /// Notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'AQI alerts & updates'**
  String get settingsNotifSub;

  /// Biometric toggle
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get settingsBiometric;

  /// Biometric subtitle
  ///
  /// In en, this message translates to:
  /// **'Fingerprint / Face ID'**
  String get settingsBiometricSub;

  /// Cloud sync toggle
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get settingsCloudSync;

  /// Cloud sync subtitle
  ///
  /// In en, this message translates to:
  /// **'Sync data across devices'**
  String get settingsCloudSyncSub;

  /// General section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// Language row
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Region row
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get settingsRegion;

  /// Storage row
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// About row
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Air quality section
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get settingsAirQuality;

  /// Default station row
  ///
  /// In en, this message translates to:
  /// **'Default Station'**
  String get settingsDefaultStation;

  /// AQI threshold row
  ///
  /// In en, this message translates to:
  /// **'AQI Alert Threshold'**
  String get settingsAqiThreshold;

  /// Refresh interval row
  ///
  /// In en, this message translates to:
  /// **'Refresh Interval'**
  String get settingsRefreshInterval;

  /// Account section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Privacy row
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacy;

  /// Help row
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelp;

  /// Rate app row
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get settingsRate;

  /// Guest card name
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get settingsGuestName;

  /// Guest card subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get settingsGuestSub;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settingsSignIn;

  /// CTA title
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get settingsCreateAccount;

  /// CTA subtitle
  ///
  /// In en, this message translates to:
  /// **'Save your stations, history\nand personalized alerts.'**
  String get settingsCtaSub;

  /// CTA button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get settingsGetStarted;

  /// Footer text
  ///
  /// In en, this message translates to:
  /// **'AirWatch v1.0.0 · Dar es Salaam'**
  String get settingsFooter;

  /// Cache cleared toast
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// Clear cache button
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCache;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settingsDone;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsClose;

  /// ON state label
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get settingsOn;

  /// OFF state label
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get settingsOff;

  /// Server unreachable error
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server.\nCheck your IP in api_service.dart'**
  String get errorCannotReach;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Fetching air quality…'**
  String get loadingFetching;

  /// Time - just now
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// Time - minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// Time - hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// Next 24 hours section header
  ///
  /// In en, this message translates to:
  /// **'Next 24 Hours'**
  String get forecastNext24Hours;

  /// Historical trends section header
  ///
  /// In en, this message translates to:
  /// **'Historical Trends'**
  String get forecastHistoricalTrends;

  /// No data message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get forecastNoData;

  /// ML notice banner
  ///
  /// In en, this message translates to:
  /// **'ML predictions coming soon — showing estimated forecast based on current conditions.'**
  String get forecastMlNotice;

  /// AQI scale - Good
  ///
  /// In en, this message translates to:
  /// **'Good (0-50)'**
  String get aqiScaleGood;

  /// AQI scale - Moderate
  ///
  /// In en, this message translates to:
  /// **'Moderate (51-100)'**
  String get aqiScaleModerate;

  /// AQI scale - Sensitive
  ///
  /// In en, this message translates to:
  /// **'Sensitive (101-150)'**
  String get aqiScaleSensitive;

  /// AQI scale - Unhealthy
  ///
  /// In en, this message translates to:
  /// **'Unhealthy (151-200)'**
  String get aqiScaleUnhealthy;

  /// AQI scale - Very Unhealthy
  ///
  /// In en, this message translates to:
  /// **'Very Unhealthy (201+)'**
  String get aqiScaleVeryUnhealthy;

  /// Map retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapRetry;

  /// Dark mode enabled message
  ///
  /// In en, this message translates to:
  /// **'Dark mode on'**
  String get settingsDarkModeOn;

  /// Dark mode disabled message
  ///
  /// In en, this message translates to:
  /// **'Dark mode off'**
  String get settingsDarkModeOff;

  /// Notifications enabled message
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get settingsNotifOn;

  /// Notifications disabled message
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get settingsNotifOff;

  /// Biometric enabled message
  ///
  /// In en, this message translates to:
  /// **'Biometric on'**
  String get settingsBiometricOn;

  /// Biometric disabled message
  ///
  /// In en, this message translates to:
  /// **'Biometric off'**
  String get settingsBiometricOff;

  /// Cloud sync enabled message
  ///
  /// In en, this message translates to:
  /// **'Cloud sync on'**
  String get settingsCloudSyncOn;

  /// Cloud sync disabled message
  ///
  /// In en, this message translates to:
  /// **'Cloud sync off'**
  String get settingsCloudSyncOff;

  /// Language selected message
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String settingsLanguageSelected(String language);

  /// Region selected message
  ///
  /// In en, this message translates to:
  /// **'Region: {region}'**
  String settingsRegionSelected(String region);

  /// Station selected message
  ///
  /// In en, this message translates to:
  /// **'Station: {station}'**
  String settingsStationSelected(String station);

  /// Threshold selected message
  ///
  /// In en, this message translates to:
  /// **'Threshold: {threshold}'**
  String settingsThresholdSelected(String threshold);

  /// Refresh selected message
  ///
  /// In en, this message translates to:
  /// **'Refresh: {interval}'**
  String settingsRefreshSelected(String interval);

  /// Rate app thanks message
  ///
  /// In en, this message translates to:
  /// **'⭐ Thank you!'**
  String get settingsRateThanks;

  /// About dialog content
  ///
  /// In en, this message translates to:
  /// **'Air Quality Monitoring App\nVersion 1.0.0\n\nMonitoring Dar es Salaam\'s air quality\nin real time using IoT sensors and ML-powered forecasting.'**
  String get settingsAboutContent;

  /// Hazardous alert message
  ///
  /// In en, this message translates to:
  /// **'HAZARDOUS — health emergency. Stay indoors immediately.'**
  String get alertHazardous;

  /// Very unhealthy alert message
  ///
  /// In en, this message translates to:
  /// **'Very unhealthy — avoid all outdoor exposure. Use air purifiers.'**
  String get alertVeryUnhealthy;

  /// Unhealthy alert message
  ///
  /// In en, this message translates to:
  /// **'Unhealthy air — everyone should reduce outdoor activity now.'**
  String get alertUnhealthy;

  /// Sensitive alert message
  ///
  /// In en, this message translates to:
  /// **'Sensitive groups should take extra precautions outdoors.'**
  String get alertSensitive;

  /// Tips label
  ///
  /// In en, this message translates to:
  /// **'tips'**
  String get healthTips;

  /// Health screen retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get healthRetry;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Ingia'**
  String get signIn;

  /// Create account button
  ///
  /// In en, this message translates to:
  /// **'Unda Akaunti'**
  String get createAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
