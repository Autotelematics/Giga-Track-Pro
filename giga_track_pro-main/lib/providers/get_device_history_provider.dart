import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/device_history_model.dart';
import 'package:trackerapp/models/playbackrout.dart';
import 'package:trackerapp/models/track_play_rout_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_device_history_repository.dart';
import 'dart:io';

class HistoryPlayRoutOnMapProvider with ChangeNotifier {
  final DeviceHistoryRepository _historyRepository = DeviceHistoryRepository();
  final UserLoginProvider userLoginProvider = UserLoginProvider();
  ApiResponse<DeviceHistoryModel> deviceRoutHistoryResponse =
  ApiResponse.loading();
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
  List<int> playBackTimeSpeed = [2000, 1200, 700, 350];

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
  String get errorMessage => _errorMessage;

  void _resetAllData() {
    if (kDebugMode) {
      print('🔁 _resetAllData: Resetting all data');
    }
    mapMarkers.clear();
    polyLatLng.clear();
    _parkedLatLng.clear();
    _eventsLatLng.clear();
    routeList.clear();
    tripsList.clear();

    currentSliderValue = 0;
    sliderValueMax = 0;
    _intermediateDistance = 0;
    _tripIntermediateDistance = 0;
    selectedPlayBackSpeed = 0;
    tripCount = 0;
    stopCount = 0;
    deviceName = '';
    _errorMessage = '';
    routPolyLine.clear();
    if (kDebugMode) {
      print('🔁 _resetAllData: Reset complete');
    }
  }

  void setPlayBackSpeed() {
    selectedPlayBackSpeed = selectedPlayBackSpeed < 3 ? selectedPlayBackSpeed + 1 : 0;
    _notifyListeners();
  }

  void playUsingSlider(int sliderValue) {
    if (routeList.isEmpty) return;
    currentSliderValue = sliderValue.clamp(0, routeList.length - 1);
    mapMarkers.removeWhere((m) => m.markerId == const MarkerId('0'));

    final lat = _parseDouble(routeList[currentSliderValue].latitude);
    final lng = _parseDouble(routeList[currentSliderValue].longitude);

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
        rotation: _parseDouble(routeList[currentSliderValue].course) ?? 0.0,
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

  void applyMarkersOnMap() {
    if (routeList.isEmpty) return;
    mapMarkers.clear();

    // Car marker
    final carLat = _parseDouble(routeList[0].latitude);
    final carLng = _parseDouble(routeList[0].longitude);
    if (carLat != null && carLng != null) {
      mapMarkers.add(
        Marker(
          markerId: const MarkerId('0'),
          anchor: const Offset(0.5, 0.5),
          position: LatLng(carLat, carLng),
          rotation: _parseDouble(routeList[0].course) ?? 0.0,
          draggable: true,
          icon: carIcon,
          infoWindow: const InfoWindow(title: 'Car'),
        ),
      );
    }

    // Start marker
    final firstLat = _parseDouble(routeList.first.latitude);
    final firstLng = _parseDouble(routeList.first.longitude);
    if (firstLat != null && firstLng != null) {
      mapMarkers.add(
        Marker(
          markerId: MarkerId((routeList.length + 2).toString()),
          anchor: const Offset(0.5, 0.5),
          position: LatLng(firstLat, firstLng),
          draggable: true,
          icon: startIcon,
        ),
      );
    }

    // End marker
    final lastLat = _parseDouble(routeList.last.latitude);
    final lastLng = _parseDouble(routeList.last.longitude);
    if (lastLat != null && lastLng != null) {
      mapMarkers.add(
        Marker(
          markerId: MarkerId((routeList.length + 3).toString()),
          anchor: const Offset(0.5, 0.5),
          position: LatLng(lastLat, lastLng),
          draggable: true,
          icon: endIcon,
        ),
      );
    }

    // Parking markers (sirf ye rakhe hain)
    for (var element in _parkedLatLng) {
      mapMarkers.add(
        Marker(
          markerId: MarkerId(('Parking ${element.latitude}').toString()),
          anchor: const Offset(0.5, 0.5),
          position: element,
          draggable: true,
          icon: parkingIcon,
        ),
      );
    }

    // Events / Alert markers → Completely ignored (removed)
    // int i = 0;
    // for (var element in _eventsLatLng) { ... }  ← Yeh block delete kar diya hai

    _notifyListeners();
  }

  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return double.tryParse(s);
  }

