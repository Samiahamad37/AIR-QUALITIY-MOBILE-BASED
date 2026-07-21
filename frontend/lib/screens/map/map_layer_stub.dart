import 'package:flutter/material.dart';
import 'map_models.dart';
import '/services/shared_data_service.dart';

/// Fallback if neither web nor IO platform is detected.
Widget buildAirQualityMapLayer({
  required SharedDataService service,
  required bool initialLoad,
  required String? selectedDeviceId,
  required ValueChanged<MapDeviceLocation> onSelect,
  required VoidCallback onDeselect,
  required ValueChanged<MapLayerHandle> onHandleReady,
  required Color Function(int aqi) aqiColor,
}) {
  throw UnsupportedError('Map is not supported on this platform.');
}
