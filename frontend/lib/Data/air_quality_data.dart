import 'package:flutter/material.dart';
import '/screens/app_theme.dart';

// ─── AQI Level Model ─────────────────────────────────────────────────────────

class AqiLevel {
  final String name;
  final String shortName;
  final Color color;
  final Color bgColor;
  final Color textColor;
  final String emoji;
  final String advice;

  const AqiLevel({
    required this.name,
    required this.shortName,
    required this.color,
    required this.bgColor,
    required this.textColor,
    required this.emoji,
    required this.advice,
  });
}

AqiLevel getAqiLevel(int aqi) {
  if (aqi <= 50) {
    return const AqiLevel(
      name: 'Good',
      shortName: 'Good',
      color: AppColors.good,
      bgColor: Color(0xFF052E16),
      textColor: Color(0xFF4ADE80),
      emoji: '',
      advice: 'Air quality is satisfactory. Enjoy your day outside!',
    );
  } else if (aqi <= 100) {
    return const AqiLevel(
      name: 'Moderate',
      shortName: 'Moderate',
      color: AppColors.moderate,
      bgColor: Color(0xFF422006),
      textColor: Color(0xFFFACC15),
      emoji: '',
      advice: 'Acceptable quality. Sensitive individuals should limit exertion.',
    );
  } else if (aqi <= 150) {
    return const AqiLevel(
      name: 'Unhealthy for Sensitive Groups',
      shortName: 'Sensitive Groups',
      color: AppColors.sensitiveGroups,
      bgColor: Color(0xFF431407),
      textColor: Color(0xFFFB923C),
      emoji: '',
      advice: 'Sensitive groups should reduce outdoor activities.',
    );
  } else if (aqi <= 200) {
    return const AqiLevel(
      name: 'Unhealthy',
      shortName: 'Unhealthy',
      color: AppColors.unhealthy,
      bgColor: Color(0xFF450A0A),
      textColor: Color(0xFFF87171),
      emoji: '',
      advice: 'Everyone should reduce prolonged outdoor exertion.',
    );
  } else if (aqi <= 300) {
    return const AqiLevel(
      name: 'Very Unhealthy',
      shortName: 'Very Unhealthy',
      color: AppColors.veryUnhealthy,
      bgColor: Color(0xFF2E1065),
      textColor: Color(0xFFC084FC),
      emoji: '',
      advice: 'Health alert! Everyone should avoid outdoor activity.',
    );
  } else {
    return const AqiLevel(
      name: 'Hazardous',
      shortName: 'Hazardous',
      color: AppColors.hazardous,
      bgColor: Color(0xFF4C0519),
      textColor: Color(0xFFFB7185),
      emoji: '',
      advice: 'Emergency conditions. Stay indoors immediately.',
    );
  }
}

// ─── Pollutant Model ──────────────────────────────────────────────────────────

class Pollutant {
  final String name;
  final String unit;
  final double value;
  final double maxSafe;
  final Color color;

  const Pollutant({
    required this.name,
    required this.unit,
    required this.value,
    required this.maxSafe,
    required this.color,
  });

  double get ratio =>
      maxSafe > 0 ? (value / maxSafe).clamp(0.0, 1.0) : 0.0;
}

// ─── Hourly AQI Data ──────────────────────────────────────────────────────────

class HourlyAqi {
  final String hour;
  final int aqi;
  final bool isCurrent;

  const HourlyAqi({
    required this.hour,
    required this.aqi,
    this.isCurrent = false,
  });
}

// ─── Air Quality Data Model ───────────────────────────────────────────────────

class AirQualityData {
  final int aqi;
  final String city;
  final String district;
  final DateTime updatedAt;
  final List<Pollutant> pollutants;
  final List<HourlyAqi> hourlyData;
  final double temperature;
  final double humidity;
  final double windSpeed;

  const AirQualityData({
    required this.aqi,
    required this.city,
    required this.district,
    required this.updatedAt,
    required this.pollutants,
    required this.hourlyData,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
  });

  AqiLevel get level => getAqiLevel(aqi);
}

// ─── Mock Data (replace with API calls) ──────────────────────────────────────

// AirQualityData getMockAirQualityData() {
//   return AirQualityData(
//     aqi: 142,
//     city: 'Dar es Salaam',
//     district: 'Kinondoni',
//     updatedAt: DateTime.now(),
//     temperature: 28.5,
//     humidity: 72,
//     windSpeed: 12.3,
//     pollutants: const [
//       Pollutant(name: 'PM2.5', unit: 'µg/m³', value: 52, maxSafe: 80, color: AppColors.pm25Color),
//       Pollutant(name: 'PM10',  unit: 'µg/m³', value: 88, maxSafe: 160, color: AppColors.pm10Color),
//       Pollutant(name: 'O₃',   unit: 'ppb',   value: 34, maxSafe: 120, color: AppColors.o3Color),
//       Pollutant(name: 'NO₂',  unit: 'ppb',   value: 24, maxSafe: 80,  color: AppColors.no2Color),
//       Pollutant(name: 'SO₂',  unit: 'ppb',   value: 8,  maxSafe: 75,  color: AppColors.so2Color),
//       Pollutant(name: 'CO',   unit: 'ppm',   value: 1.2, maxSafe: 9,  color: AppColors.coColor),
//     ],
//     hourlyData: const [
//       HourlyAqi(hour: '6am',  aqi: 55),
//       HourlyAqi(hour: '8am',  aqi: 78),
//       HourlyAqi(hour: '10am', aqi: 102),
//       HourlyAqi(hour: '12pm', aqi: 128),
//       HourlyAqi(hour: '2pm',  aqi: 168),
//       HourlyAqi(hour: 'Now',  aqi: 142, isCurrent: true),
//       HourlyAqi(hour: '6pm',  aqi: 110),
//       HourlyAqi(hour: '8pm',  aqi: 85),
//       HourlyAqi(hour: '10pm', aqi: 62),
//     ],
//   );
// }