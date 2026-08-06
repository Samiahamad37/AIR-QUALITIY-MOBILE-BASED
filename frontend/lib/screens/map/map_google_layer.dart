import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import '/services/shared_data_service.dart';
import 'map_models.dart';

class _GoogleMapLayerHandle implements MapLayerHandle {
  gmaps.GoogleMapController? _controller;

  void bind(gmaps.GoogleMapController controller) => _controller = controller;

  @override
  void moveTo(LatLng position, double zoom) {
    _controller?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        gmaps.LatLng(position.latitude, position.longitude),
        zoom,
      ),
    );
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
  return _GoogleMapLayer(
    service: service,
    initialLoad: initialLoad,
    selectedDeviceId: selectedDeviceId,
    onSelect: onSelect,
    onDeselect: onDeselect,
    onHandleReady: onHandleReady,
    aqiColor: aqiColor,
  );
}

class _GoogleMapLayer extends StatefulWidget {
  final SharedDataService service;
  final bool initialLoad;
  final String? selectedDeviceId;
  final ValueChanged<MapDeviceLocation> onSelect;
  final VoidCallback onDeselect;
  final ValueChanged<MapLayerHandle> onHandleReady;
  final Color Function(int aqi) aqiColor;

  const _GoogleMapLayer({
    required this.service,
    required this.initialLoad,
    required this.selectedDeviceId,
    required this.onSelect,
    required this.onDeselect,
    required this.onHandleReady,
    required this.aqiColor,
  });

  @override
  State<_GoogleMapLayer> createState() => _GoogleMapLayerState();
}

class _GoogleMapLayerState extends State<_GoogleMapLayer> {
  final _GoogleMapLayerHandle _handle = _GoogleMapLayerHandle();

  double _markerHue(int aqi) {
    if (aqi <= 50) return gmaps.BitmapDescriptor.hueGreen;
    if (aqi <= 100) return gmaps.BitmapDescriptor.hueYellow;
    if (aqi <= 150) return gmaps.BitmapDescriptor.hueOrange;
    if (aqi <= 200) return gmaps.BitmapDescriptor.hueRed;
    return gmaps.BitmapDescriptor.hueViolet;
  }

  gmaps.BitmapDescriptor _markerIcon(int aqi) {
    // defaultMarkerWithHue is not supported on web.
    if (kIsWeb) {
      return gmaps.BitmapDescriptor.defaultMarker;
    }
    return gmaps.BitmapDescriptor.defaultMarkerWithHue(_markerHue(aqi));
  }

  Set<gmaps.Circle> _buildCircles() {
    return mapDevices.map((d) {
      final aqi = widget.service.aqiForDevice(d.deviceId);
      final color = widget.aqiColor(aqi);
      return gmaps.Circle(
        circleId: gmaps.CircleId('${d.deviceId}-halo'),
        center: gmaps.LatLng(d.position.latitude, d.position.longitude),
        radius: 60,
        fillColor: color.withOpacity(0.2),
        strokeColor: color.withOpacity(0.6),
        strokeWidth: 2,
      );
    }).toSet();
  }

  Set<gmaps.Marker> _buildMarkers() {
    return mapDevices.map((d) {
      final aqi = widget.service.aqiForDevice(d.deviceId);
      final isSelected = widget.selectedDeviceId == d.deviceId;
      return gmaps.Marker(
        markerId: gmaps.MarkerId(d.deviceId),
        position: gmaps.LatLng(d.position.latitude, d.position.longitude),
        zIndexInt: isSelected ? 2 : 1,
        icon: _markerIcon(aqi),
        infoWindow: gmaps.InfoWindow(
          title: d.label,
          snippet: 'AQI $aqi',
        ),
        onTap: () => widget.onSelect(d),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        return gmaps.GoogleMap(
          key: const ValueKey('airwatch-google-map'),
          initialCameraPosition: gmaps.CameraPosition(
            target: gmaps.LatLng(
              mapInitialPosition.latitude,
              mapInitialPosition.longitude,
            ),
            zoom: 16,
          ),
          onMapCreated: (controller) {
            _handle.bind(controller);
            widget.onHandleReady(_handle);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.animateCamera(
                gmaps.CameraUpdate.newLatLngZoom(
                  gmaps.LatLng(
                    mapInitialPosition.latitude,
                    mapInitialPosition.longitude,
                  ),
                  16,
                ),
              );
            });
          },
          onTap: (_) => widget.onDeselect(),
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          liteModeEnabled: false,
          circles: widget.initialLoad ? {} : _buildCircles(),
          markers: widget.initialLoad ? {} : _buildMarkers(),
        );
      },
    );
  }
}
