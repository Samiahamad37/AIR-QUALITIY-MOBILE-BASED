import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'air_quality_data.dart';
import 'app_theme.dart';
import 'common_widget.dart';
import 'api_service.dart';

const String defaultDevice = 'lands-building';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AirQualityData? _data;
  bool _isRefreshing = false;
  bool _isLoading = true;
  String _selectedDevice = defaultDevice;
  List<String> _devices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      final aqiData = await api.fetchDeviceAqi(deviceId: _selectedDevice);
      final devices = await api.fetchDevices();
      final readings = await api.fetchDeviceReadings(deviceId: _selectedDevice, hours: 24);

      final pollutants = aqiData['pollutants'] as Map<String, dynamic>? ?? {};
      final environment = aqiData['environment'] as Map<String, dynamic>? ?? {};
      final hourlyData = _buildHourlyData(readings);

      setState(() {
        _devices = devices;
        _data = AirQualityData(
          aqi: (aqiData['aqi'] as num?)?.toInt() ?? 0,
          city: 'Dar es Salaam',
          district: _selectedDevice,
          updatedAt: DateTime.parse(aqiData['timestamp']).toLocal(),
          temperature: (environment['temperature'] as num?)?.toDouble() ?? 0,
          humidity: (environment['humidity'] as num?)?.toDouble() ?? 0,
          windSpeed: 0,
          pollutants: [
            Pollutant(
              name: 'PM2.5', unit: 'µg/m³',
              value: (pollutants['pm25'] as num?)?.toDouble() ?? 0,
              maxSafe: 35, color: AppColors.pm25Color,
            ),
            Pollutant(
              name: 'PM10', unit: 'µg/m³',
              value: (pollutants['pm10'] as num?)?.toDouble() ?? 0,
              maxSafe: 150, color: AppColors.pm10Color,
            ),
            Pollutant(
              name: 'CO2', unit: 'PPM',
              value: (pollutants['co2'] as num?)?.toDouble() ?? 0,
              maxSafe: 1000, color: AppColors.o3Color,
            ),
            Pollutant(
              name: 'NOx', unit: 'PPM',
              value: (pollutants['nox'] as num?)?.toDouble() ?? 0,
              maxSafe: 0.1, color: AppColors.no2Color,
            ),
            Pollutant(
              name: 'VOC', unit: 'PPM',
              value: (pollutants['voc'] as num?)?.toDouble() ?? 0,
              maxSafe: 1.0, color: AppColors.so2Color,
            ),
          ],
          hourlyData: hourlyData,
        );
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  List<HourlyAqi> _buildHourlyData(List<Map<String, dynamic>> readings) {
    if (readings.isEmpty) return [];
    final sorted = readings.reversed.toList();
    return sorted.take(9).map((r) {
      final ts = DateTime.parse(r['timestamp'].toString()).toLocal();
      final hour = DateFormat('ha').format(ts).toLowerCase();
      final pm25 = (r['pm25'] as num?)?.toDouble() ?? 0;
      final pm10 = (r['pm10'] as num?)?.toDouble() ?? 0;
      final nox = (r['nox'] as num?)?.toDouble() ?? 0;
      final aqi = _quickAqi(pm25, pm10, nox);
      return HourlyAqi(hour: hour, aqi: aqi);
    }).toList();
  }

  int _quickAqi(double pm25, double pm10, double nox) {
    int a = (pm25 / 35 * 100).round().clamp(0, 500);
    int b = (pm10 / 150 * 100).round().clamp(0, 500);
    int c = (nox / 0.1 * 100).round().clamp(0, 500);
    return [a, b, c].reduce((x, y) => x > y ? x : y);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _data == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(_error ?? 'No data',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final level = data.level;
    final maxHourlyAqi = data.hourlyData.isEmpty
        ? 1
        : data.hourlyData.map((h) => h.aqi).reduce((a, b) => a > b ? a : b);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: level.color,
          backgroundColor: AppColors.bgCard,
          child: CustomScrollView(
            slivers: [

              // ─── Hero Header ─────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHero(data, level)),

              // ─── Device Selector ──────────────────────────────────────
              if (_devices.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDevice,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.bgCard,
                      ),
                      items: _devices
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d,
                                    style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDevice = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),

              // ─── Metrics Strip ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      MetricChip(
                        icon: Icons.thermostat_rounded,
                        value: '${data.temperature.toStringAsFixed(1)}°C',
                        label: 'Temperature',
                        color: const Color(0xFFFB923C),
                      ),
                      const SizedBox(width: 8),
                      MetricChip(
                        icon: Icons.water_drop_rounded,
                        value: '${data.humidity.round()}%',
                        label: 'Humidity',
                        color: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 8),
                      MetricChip(
                        icon: Icons.co2_rounded,
                        value: '${data.pollutants[2].value.round()} PPM',
                        label: 'CO2',
                        color: const Color(0xFF34D399),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Today's AQI Trend ────────────────────────────────────
              if (data.hourlyData.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(title: "Today's AQI Trend"),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: SizedBox(
                        height: 110,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: data.hourlyData.asMap().entries.map((e) {
                            return HourlyChartBar(
                              data: e.value,
                              maxAqi: maxHourlyAqi,
                              delayMs: e.key * 60,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // ─── Pollutants Breakdown ─────────────────────────────────
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Pollutant Breakdown'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    child: Column(
                      children: data.pollutants.asMap().entries.map((e) {
                        return PollutantBar(
                          pollutant: e.value,
                          delayMs: e.key * 80,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // ─── Health Advisory ──────────────────────────────────────
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Health Advisory'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: level.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: level.color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: level.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.health_and_safety_rounded,
                                color: level.color, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(level.shortName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: level.textColor,
                                  )),
                              const SizedBox(height: 3),
                              Text(level.advice,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: level.textColor.withOpacity(0.8),
                                    height: 1.4,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AirQualityData data, AqiLevel level) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: level.color),
                          const SizedBox(width: 4),
                          const Text('Your Location',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Dar es Salaam',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(data.district,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      if (_isRefreshing)
                        SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: level.color),
                        )
                      else
                        GestureDetector(
                          onTap: _loadData,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.bgCardLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                size: 18, color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            AqiRing(aqi: data.aqi, size: 190),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: level.color.withOpacity(0.3)),
              ),
              child: Text(level.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: level.color)),
            ),

            const SizedBox(height: 6),
            Text('Updated ${_timeAgo(data.updatedAt)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  _quickStat('PM2.5',
                      '${data.pollutants[0].value.round()} µg/m³',
                      AppColors.pm25Color),
                  _divider(),
                  _quickStat('PM10',
                      '${data.pollutants[1].value.round()} µg/m³',
                      AppColors.pm10Color),
                  _divider(),
                  _quickStat('NOx',
                      '${data.pollutants[3].value.toStringAsFixed(2)} PPM',
                      AppColors.no2Color),
                  _divider(),
                  _quickStat('VOC',
                      '${data.pollutants[4].value.toStringAsFixed(2)} PPM',
                      AppColors.so2Color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 28, color: AppColors.border.withOpacity(0.5));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}