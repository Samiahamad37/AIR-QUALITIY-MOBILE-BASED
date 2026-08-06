import 'package:latlong2/latlong.dart';

class MapDeviceLocation {
  final String deviceId;
  final String label;
  final LatLng position;

  const MapDeviceLocation({
    required this.deviceId,
    required this.label,
    required this.position,
  });
}

abstract class MapLayerHandle {
  void moveTo(LatLng position, double zoom);
  void dispose();
}

/// Default map center — midpoint between both sensor sites.
const mapInitialPosition = LatLng(-6.768775, 39.22032);

/// Planning building sensor (planing-building).
const mapPlanningPosition = LatLng(-6.76375, 39.21444);

/// Lands / panning area sensor (lands-building).
const mapPanningPosition = LatLng(-6.7738, 39.2262);

const mapDevices = [
  MapDeviceLocation(
    deviceId: 'lands-building',
    label: 'Lands Building',
    position: mapPanningPosition,
  ),
  MapDeviceLocation(
    deviceId: 'planing-building',
    label: 'Planing Building',
    position: mapPlanningPosition,
  ),
];
