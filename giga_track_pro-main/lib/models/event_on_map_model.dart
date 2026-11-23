class EventOnMapDataModel {
  double? intialLat;
  double? intiallng;
  int? intialdirection;
  String? vehiclename;
  String? message;
  String? address;
  int? speed;
  String? eventtime;
  int? deviceId;

  EventOnMapDataModel({
    this.intialLat,
    this.intiallng,
    this.intialdirection,
    this.message,
    this.eventtime,
    this.speed,
    this.address,
    this.vehiclename,
    this.deviceId,
  });

  factory EventOnMapDataModel.fromNotificationData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final lat = double.tryParse(
            data['latitude']?.toString() ?? data['lat']?.toString() ?? '0') ??
        0.0;
    final lng = double.tryParse(data['longitude']?.toString() ??
            data['lng']?.toString() ??
            data['long']?.toString() ??
            '0') ??
        0.0;
    final speedVal = int.tryParse(data['speed']?.toString() ?? '0') ?? 0;
    final devId = int.tryParse(
        data['device_id']?.toString() ?? data['deviceId']?.toString() ?? '0');

    String vehicleName = data['vehicle_name']?.toString() ??
        data['device_name']?.toString() ??
        data['vehiclename']?.toString() ??
        '';

    String msgText = data['message']?.toString() ??
        body ??
        title ??
        'Alert Notification';

    if (vehicleName.isEmpty && title != null && title.isNotEmpty) {
      final parts = title.split(' ');
      if (parts.isNotEmpty) {
        vehicleName = parts.first;
      } else {
        vehicleName = title;
      }
    }
    if (vehicleName.isEmpty) vehicleName = 'Vehicle';

    final addr = data['address']?.toString() ?? 'Location details from alert';
    final timeStr = data['time']?.toString() ??
        data['event_time']?.toString() ??
        data['eventtime']?.toString() ??
        DateTime.now().toIso8601String();

    return EventOnMapDataModel(
      intialLat: lat != 0.0 ? lat : 24.945273,
      intiallng: lng != 0.0 ? lng : 67.095811,
      vehiclename: vehicleName,
      message: msgText,
      address: addr,
      speed: speedVal,
      eventtime: timeStr,
      deviceId: devId,
    );
  }
}
