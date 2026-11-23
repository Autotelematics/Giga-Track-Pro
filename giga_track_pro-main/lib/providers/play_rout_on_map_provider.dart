import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/device_history_model.dart';
import 'package:trackerapp/models/playbackrout.dart';
import 'package:trackerapp/models/track_play_rout_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_device_history_repository.dart';
import 'dart:io';

class PlayRoutOnMapViewModel with ChangeNotifier {
  final DeviceHistoryRepository _historyRepository = DeviceHistoryRepository();
  final UserLoginProvider userLoginProvider = UserLoginProvider();

  ApiResponse<DeviceHistoryModel> deviceRoutHistoryResponse = ApiResponse.loading();

  List<Marker> mapMarkers = [];
  List<LatLng> polyLatLng = [];
  final Set<Polyline> routPolyLine = {};

  List<PlayBackRoute> routeList = [];
  List<TripsRoutModel> tripsList = [];

  int sliderValueMax = 0;
  int currentSliderValue = 0;
  int tripCount = 0;
  int stopCount = 0;
  int selectedPlayBackSpeed = 0;

  List<int> playBackTimeSpeed = [800, 600, 400, 200]; // milliseconds

  String deviceName = '';
  String _errorMessage = '';

  BitmapDescriptor startIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor endIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor parkingIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor eventsIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor carIcon = BitmapDescriptor.defaultMarker;

  final String _carIconPath = "assets/images/ios/car_icon6.png";
  final String _carIconPathAndroid = "assets/images/car_icon6.png";
  final String _iconPathAndroid = 'assets/images/';
  final String _iconPathIOS = 'assets/images/ios/';

  double _intermediateDistance = 0;
  double _tripIntermediateDistance = 0;
  final List<LatLng> _parkedLatLng = [];
  final List<LatLng> _eventsLatLng = [];

  bool _isDisposed = false;

  String get errorMessage => _errorMessage;

  // ✅ GETTERS
  bool get hasData => routeList.isNotEmpty;
  int get routeLength => routeList.length;

  void _resetAllData() {
    mapMarkers.clear();
    polyLatLng.clear();
    _parkedLatLng.clear();
    _eventsLatLng.clear();
    routeList.clear();
    tripsList.clear();
    routPolyLine.clear();

    currentSliderValue = 0;
    sliderValueMax = 0;
    _intermediateDistance = 0;
    _tripIntermediateDistance = 0;
    selectedPlayBackSpeed = 0;
    tripCount = 0;
    stopCount = 0;
    deviceName = '';
    _errorMessage = '';
  }

  void setPlayBackSpeed() {
    selectedPlayBackSpeed = selectedPlayBackSpeed < 3 ? selectedPlayBackSpeed + 1 : 0;
    _notifyListeners();
  }

  void playUsingSlider(int sliderValue) {
    if (routeList.isEmpty) return;

    currentSliderValue = sliderValue.clamp(0, routeList.length - 1);
    mapMarkers.removeWhere((m) => m.markerId == const MarkerId('0'));

    final route = routeList[currentSliderValue];
    final lat = _parseDouble(route.latitude);
    final lng = _parseDouble(route.longitude);

    if (lat == null || lng == null) {
      _notifyListeners();
      return;
    }

    mapMarkers.add(
      Marker(
        markerId: const MarkerId('0'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: currentSliderValue.toString()),
        icon: carIcon,
        rotation: _parseDouble(route.course) ?? 0.0,
      ),
    );

    _notifyListeners();
  }

  void setCompleteRoutPolyLineLatLng(List<LatLng> polyLatLng) {
    routPolyLine.add(
      Polyline(
        polylineId: const PolylineId('1'),
        points: polyLatLng,
        color: Colors.deepOrange,
        width: 2,
        zIndex: 0,
      ),
    );
    _notifyListeners();
  }

  void setSingleRoutPolyLineLatLng(List<LatLng> polyLatLng) {
    routPolyLine.add(
      Polyline(
        polylineId: const PolylineId('2'),
        points: polyLatLng,
        color: Colors.green,
        width: 6,
        startCap: Cap.buttCap,
        zIndex: 1,
      ),
    );
    _notifyListeners();
  }

  void removeSingleRoutPolyLineLatLng() {
    routPolyLine.removeWhere((p) => p.polylineId.value == '2');
  }

  void resetGoogleMap() {
    _notifyListeners();
  }

