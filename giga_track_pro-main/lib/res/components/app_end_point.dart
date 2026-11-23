class AppUrl {
  static var baseURL = 'https://track.autotel.pk/api';
  static var baseImgURL = 'https://track.autotel.pk/';
  static var loginEndPoint = '/login';
  static var getAlertListEndPoint = '/get_alert_list?user_api_hash=';
  static String deleteEp = '/delete_alert?user_api_hash=';
  static var getDevicesEndPoint = '/get_devices_list?user_api_hash=';
  static var getDeviceHistoryEndPoint = '/vehicle_history?user_api_hash=';
  static var generateReportType = '/get_reports_types?user_api_hash=';
  static var generateReports = '/generate_report?user_api_hash=';
  static var getAlertsTypeList = '/get_alerts?user_api_hash=';
  static var changeAlertValue = '/change_active_alert?user_api_hash=';
  static var fcmAlertTokenEndPoint = '/fcm_token?user_api_hash=';
  static var changePasswordEndPoint = '/change_password?user_api_hash=';
  static var getGeoFenceListEndPoint = '/get_geofences?user_api_hash=';
  static var changeGeoFenceActivationEndPoint =
      '/change_active_geofence?user_api_hash=';
  static var deleteGeoFenceEndPoint = '/destroy_geofence?user_api_hash=';
  static var getDeviceCommandsEndPoint = '/get_device_commands?user_api_hash=';
  static var sendDeviceCommandEndPoint = '/send_gprs_command?user_api_hash=';
  static String getDeviceLiveTrackingEp = "/live_tracking?user_api_hash=";
}