  double? _getLat(Map<dynamic, dynamic> item) =>
      _parseDouble(item['latitude'] ?? item['lat']);

  double? _getLng(Map<dynamic, dynamic> item) =>
      _parseDouble(item['longitude'] ?? item['lng']);

  PlayBackRoute _buildRoute(Map<dynamic, dynamic> el, double distanceOffset) {
    return PlayBackRoute()
      ..latitude = _getLat(el)?.toString()
      ..longitude = _getLng(el)?.toString()
      ..deviceId = (el['device_id'] ?? '').toString()
      ..speed = el['speed']
      ..course = (el['course'] ?? 0).toString()
      ..rawTime = (el['raw_time'] ?? '').toString()
      ..time = (el['time'] ?? el['raw_time'] ?? '').toString()
      ..distance = distanceOffset.toString();
  }

  void _safeParseRawTime(dynamic rawTime) {
    if (rawTime == null) return;
  }

  String _resolveAssetPath(String filename) {
    if (Platform.isAndroid) {
      return '$_iconPathAndroid$filename';
    } else if (Platform.isIOS) {
      return '$_iconPathIOS$filename';
    }
    return 'assets/images/$filename';
  }

  Future<void> _preloadIcons() async {
    if (kDebugMode) {
      print('🖼️ _preloadIcons: Starting icon preloading');
    }

    try {
      carIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        Platform.isAndroid ? _carIconPathAndroid : _carIconPath,
      );
    } catch (e) {
      carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    try {
      startIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        _resolveAssetPath('start.png'),
      );
    } catch (e) {
      startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    try {
      endIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(40, 40)),
        _resolveAssetPath('end.png'),
      );
    } catch (e) {
      endIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    try {
      parkingIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(32, 32)),
        _resolveAssetPath('stops.png'),
      );
    } catch (e) {
      parkingIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }

    // Events icon ko load nahi kar rahe kyunki markers show nahi kar rahe
    eventsIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

    if (kDebugMode) {
      print('🖼️ _preloadIcons: Completed');
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
    notifyListeners();
  }

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

      log('📡 Fetching route history: $deviceHistoryDateTime');

      final value = await _historyRepository.deviceHistoryApi(
        userApiKey,
        deviceHistoryDateTime,
      );

      deviceName = '';
      for (var item in value.items) {
        if (item.status == 3 && item.statusItems.isNotEmpty) {
          deviceName = (item.statusItems[0]['name'] ?? '').toString();
          break;
        }
      }

      for (var element in value.items) {
        if (element.status == 2) {
          _processStop(element);
        }
        if (element.status == 5 && element.statusItems.isNotEmpty) {
          final lat = _getLat(element.statusItems[0]);
          final lng = _getLng(element.statusItems[0]);
          if (lat != null && lng != null) {
            _eventsLatLng.add(LatLng(lat, lng));   // Data store to raha hai (agar future mein chahiye)
          }
        }
        if (element.status == 1) {
          _processTrip(element);
        }

        // ✅ FIX: Don't add status 5 (Events) to the polyline to avoid jumps
        // Events usually contain out-of-order coordinates that create lines across the map.
        if (element.status != 5) {
          for (var el in element.statusItems) {
            final lat = _getLat(el);
            final lng = _getLng(el);
            if (lat == null || lng == null) continue;

            routeList.add(_buildRoute(el, _intermediateDistance));
            polyLatLng.add(LatLng(lat, lng));
            _safeParseRawTime(el['raw_time']);
            _intermediateDistance += _parseDouble(el['distance']) ?? 0.0;
          }
        }
      }

      sliderValueMax = polyLatLng.isNotEmpty ? polyLatLng.length - 1 : 0;

      if (routeList.isNotEmpty) {
        setCompleteRoutPolyLineLatLng(polyLatLng);
      }

      await _preloadIcons();
      _setResponse(ApiResponse.complete(value));

      log('✅ Route history loaded: ${routeList.length} points');
    } catch (error) {
      log('❌ Error fetching route history: $error');
      // 🔥 Don't set error response if it's an "Expired" message to keep UI clean
      if (error.toString().toLowerCase().contains('expired')) {
        _setResponse(ApiResponse.error('Subscription Expired'));
      } else {
        _setError(_buildFriendlyError(error));
      }
    }
  }

  // _processStop, _processTrip, _buildFriendlyError, _contextMessage same rakhe hain
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
      final lat = _getLat(el);
      final lng = _getLng(el);
      if (lat == null || lng == null) continue;

      tripsLatLng.add(LatLng(lat, lng));
      tripsPlayBackList.add(_buildRoute(el, _tripIntermediateDistance));
      _safeParseRawTime(el['raw_time']);
      _tripIntermediateDistance += _parseDouble(el['distance']) ?? 0.0;
    }

    newTrip.tripRoutLatLng = tripsLatLng;
    newTrip.tripPlayBackRout = tripsPlayBackList;
    tripsList.add(newTrip);
    stopCount++;

    if (element.statusItems.isNotEmpty) {
      final lat = _getLat(element.statusItems[0]);
      final lng = _getLng(element.statusItems[0]);
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
      final lat = _getLat(el);
      final lng = _getLng(el);
      if (lat == null || lng == null) continue;

      tripsLatLng.add(LatLng(lat, lng));
      tripsPlayBackList.add(_buildRoute(el, _tripIntermediateDistance));
      _safeParseRawTime(el['raw_time']);
      _tripIntermediateDistance += _parseDouble(el['distance']) ?? 0.0;
    }

    newTrip.tripRoutLatLng = tripsLatLng;
    newTrip.tripPlayBackRout = tripsPlayBackList;
    tripsList.add(newTrip);
    tripCount++;
  }

  String _buildFriendlyError(Object error) {
    final raw = error.toString();
    final jsonStart = raw.indexOf('{');
    if (jsonStart != -1) {
      try {
        final body = jsonDecode(raw.substring(jsonStart)) as Map<String, dynamic>;
        final apiMessage = (body['message'] ?? '').toString().trim();
        final statusCode = (body['statusCode'] ?? body['status'] ?? '').toString();
        final errors = body['errors'];

        if (apiMessage.isNotEmpty) {
          return _contextMessage(apiMessage, statusCode, errors);
        }
      } catch (_) {}
    }

    final lower = raw.toLowerCase();
    if (lower.contains('expired')) return _contextMessage('Expired', '400', null);
    if (lower.contains('socketexception') || lower.contains('failed host lookup') || lower.contains('network unreachable')) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    if (lower.contains('timeout')) return 'Request timed out.\nPlease try again.';
    if (lower.contains('formatexception') || lower.contains('jsonunsupportedobject')) {
      return 'Unexpected server response.\nPlease try again later.';
    }
    if (lower.contains('401') || lower.contains('unauthori')) {
      return 'Unauthorized [401]\nPlease log out and log in again.';
    }
    if (lower.contains('403')) {
      return 'Access Denied [403]\nYou do not have permission to view this device\'s data.';
    }
    if (lower.contains('500')) {
      return 'Server Error [500]\nPlease try again later.';
    }

    return 'Something went wrong.\n\n$raw';
  }

  String _contextMessage(String apiMessage, String statusCode, dynamic errors) {
    final lower = apiMessage.toLowerCase();
    final code = statusCode.isNotEmpty ? ' [$statusCode]' : '';
    final errDetail = errors != null ? '\nErrors: $errors' : '';

    if (lower == 'expired' || lower.contains('expir')) {
      return 'Vehicle Subscription Expired$code\n\n'
          'Server: "$apiMessage"$errDetail\n\n'
          'This vehicle\'s GPS tracking subscription has expired. '
          'History cannot be loaded until the subscription is renewed.';
    }
    if (lower.contains('unauthori') || statusCode == '401') {
      return 'Unauthorized$code\n\n'
          'Server: "$apiMessage"\n\n'
          'Please log out and log in again.';
    }
    if (lower.contains('forbidden') || statusCode == '403') {
      return 'Access Denied$code\n\n'
          'Server: "$apiMessage"\n\n'
          'You do not have permission to view this device\'s data.';
    }
    if (statusCode == '400') {
      return 'Bad Request$code\n\n'
          'Server: "$apiMessage"$errDetail';
    }
    if (statusCode == '500') {
      return 'Server Error$code\n\n'
          'Server: "$apiMessage"\n\n'
          'Please try again later.';
    }

    return 'Error$code\n\nServer: "$apiMessage"$errDetail';
  }
}