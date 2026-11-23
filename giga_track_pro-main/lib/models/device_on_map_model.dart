import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

class DeviceOnMapInitialData {
  int? groupID;
  int? itemID;
  double? initialLat;
  double? initialLng;
  double? initialDirection;
  int? deviceId;
  BitmapDescriptor? markerImage;
  DeviceOnMapInitialData(
      {this.groupID,
      this.itemID,
      this.initialLat,
      this.initialLng,
      this.initialDirection,
      this.deviceId,
      this.markerImage});
}
