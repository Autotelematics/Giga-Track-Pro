import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/get_device_live_tracking_model.dart';
import 'package:trackerapp/repository/get_device_live_tracking_repository.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/string_extensions.dart';

class VehicleTrackingProvider extends ChangeNotifier {
  final GetDeviceLiveTrackingRepository repository =
  GetDeviceLiveTrackingRepository();

  GetDeviceLiveTrackingModel? deviceData;

  Timer? _refreshTimer;
  bool isDisposed = false;
  bool isLoading = true;
  bool hasNoData = false;
  bool isExpired = false;
  String? noDataMessage;
  String? errorMessage;

  // Position data
  double deviceLat = 0.0;
  double deviceLng = 0.0;
  double deviceRotation = 0.0;
  int deviceSpeed = 0;

  // Map state
  MapType currentMapType = MapType.normal;
  bool enableTraffic = false;
  bool followVehicle = true;
  bool rulerMode = false;
  final List<LatLng> _rulerPoints = [];
  Position? _userPosition;
  bool isLocatingUser = false;
  String? locationError;
  
  DateTime? _lastNotifyTime;
  final Duration _notifyThrottle = const Duration(milliseconds: 50);
  String? _lastIconPath;
  String? _lastStatus;

  // Getters
  Item? get item => deviceData?.item;

  String get deviceName => item?.name ?? 'Unknown Vehicle';
  String get deviceId => item?.id.toString() ?? 'Unknown Vehicle';
  String get vehicleType => item?.vehicleType ?? '';
  String get status => (item?.online ?? 'offline').toLowerCase();
  double get odometer => _safeDouble(item?.odometer);
  String get totalDistance => odometer.toStringAsFixed(2);
  String get address => item?.addr ?? 'Fetching location...';
  String get lastUpdate => _formatUpdateTime(item?.time ?? '');
  List<Sensor>? get sensors => item?.sensors;

  double get latitude => deviceLat;
  double get longitude => deviceLng;
  double get rawCourse => _safeDouble(item?.course) % 360;
  double get course => deviceRotation;

  String get deviceStopDuration => item?.stopDuration?.toString() ?? '0';
  String get iconPath => item?.path ?? '';
  Position? get userPosition => _userPosition;

  String get stopStartStatus {
    if (isExpired) return 'Expired since ';
    if (status == 'online' && deviceSpeed > 5) {
      return 'Running since ';
    } else if (status == 'online' && deviceSpeed <= 5) {
      return 'Stop since ';
    } else if (status == 'engine') {
      return 'Idle since ';
    } else {
      return 'Stop since ';
    }
  }

  String get stopDurationDisplay => deviceStopDuration.formatDuration();

  Color get statusColor {
    if (isExpired) return AppColors.statusExpired;
    if (status == 'online') {
      return deviceSpeed > 5 ? AppColors.statusRunning : AppColors.statusStopped;
    } else if (status == 'engine') {
      return AppColors.statusIdle;
    } else if (status == 'ack') {
      return AppColors.statusStopped;
    } else {
      return AppColors.statusOffline;
    }
  }

  String get statusText {
    if (isExpired) return 'Expired';
    if (status == 'online') {
      return deviceSpeed > 5 ? 'Driving' : 'Stopped';
    } else if (status == 'engine') {
      return 'Idle';
    } else if (status == 'ack') {
      return 'Stopped';
    } else {
      return 'Offline';
    }
  }

  Color get ignitionColor {
    switch (status) {
      case 'online':
      case 'engine':
        return AppColors.statusRunning;
      case 'ack':
        return AppColors.statusStopped;
      default:
        return AppColors.statusIdle;
    }
  }

  String get runningOrStoppedInfoRealTime {
    if (isExpired) return 'Subscription Expired';
    return '$stopStartStatus$stopDurationDisplay';
  }

  String get vehicleStatusText {
    switch (status) {
      case 'online':
        return 'Running';
      case 'ack':
        return 'Stopped';
      case 'engine':
        return 'Idle';
      default:
        return 'Offline';
    }
  }

  String _formatUpdateTime(String timeStr) {
    if (timeStr.isEmpty) return 'Loading...';
    try {
      final parsed = DateFormat("dd-MM-yyyy hh:mm:ss a").parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(parsed);

      if (diff.inSeconds < 60) {
        return DateFormat("dd MMM yyyy, hh:mm a").format(parsed);
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return DateFormat("dd MMM yyyy, hh:mm a").format(parsed);
      }
    } catch (e) {
      return timeStr;
    }
  }

