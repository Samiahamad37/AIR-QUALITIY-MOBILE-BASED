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

const mapInitialPosition = LatLng(-6.7688, 39.2397);

const mapDevices = [
  MapDeviceLocation(
    deviceId: 'lands-building',
    label: 'Lands Building',
    position: LatLng(-6.7690, 39.2400),
  ),
  MapDeviceLocation(
    deviceId: 'planing-building',
    label: 'Planing Building',
    position: LatLng(-6.7720, 39.2380),
  ),
];
