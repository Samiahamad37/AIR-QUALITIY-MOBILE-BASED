import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/Data/air_quality_data.dart';
import '/services/api_service.dart';
import '/screens/app_theme.dart';
import '/L10n/app_localizations.dart';

class _DeviceLocation {
  final String deviceId;
  final String label;
  final LatLng position;
  Map<String, dynamic>? aqiData;

  _DeviceLocation({
    required this.deviceId,
    required this.label,
    required this.position,

  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _loading = true;
  String? _error;
  _DeviceLocation? _selected;

  final List<_DeviceLocation> _devices = [
    _DeviceLocation(
      deviceId: 'lands-building',
      label: 'Mwenge',
      position: const LatLng(-6.7690, 39.2400),
    ),
    _DeviceLocation(
      deviceId: 'planing-building',
      label: 'Planing Building',
      position: const LatLng(-6.7685, 39.2395),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      for (final device in _devices) {
        final data = await api.fetchDeviceAqi(deviceId: device.deviceId);
        device.aqiData = data;
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _aqiColor(int aqi) => getAqiLevel(aqi).color;

  int _getAqi(_DeviceLocation d) =>
      (d.aqiData?['aqi'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.appOverlayStyle,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [

            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(-6.7688, 39.2397),
                initialZoom: 16,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.air_quality_monitor',
                ),

                // Heatmap circles
                if (!_loading)
                  CircleLayer(
                    circles: _devices.map((d) {
                      final aqi = _getAqi(d);
                      return CircleMarker(
                        point: d.position,
                        radius: 60,
                        color: _aqiColor(aqi).withOpacity(0.2),
                        borderColor: _aqiColor(aqi).withOpacity(0.6),
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  ),

                // Device markers
                if (!_loading)
                  MarkerLayer(
                    markers: _devices.map((d) {
                      final aqi = _getAqi(d);
                      final color = _aqiColor(aqi);
                      final isSelected = _selected?.deviceId == d.deviceId;

                      return Marker(
                        point: d.position,
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selected = d;
                            _mapController.move(d.position, 17);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // AQI bubble
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : color.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: isSelected ? 12 : 6,
                                        spreadRadius: isSelected ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '$aqi',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Pin
                                Container(
                                  width: 2,
                                  height: 8,
                                  color: color,
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),

            // ── Top Bar ────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bg.withOpacity(0.95),
                      bg.withOpacity(0),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context).mapTitle,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary)),
                        GestureDetector(
                          onTap: _loadData,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: palette.card.withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.border),
                            ),
                            child: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.good),
                                  )
                                : Icon(Icons.refresh_rounded,
                                    size: 18,
                                    color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 90, right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.card.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).mapAqiScale,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: palette.textSecondary)),
                    const SizedBox(height: 6),
                    _legendItem(context, AppColors.good, AppLocalizations.of(context).aqiScaleGood),
                    _legendItem(context, AppColors.moderate, AppLocalizations.of(context).aqiScaleModerate),
                    _legendItem(context, AppColors.sensitiveGroups, AppLocalizations.of(context).aqiScaleSensitive),
                    _legendItem(context, AppColors.unhealthy, AppLocalizations.of(context).aqiScaleUnhealthy),
                    _legendItem(context, AppColors.veryUnhealthy, AppLocalizations.of(context).aqiScaleVeryUnhealthy),
                  ],
                ),
              ),
            ),

            // ── Bottom Sheet (selected device) ─────────────────────
            if (_selected != null)
              Positioned(
                bottom: 80, left: 16, right: 16,
                child: _DeviceCard(
                  device: _selected!,
                  onClose: () => setState(() => _selected = null),
                ),
              ),

            // ── Error ──────────────────────────────────────────────
            if (_error != null)
              Positioned(
                bottom: 100, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.unhealthy.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                    GestureDetector(
                      onTap: _loadData,
                      child: Text(AppLocalizations.of(context).mapRetry,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: context.palette.textSecondary)),
      ]),
    );
  }
}

// ─── Device Detail Card ───────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final _DeviceLocation device;
  final VoidCallback onClose;

  const _DeviceCard({required this.device, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final aqiData = device.aqiData;
    final aqi = (aqiData?['aqi'] as num?)?.toInt() ?? 0;
    final level = getAqiLevel(aqi);
    final pollutants = aqiData?['pollutants'] as Map<String, dynamic>? ?? {};
    final environment = aqiData?['environment'] as Map<String, dynamic>? ?? {};
    final category = aqiData?['category'] ?? 'unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.sensors_rounded, color: level.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary)),
                  Text(device.deviceId,
                      style: TextStyle(
                          fontSize: 11,
                          color: palette.textSecondary)),
                ],
              ),
            ),
            // AQI badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: level.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: level.color.withOpacity(0.3)),
              ),
              child: Column(children: [
                Text('$aqi',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: level.color)),
                Text(category.toString().toUpperCase(),
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: level.color)),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: palette.cardLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 16, color: palette.textSecondary),
              ),
            ),
          ]),

          const SizedBox(height: 14),
          Divider(color: palette.border.withOpacity(0.5)),
          const SizedBox(height: 10),

          // Pollutants row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('PM2.5', '${(pollutants['pm25'] as num?)?.toStringAsFixed(1) ?? '--'} µg/m³', AppColors.pm25Color),
              _stat('PM10',  '${(pollutants['pm10'] as num?)?.toStringAsFixed(1) ?? '--'} µg/m³', AppColors.pm10Color),
              _stat('NOx',   '${(pollutants['nox'] as num?)?.toStringAsFixed(2) ?? '--'} PPM',    AppColors.no2Color),
              _stat('VOC',   '${(pollutants['voc'] as num?)?.toStringAsFixed(2) ?? '--'} PPM',    AppColors.so2Color),
            ],
          ),

          // Environment row (only if available)
          if (environment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: AppColors.border.withOpacity(0.5)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Temp',     '${(environment['temperature'] as num?)?.toStringAsFixed(1) ?? '--'}°C', const Color(0xFFFB923C)),
                _stat('Humidity', '${(environment['humidity'] as num?)?.toStringAsFixed(0) ?? '--'}%',     const Color(0xFF60A5FA)),
                _stat('Pressure', '${(environment['pressure'] as num?)?.toStringAsFixed(1) ?? '--'} hPa',  const Color(0xFF34D399)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}