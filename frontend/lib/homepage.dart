import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'recommendation.dart';
import 'Apidocs.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _aqiData;
  List<String> _devices = [];
  bool _loading = true;
  String _selectedDevice = 'lands-building';

  @override
  void initState() {
    super.initState();
    _loadData();

  }
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final aqi = await api.fetchDeviceAqi(deviceId: _selectedDevice);
      final devices = await api.fetchDevices();
      setState(() {
        _aqiData = aqi;
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading data: $e');
    }
  }

  Color _getAqiColor() {
    final color = _aqiData?['color'] ?? '#FFFFFF';
    return Color(int.parse(color.replaceAll('#', '0xFF')));
  }

  String _formatTimestamp(String? utc) {
    if (utc == null) return '';
    final dt = DateTime.parse(utc).toLocal();
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final aqi = _aqiData?['aqi'] ?? 0;
    final category = _aqiData?['category'] ?? 'unknown';
    final recommendations = _aqiData?['recommendations'];
    final pollutants = _aqiData?['pollutants'];
    final environment = _aqiData?['environment'];
    final timestamp = _formatTimestamp(_aqiData?['timestamp']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.air, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              "AirQuality",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          _navItem(context, "Home", true, const HomePage()),
          _navItem(context, "Health Guidance", false, const Recommendation()),
          _navItem(context, "API Docs", false, const ApiDocsPage()),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

              // ── DEVICE SELECTOR ─────────────────────────────────
              if (_devices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedDevice,
                    decoration: InputDecoration(
                      labelText: 'Select Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _devices.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDevice = val);
                        _loadData();
                      }
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // ── HERO / AQI SECTION ───────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "CITY-WIDE AIR QUALITY INDEX",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text("Loading AQI data..."),
                                ],
                              )
                            : _aqiData == null
                                ? const Text(
                                    "Failed to load data",
                                    style: TextStyle(color: Colors.red),
                                  )
                                : Column(
                                    children: [
                                      Text(
                                        "$aqi",
                                        style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.bold,
                                          color: _getAqiColor(),
                                        ),
                                      ),
                                      Text(
                                        category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: _getAqiColor(),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Updated: $timestamp",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── POLLUTANTS ───────────────────────────────────────
              if (pollutants != null)
                _infoCard(
                  title: "Pollutants",
                  icon: Icons.science_outlined,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _pollutantChip("CO2", pollutants['co2'], "PPM"),
                      _pollutantChip("NOx", pollutants['nox'], "PPM"),
                      _pollutantChip("VOC", pollutants['voc'], "PPM"),
                      _pollutantChip("PM2.5", pollutants['pm25'], "µg/m³"),
                      _pollutantChip("PM10", pollutants['pm10'], "µg/m³"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── ENVIRONMENT ──────────────────────────────────────
              if (environment != null)
                _infoCard(
                  title: "Environment",
                  icon: Icons.thermostat_outlined,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _envItem(Icons.thermostat, "${environment['temperature']}°C", "Temp"),
                      _envItem(Icons.water_drop_outlined, "${environment['humidity']}%", "Humidity"),
                      _envItem(Icons.compress, "${environment['pressure']} hPa", "Pressure"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── HEALTH RECOMMENDATIONS ───────────────────────────
              if (recommendations != null)
                _infoCard(
                  title: "Health Recommendations",
                  icon: Icons.info_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recommendations['general'] ?? ''),
                      const SizedBox(height: 8),
                      Text(recommendations['personal'] ?? ''),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pollutantChip(String label, dynamic value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value != null ? value.toString() : '--',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  static Widget _envItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  static Widget _navItem(BuildContext context, String title, bool active, Widget page) {
    return GestureDetector(
      onTap: () {
        if (!active) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.blue : Colors.grey[700],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static Widget _infoCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}