  static double _safeDouble(dynamic val, {double defaultValue = 0.0}) {
    try {
      if (val == null ||
          val.toString().trim().isEmpty ||
          val.toString() == '-' ||
          val.toString() == 'null') {
        return defaultValue;
      }
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.parse(val.toString());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing double: $val, error: $e');
      }
      return defaultValue;
    }
  }

  static int _safeInt(dynamic val, {int defaultValue = 0}) {
    try {
      if (val == null ||
          val.toString().trim().isEmpty ||
          val.toString() == '-' ||
          val.toString() == 'null') {
        return defaultValue;
      }
      if (val is int) return val;
      return int.parse(val.toString());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing int: $val, error: $e');
      }
      return defaultValue;
    }
  }

  double radians(double degrees) => degrees * pi / 180;
  double degrees(double radians) => radians * 180 / pi;

  double calculateBearing(LatLng start, LatLng end) {
    double startLat = radians(start.latitude);
    double startLng = radians(start.longitude);
    double endLat = radians(end.latitude);
    double endLng = radians(end.longitude);

    double dLng = endLng - startLng;

    double y = sin(dLng) * cos(endLat);
    double x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    double bearing = atan2(y, x);
    return (degrees(bearing) + 360) % 360;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;
    double lat1 = radians(start.latitude);
    double lng1 = radians(start.longitude);
    double lat2 = radians(end.latitude);
    double lng2 = radians(end.longitude);

    double dLat = lat2 - lat1;
    double dLng = lng2 - lng1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double? get distanceToVehicleKm {
    if (_userPosition == null || deviceLat == 0.0 || deviceLng == 0.0) {
      return null;
    }
    return _calculateDistance(
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(deviceLat, deviceLng),
    );
  }

  String get distanceToVehicleLabel {
    final km = distanceToVehicleKm;
    if (km == null) return 'Distance unavailable';
    if (km < 1) {
      return '${(km * 1000).round()} m away';
    }
    return '${km.toStringAsFixed(2)} km away';
  }

  List<LatLng> get rulerPoints => List.unmodifiable(_rulerPoints);

  double get rulerDistanceKm {
    if (_rulerPoints.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < _rulerPoints.length; i++) {
      total += _calculateDistance(_rulerPoints[i - 1], _rulerPoints[i]);
    }
    return total;
  }

  String get rulerDistanceLabel {
    if (_rulerPoints.length < 2) return 'Tap points to measure';
    final km = rulerDistanceKm;
    if (km < 1) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(2)} km';
  }

  Set<Marker> get rulerMarkers {
    if (_rulerPoints.isEmpty) return {};
    return _rulerPoints
        .asMap()
        .entries
        .map(
          (entry) => Marker(
        markerId: MarkerId('ruler_point_${entry.key}'),
        position: entry.value,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        anchor: const Offset(0.5, 1),
      ),
    )
        .toSet();
  }

  Set<Polyline> get rulerPolylines {
    if (_rulerPoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('ruler_line'),
        points: _rulerPoints,
        width: 4,
        color: AppColors.statusOffline,
      ),
    };
  }

  void _safeNotify() {
    final now = DateTime.now();
    if (_lastNotifyTime != null &&
        now.difference(_lastNotifyTime!) < _notifyThrottle) {
      return;
    }
    _lastNotifyTime = now;
    notifyListeners();
  }

  void _checkAndUpdateStatus(String newStatus) {
    if (_lastStatus != newStatus) {
      _lastStatus = newStatus;
    }
  }

  // ✅ PREVENT JUMPING: Initialize provider with dashboard data immediately
  void initWithDashboardData(double lat, double lng, double course) {
    if (lat == 0.0 || lng == 0.0) return;
    
    // Clear old data first
    deviceLat = lat;
    deviceLng = lng;
    deviceRotation = course;
    _lastStatus = null;

    // Note: We don't call notifyListeners here if called from initState
    // UI will pick it up on its first build
  }

  void resetCoordinates() {
    deviceLat = 0.0;
    deviceLng = 0.0;
    deviceRotation = 0.0;
    deviceData = null;
    _lastIconPath = null;
    _lastStatus = null;
    isLoading = true;
    hasNoData = false;
    isExpired = false;
    errorMessage = null;
  }

  void reset() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    resetCoordinates();
    notifyListeners();
  }

  Future<void> _updateDeviceData({required bool isRefresh}) async {
    if (isDisposed || deviceData?.item == null) return;

    double lat = _safeDouble(deviceData!.item!.lat);
    double lng = _safeDouble(deviceData!.item!.lng);
    double course = _safeDouble(deviceData!.item!.course);
    int speed = _safeInt(deviceData!.item!.speed);

    final currentStatus = status;
    _checkAndUpdateStatus(currentStatus);

    final newIconPath = deviceData!.item!.path ?? '';
    if (newIconPath.isNotEmpty && newIconPath != _lastIconPath) {
      _lastIconPath = newIconPath;
    }

    deviceLat = lat;
    deviceLng = lng;
    deviceRotation = course;
    deviceSpeed = speed;

    _safeNotify();
  }

  bool get mounted => !isDisposed;

  Future<void> fetchDeviceLiveTracking({
    required int deviceId,
    bool isRefresh = false,
    required BuildContext context,
  }) async {
    if (isDisposed) return;

    if (!isRefresh) {
      isLoading = true;
      errorMessage = null;
      hasNoData = false;
      isExpired = false;
      noDataMessage = null;
      _safeNotify();
    }

    try {
      final response = await _fetchLiveWithRetry(deviceId: deviceId);
      if (isDisposed) return;

      deviceData = response;

      if (deviceData?.item == null) {
        hasNoData = true;
        noDataMessage = 'No live data available for this vehicle.';
        isLoading = false;
        _safeNotify();
        return;
      }

      final liveItem = deviceData!.item!;
      final lat = _safeDouble(liveItem.lat);
      final lng = _safeDouble(liveItem.lng);
      final online = (liveItem.online ?? '').toLowerCase().trim();
      final timeStr = (liveItem.time ?? '').toLowerCase().trim();

      // ✅ VEHICLE EXPIRED CHECK
      if (online == 'expired' || timeStr.contains('expired')) {
        isExpired = true;
        errorMessage = 'Subscription Expired';
        stopPeriodicRefresh();
        isLoading = false;
        _safeNotify();
        return;
      }

      // ✅ NOT CONNECTED / NO DATA CHECK
      final noDataStatus = online == 'never_connected' ||
          (online == 'offline' && timeStr == 'not connected');

      if ((lat == 0.0 || lng == 0.0) || noDataStatus) {
        hasNoData = true;
        noDataMessage = 'This vehicle has no live location data yet.';
        isLoading = false;
        _safeNotify();
        return;
      }

      hasNoData = false;
      noDataMessage = null;
      errorMessage = null;

      await _updateDeviceData(isRefresh: isRefresh);

      isLoading = false;
      _safeNotify();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('expired')) {
        isExpired = true;
        errorMessage = 'Subscription Expired';
        stopPeriodicRefresh();
      } else {
        errorMessage = _friendlyErrorMessage(e);
      }
      isLoading = false;
      _safeNotify();
    }
  }

  Future<GetDeviceLiveTrackingModel?> _fetchLiveWithRetry({
    required int deviceId,
  }) async {
    const maxAttempts = 3;
    Object? lastError;
    for (int i = 1; i <= maxAttempts; i++) {
      try {
        final response =
        await repository.getDeviceLiveTrackingApi(deviceId: deviceId);
        if (response != null) {
          return response;
        }
      } catch (e) {
        lastError = e;
        if (e.toString().contains('Expired')) {
          rethrow;
        }
        if (!_isLikelyNetworkError(e) || i == maxAttempts) {
          rethrow;
        }
      }
      if (i < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 500 * i));
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }

  bool _isLikelyNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('network is unreachable') ||
        text.contains('timed out') ||
        text.contains('clientexception');
  }

  String _friendlyErrorMessage(Object error) {
    if (_isLikelyNetworkError(error)) {
      return 'Network connection issue. Please check internet and try again.';
    }
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }

  void startPeriodicRefresh(int deviceId, BuildContext context,
      {int intervalSeconds = 8}) {
    if (isDisposed) return;
    _refreshTimer?.cancel();
    fetchDeviceLiveTracking(
        deviceId: deviceId, context: context, isRefresh: false);
    _refreshTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (isDisposed) return;
      fetchDeviceLiveTracking(
          deviceId: deviceId, context: context, isRefresh: true);
    });
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void toggleMapType() {
    currentMapType =
    currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    notifyListeners();
  }

  void toggleTraffic() {
    enableTraffic = !enableTraffic;
    notifyListeners();
  }

  void centerOnVehicle() {
    followVehicle = true;
    notifyListeners();
  }

  void toggleFollowVehicle() {
    followVehicle = !followVehicle;
    notifyListeners();
  }

  void toggleRulerMode() {
    rulerMode = !rulerMode;
    if (rulerMode) {
      followVehicle = false;
    } else {
      _rulerPoints.clear();
    }
    notifyListeners();
  }

  void handleRulerTap(LatLng point) {
    if (!rulerMode) return;
    _rulerPoints.add(point);
    notifyListeners();
  }

  void clearRulerPoints() {
    if (_rulerPoints.isEmpty) return;
    _rulerPoints.clear();
    notifyListeners();
  }

  Future<bool> fetchUserLocation() async {
    try {
      locationError = null;
      isLocatingUser = true;
      notifyListeners();

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError = 'Location services are disabled';
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        locationError = 'Location permission denied';
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        locationError = 'Enable location permission in Settings';
        return false;
      }

      _userPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _userPosition ??= await Geolocator.getLastKnownPosition();

      if (_userPosition == null) {
        locationError = 'No GPS fix available';
        return false;
      }
      return true;
    } catch (e) {
      _userPosition = await Geolocator.getLastKnownPosition();
      if (_userPosition != null) {
        locationError = null;
        return true;
      }
      locationError = 'Unable to get current location';
      return false;
    } finally {
      isLocatingUser = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    isDisposed = true;
    stopPeriodicRefresh();
    super.dispose();
  }
}