  // ✅ SAFE PARSING HELPERS
  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    if (s.isEmpty || s == 'null' || s == '-') return null;
    return double.tryParse(s);
  }

  double? _getLat(Map<dynamic, dynamic> item) =>
      _parseDouble(item['latitude'] ?? item['lat']);

  double? _getLng(Map<dynamic, dynamic> item) =>
      _parseDouble(item['longitude'] ?? item['lng']);

  PlayBackRoute _buildRoute(Map<dynamic, dynamic> el, double distanceOffset) {
    return PlayBackRoute()
      ..latitude = _getLat(el)?.toString() ?? '0'
      ..longitude = _getLng(el)?.toString() ?? '0'
      ..deviceId = (el['device_id'] ?? '').toString()
      ..speed = el['speed'] ?? 0
      ..course = (el['course'] ?? 0).toString()
      ..rawTime = (el['raw_time'] ?? '').toString()
      ..time = (el['time'] ?? el['raw_time'] ?? '').toString()
      ..distance = distanceOffset.toString();
  }

  String _resolveAssetPath(String filename) {
    if (Platform.isAndroid) return '$_iconPathAndroid$filename';
    if (Platform.isIOS) return '$_iconPathIOS$filename';
    return 'assets/images/$filename';
  }

  Future<void> _preloadIcons() async {
    try {
      carIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        Platform.isAndroid ? _carIconPathAndroid : _carIconPath,
      );
      log('✅ Car icon loaded');
    } catch (e) {
      log('❌ Error loading car icon: $e');
    }

    try {
      startIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)),
        _resolveAssetPath('start.png'),
      );
      log('✅ Start icon loaded');
    } catch (e) {
      log('❌ Error loading start icon: $e');
    }

    try {
      endIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)),
        _resolveAssetPath('end.png'),
      );
      log('✅ End icon loaded');
    } catch (e) {
      log('❌ Error loading end icon: $e');
    }

    try {
      parkingIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(32, 32)),
        _resolveAssetPath('stops.png'),
      );
      log('✅ Parking icon loaded');
    } catch (e) {
      log('❌ Error loading parking icon: $e');
    }

    try {
      eventsIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(32, 32)),
        _resolveAssetPath('alert.png'),
      );
      log('✅ Events icon loaded');
    } catch (e) {
      log('❌ Error loading events icon: $e');
    }
  }

  void _setResponse(ApiResponse<DeviceHistoryModel> response) {
    deviceRoutHistoryResponse = response;
    _notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _setResponse(ApiResponse.error(msg));
  }

  void _notifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  // ✅ MAIN API CALL
  Future<void> fetchDeviceRouteHistory(
      String deviceId,
      String fromDate,
      String toDate,
      String fromTime,
      String toTime,
      ) async {
    _setResponse(ApiResponse.loading());
    _resetAllData();

    try {
      final userApiKey = await userLoginProvider.getUserApiHashString();
      final deviceHistoryDateTime =
          '&device_id=$deviceId&from_date=$fromDate&from_time=$fromTime&to_date=$toDate&to_time=$toTime';

      log('📡 Fetching route history...');

      final value = await _historyRepository.deviceHistoryApi(
        userApiKey,
        deviceHistoryDateTime,
      );

      if (_isDisposed) return;

      // Extract device name from first available item
      deviceName = 'Device';
      for (var item in value.items) {
        if (item.statusItems.isNotEmpty) {
          if (item.statusItems[0] is Map) {
            final name = item.statusItems[0]['name'] ?? 'Device';
            if (name.toString().isNotEmpty) {
              deviceName = name.toString();
              break;
            }
          }
        }
      }

      log('📍 Device: $deviceName');

      // ✅ PROCESS ALL HISTORY ITEMS
      for (var element in value.items) {
        if (element.status == 2) {
          // ✅ STOP
          _processStop(element);
        }

        if (element.status == 5 && element.statusItems.isNotEmpty) {
          // ✅ EVENT
          final lat = _getLat(element.statusItems[0] as Map<dynamic, dynamic>);
          final lng = _getLng(element.statusItems[0] as Map<dynamic, dynamic>);
          if (lat != null && lng != null) {
            _eventsLatLng.add(LatLng(lat, lng));
          }
        }

        if (element.status == 1) {
          // ✅ TRIP
          _processTrip(element);
        }

        // ✅ ADD TO COMPLETE ROUTE
        for (var el in element.statusItems) {
          if (el is! Map<dynamic, dynamic>) continue;

          final lat = _getLat(el);
          final lng = _getLng(el);
          if (lat == null || lng == null) continue;

          routeList.add(_buildRoute(el, _intermediateDistance));
          polyLatLng.add(LatLng(lat, lng));
          _intermediateDistance += _parseDouble(el['distance']) ?? 0.0;
        }
      }

      sliderValueMax = polyLatLng.isNotEmpty ? polyLatLng.length - 1 : 0;

      log('✅ Parsed: ${routeList.length} points, $tripCount trips, $stopCount stops');

      // ✅ SET INITIAL POLYLINE
      if (routeList.isNotEmpty && polyLatLng.isNotEmpty) {
        setCompleteRoutPolyLineLatLng(polyLatLng);
      }

      // ✅ PRELOAD ICONS
      await _preloadIcons();

      _setResponse(ApiResponse.complete(value));
    } catch (error) {
      log('❌ Error fetching route history: $error');
      _setError(_buildFriendlyError(error));
    }
  }

  void _processStop(HistoryItem element) {
    final tripsLatLng = <LatLng>[];
    final tripsPlayBackList = <PlayBackRoute>[];
    _tripIntermediateDistance = 0;

    final newTrip = TripsRoutModel()
      ..status = element.status
      ..totalTripDuration = element.time
      ..tripStart = element.show
      ..tripEnd = element.left
      ..distance = element.distance
      ..topSpeed = element.topSpeed
      ..avgSpeed = element.avgSpeed;

    for (var el in element.statusItems) {
      if (el is! Map<dynamic, dynamic>) continue;

      final lat = _getLat(el);
      final lng = _getLng(el);
      if (lat == null || lng == null) continue;

      tripsLatLng.add(LatLng(lat, lng));
      tripsPlayBackList.add(_buildRoute(el, _tripIntermediateDistance));
      _tripIntermediateDistance += _parseDouble(el['distance']) ?? 0.0;
    }

    newTrip.tripRoutLatLng = tripsLatLng;
    newTrip.tripPlayBackRout = tripsPlayBackList;
    tripsList.add(newTrip);
    stopCount++;

    // Add parking marker
    if (element.statusItems.isNotEmpty && element.statusItems[0] is Map) {
      final first = element.statusItems[0] as Map<dynamic, dynamic>;
      final lat = _getLat(first);
      final lng = _getLng(first);
      if (lat != null && lng != null) {
        _parkedLatLng.add(LatLng(lat, lng));
      }
    }
  }

  void _processTrip(HistoryItem element) {
    final tripsLatLng = <LatLng>[];
    final tripsPlayBackList = <PlayBackRoute>[];
    _tripIntermediateDistance = 0;

    final newTrip = TripsRoutModel()
      ..status = element.status
      ..totalTripDuration = element.time
      ..tripStart = element.show
      ..tripEnd = element.left
      ..distance = element.distance
      ..topSpeed = element.topSpeed
      ..avgSpeed = element.avgSpeed;

    for (var el in element.statusItems) {
      if (el is! Map<dynamic, dynamic>) continue;

      final lat = _getLat(el);
      final lng = _getLng(el);
      if (lat == null || lng == null) continue;

      tripsLatLng.add(LatLng(lat, lng));
      tripsPlayBackList.add(_buildRoute(el, _tripIntermediateDistance));
      _tripIntermediateDistance += _parseDouble(el['distance']) ?? 0.0;
    }

    newTrip.tripRoutLatLng = tripsLatLng;
    newTrip.tripPlayBackRout = tripsPlayBackList;
    tripsList.add(newTrip);
    tripCount++;
  }

  String _buildFriendlyError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('expired')) {
      return 'Vehicle subscription has expired.\nPlease renew to view history.';
    }
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network unreachable')) {
      return 'No internet connection.\nPlease check your network.';
    }
    if (lower.contains('timeout')) {
      return 'Request timed out.\nPlease try again.';
    }
    if (lower.contains('401') || lower.contains('unauthor')) {
      return 'Unauthorized.\nPlease log in again.';
    }
    if (lower.contains('403')) {
      return 'Access Denied.\nYou don\'t have permission for this device.';
    }
    if (lower.contains('500')) {
      return 'Server error.\nPlease try again later.';
    }

    return 'Error loading route history.\nPlease try again.';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}