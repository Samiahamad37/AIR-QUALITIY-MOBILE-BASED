import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/services/shared_data_service.dart';
import 'map_models.dart';

class _OsmMapLayerHandle implements MapLayerHandle {
  MapController? _controller;

  void bind(MapController controller) => _controller = controller;

  @override
  void moveTo(LatLng position, double zoom) {
    _controller?.move(position, zoom);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}

Widget buildAirQualityMapLayer({
  required SharedDataService service,
  required bool initialLoad,
  required String? selectedDeviceId,
  required ValueChanged<MapDeviceLocation> onSelect,
  required VoidCallback onDeselect,
  required ValueChanged<MapLayerHandle> onHandleReady,
  required Color Function(int aqi) aqiColor,
}) {
  return _OsmMapLayer(
    service: service,
    initialLoad: initialLoad,
    selectedDeviceId: selectedDeviceId,
    onSelect: onSelect,
    onDeselect: onDeselect,
    onHandleReady: onHandleReady,
    aqiColor: aqiColor,
  );
}

class _OsmMapLayer extends StatefulWidget {
  final SharedDataService service;
  final bool initialLoad;
  final String? selectedDeviceId;
  final ValueChanged<MapDeviceLocation> onSelect;
  final VoidCallback onDeselect;
  final ValueChanged<MapLayerHandle> onHandleReady;
  final Color Function(int aqi) aqiColor;

  const _OsmMapLayer({
    required this.service,
    required this.initialLoad,
    required this.selectedDeviceId,
    required this.onSelect,
    required this.onDeselect,
    required this.onHandleReady,
    required this.aqiColor,
  });

  @override
  State<_OsmMapLayer> createState() => _OsmMapLayerState();
}

class _OsmMapLayerState extends State<_OsmMapLayer> {
  final MapController _mapController = MapController();
  final _OsmMapLayerHandle _handle = _OsmMapLayerHandle();

  @override
  void initState() {
    super.initState();
    _handle.bind(_mapController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHandleReady(_handle);
    });
  }

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  List<CircleMarker> _buildCircles() {
    return mapDevices.map((d) {
      final aqi = widget.service.aqiForDevice(d.deviceId);
      final color = widget.aqiColor(aqi);
      return CircleMarker(
        point: d.position,
        radius: 60,
        color: color.withOpacity(0.2),
        borderColor: color.withOpacity(0.6),
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    return mapDevices.map((d) {
      final aqi = widget.service.aqiForDevice(d.deviceId);
      final color = widget.aqiColor(aqi);
      final isSelected = widget.selectedDeviceId == d.deviceId;
      return Marker(
        point: d.position,
        width: isSelected ? 44 : 36,
        height: isSelected ? 44 : 36,
        child: GestureDetector(
          onTap: () => widget.onSelect(d),
          child: Icon(
            Icons.location_on_rounded,
            color: color,
            size: isSelected ? 44 : 36,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapInitialPosition,
        initialZoom: 16,
        minZoom: 12,
        maxZoom: 18,
        onTap: (_, __) => widget.onDeselect(),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.frontend',
        ),
        if (!widget.initialLoad) CircleLayer(circles: _buildCircles()),
        if (!widget.initialLoad) MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }
}
