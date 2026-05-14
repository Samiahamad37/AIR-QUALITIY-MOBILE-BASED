import 'package:flutter/material.dart';
import 'air_quality_data.dart';

// ─── Daily Forecast Model ─────────────────────────────────────────────────────

class DailyForecast {
  final String dayName;
  final String date;
  final int aqiMin;
  final int aqiMax;
  final int aqiAvg;
  final String condition;
  final IconData weatherIcon;
  final bool isToday;

  const DailyForecast({
    required this.dayName,
    required this.date,
    required this.aqiMin,
    required this.aqiMax,
    required this.aqiAvg,
    required this.condition,
    required this.weatherIcon,
    this.isToday = false,
  });

  AqiLevel get level => getAqiLevel(aqiAvg);
}

// ─── Hourly Forecast Model ────────────────────────────────────────────────────

class HourlyForecast {
  final String time;
  final int aqi;
  final double temperature;
  final bool isCurrent;

  const HourlyForecast({
    required this.time,
    required this.aqi,
    required this.temperature,
    this.isCurrent = false,
  });

  AqiLevel get level => getAqiLevel(aqi);
}

// ─── Insight Model ────────────────────────────────────────────────────────────

class ForecastInsight {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isPositive;

  const ForecastInsight({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isPositive,
  });
}

// ─── Mock Forecast Data ───────────────────────────────────────────────────────

List<DailyForecast> getMockDailyForecast() => const [
      DailyForecast(
        dayName: 'Today',
        date: 'May 14',
        aqiMin: 98,
        aqiMax: 168,
        aqiAvg: 142,
        condition: 'Hazy',
        weatherIcon: Icons.wb_cloudy_rounded,
        isToday: true,
      ),
      DailyForecast(
        dayName: 'Thu',
        date: 'May 15',
        aqiMin: 85,
        aqiMax: 135,
        aqiAvg: 118,
        condition: 'Moderate',
        weatherIcon: Icons.wb_cloudy_rounded,
      ),
      DailyForecast(
        dayName: 'Fri',
        date: 'May 16',
        aqiMin: 60,
        aqiMax: 105,
        aqiAvg: 90,
        condition: 'Partly Cloudy',
        weatherIcon: Icons.wb_sunny_rounded,
      ),
      DailyForecast(
        dayName: 'Sat',
        date: 'May 17',
        aqiMin: 30,
        aqiMax: 55,
        aqiAvg: 48,
        condition: 'Clear',
        weatherIcon: Icons.wb_sunny_rounded,
      ),
      DailyForecast(
        dayName: 'Sun',
        date: 'May 18',
        aqiMin: 22,
        aqiMax: 44,
        aqiAvg: 35,
        condition: 'Clear',
        weatherIcon: Icons.wb_sunny_rounded,
      ),
      DailyForecast(
        dayName: 'Mon',
        date: 'May 19',
        aqiMin: 45,
        aqiMax: 88,
        aqiAvg: 70,
        condition: 'Windy',
        weatherIcon: Icons.air_rounded,
      ),
      DailyForecast(
        dayName: 'Tue',
        date: 'May 20',
        aqiMin: 55,
        aqiMax: 110,
        aqiAvg: 95,
        condition: 'Cloudy',
        weatherIcon: Icons.cloud_rounded,
      ),
    ];

List<HourlyForecast> getMockHourlyForecast() => const [
      HourlyForecast(time: '6am',  aqi: 55,  temperature: 24.0),
      HourlyForecast(time: '8am',  aqi: 78,  temperature: 25.5),
      HourlyForecast(time: '10am', aqi: 102, temperature: 27.0),
      HourlyForecast(time: '12pm', aqi: 128, temperature: 28.5),
      HourlyForecast(time: '2pm',  aqi: 168, temperature: 29.5),
      HourlyForecast(time: 'Now',  aqi: 142, temperature: 28.5, isCurrent: true),
      HourlyForecast(time: '6pm',  aqi: 110, temperature: 27.5),
      HourlyForecast(time: '8pm',  aqi: 85,  temperature: 26.0),
      HourlyForecast(time: '10pm', aqi: 62,  temperature: 25.0),
      HourlyForecast(time: '12am', aqi: 50,  temperature: 24.0),
    ];

List<ForecastInsight> getMockInsights() => const [
      ForecastInsight(
        title: 'Best day this week',
        value: 'Sunday',
        subtitle: 'AQI drops to 35 — great for outdoor activities',
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFF4ADE80),
        isPositive: true,
      ),
      ForecastInsight(
        title: 'Peak pollution today',
        value: '2:00 PM',
        subtitle: 'AQI expected to peak at 168 — stay indoors',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFF87171),
        isPositive: false,
      ),
      ForecastInsight(
        title: 'Safe outdoor window',
        value: '6–8 AM',
        subtitle: 'Lowest pollution of the day, good for exercise',
        icon: Icons.directions_run_rounded,
        color: Color(0xFF60A5FA),
        isPositive: true,
      ),
    ];