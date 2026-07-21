import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/Data/air_quality_data.dart';
import '/services/shared_data_service.dart';
import '/screens/app_theme.dart';
import '/utils/device_labels.dart';
import '/utils/time_utils.dart';
import 'package:air_quality_monitor/L10n/app_localizations.dart';
import 'map/map_models.dart';
import 'map/map_layer_stub.dart'
    if (dart.library.html) 'map/map_layer_web.dart'
    if (dart.library.io) 'map/map_layer_io.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLayerHandle? _mapHandle;
  MapDeviceLocation? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<SharedDataService>();
      if (service.deviceAqiById.isEmpty) {
        service.loadData();
      } else {
        service.loadData(background: true);
      }
    });
  }

  @override
  void dispose() {
    _mapHandle?.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<SharedDataService>().loadData(background: true);

  Color _aqiColor(int aqi) => getAqiLevel(aqi).color;

  void _selectDevice(MapDeviceLocation device) {
    setState(() => _selected = device);
    _mapHandle?.moveTo(device.position, 17);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final service = context.watch<SharedDataService>();
    final initialLoad =
        service.isLoading && service.deviceAqiById.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.appOverlayStyle,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            buildAirQualityMapLayer(
              service: service,
              initialLoad: initialLoad,
              selectedDeviceId: _selected?.deviceId,
              onSelect: _selectDevice,
              onDeselect: () => setState(() => _selected = null),
              onHandleReady: (handle) => _mapHandle = handle,
              aqiColor: _aqiColor,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).mapTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (service.lastUpdated != null)
                                Text(
                                  'Live · updated ${formatTimeAgo(service.lastUpdated!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: service.isRefreshing ? null : _refresh,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: palette.card.withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.border),
                            ),
                            child: service.isRefreshing
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.good,
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: palette.textSecondary,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 90,
              right: 16,
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
                    Text(
                      AppLocalizations.of(context).mapAqiScale,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _legendItem(
                        context, AppColors.good, AppLocalizations.of(context).aqiScaleGood),
                    _legendItem(context, AppColors.moderate,
                        AppLocalizations.of(context).aqiScaleModerate),
                    _legendItem(context, AppColors.sensitiveGroups,
                        AppLocalizations.of(context).aqiScaleSensitive),
                    _legendItem(context, AppColors.unhealthy,
                        AppLocalizations.of(context).aqiScaleUnhealthy),
                    _legendItem(context, AppColors.veryUnhealthy,
                        AppLocalizations.of(context).aqiScaleVeryUnhealthy),
                  ],
                ),
              ),
            ),
            if (_selected != null)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: _DeviceCard(
                  device: _selected!,
                  aqiData: service.aqiDataFor(_selected!.deviceId),
                  updatedAt: service.aqiUpdatedAtFor(_selected!.deviceId),
                  onClose: () => setState(() => _selected = null),
                ),
              ),
            if (service.error != null && service.deviceAqiById.isEmpty)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.unhealthy.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.error!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: _refresh,
                        child: Text(
                          AppLocalizations.of(context).mapRetry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (initialLoad)
              const Center(
                child: CircularProgressIndicator(color: AppColors.good),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontSize: 9, color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final MapDeviceLocation device;
  final Map<String, dynamic>? aqiData;
  final DateTime? updatedAt;
  final VoidCallback onClose;

  const _DeviceCard({
    required this.device,
    required this.aqiData,
    required this.updatedAt,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final aqi = (aqiData?['aqi'] as num?)?.toInt() ?? 0;
    final level = getAqiLevel(aqi);
    final pollutants = aqiData?['pollutants'] as Map<String, dynamic>? ?? {};
    final environment = aqiData?['environment'] as Map<String, dynamic>? ?? {};
    final category = aqiData?['category'] ?? level.name;

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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.sensors_rounded, color: level.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceDisplayName(device.deviceId),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      updatedAt == null
                          ? 'Live AQI'
                          : 'Updated ${formatTimeAgo(updatedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: level.color.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$aqi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: level.color,
                      ),
                    ),
                    Text(
                      category.toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: level.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.cardLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: palette.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(context, 'PM2.5',
                  '${(pollutants['pm25'] as num?)?.toStringAsFixed(1) ?? '--'} µg/m³',
                  AppColors.pm25Color),
              _stat(context, 'PM10',
                  '${(pollutants['pm10'] as num?)?.toStringAsFixed(1) ?? '--'} µg/m³',
                  AppColors.pm10Color),
              _stat(context, 'NOx',
                  '${(pollutants['nox'] as num?)?.toStringAsFixed(2) ?? '--'} PPM',
                  AppColors.no2Color),
              _stat(context, 'VOC',
                  '${(pollutants['voc'] as num?)?.toStringAsFixed(2) ?? '--'} PPM',
                  AppColors.so2Color),
            ],
          ),
          if (environment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: palette.border.withOpacity(0.5)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(
                    context,
                    'Temp',
                    '${(environment['temperature'] as num?)?.toStringAsFixed(1) ?? '--'}°C',
                    const Color(0xFFFB923C)),
                _stat(
                    context,
                    'Humidity',
                    '${(environment['humidity'] as num?)?.toStringAsFixed(0) ?? '--'}%',
                    const Color(0xFF60A5FA)),
                _stat(
                    context,
                    'Pressure',
                    '${(environment['pressure'] as num?)?.toStringAsFixed(1) ?? '--'} hPa',
                    const Color(0xFF34D399)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(
      BuildContext context, String label, String value, Color color) {
    final palette = context.palette;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: palette.textSecondary)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
