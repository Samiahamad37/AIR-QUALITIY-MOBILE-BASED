import '/L10n/app_localizations.dart';

String localizedAqiName(AppLocalizations l10n, int aqi) {
  if (aqi <= 50) return l10n.aqiGood;
  if (aqi <= 100) return l10n.aqiModerate;
  if (aqi <= 150) return l10n.aqiSensitive;
  if (aqi <= 200) return l10n.aqiUnhealthy;
  if (aqi <= 300) return l10n.aqiVeryUnhealthy;
  return l10n.aqiHazardous;
}

String localizedAqiAdvice(AppLocalizations l10n, int aqi) {
  if (aqi <= 50) return l10n.aqiAdviceGood;
  if (aqi <= 100) return l10n.aqiAdviceModerate;
  if (aqi <= 150) return l10n.aqiAdviceSensitive;
  if (aqi <= 200) return l10n.aqiAdviceUnhealthy;
  if (aqi <= 300) return l10n.aqiAdviceVery;
  return l10n.aqiAdviceHazardous;
}
