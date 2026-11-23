import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/models/devices_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_devices_list_repository.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

class AllDevicesOnMapProvider with ChangeNotifier {
  bool _disposed = false;
  bool _isLoading = false;

  final GetDevicesListRepository _repository = GetDevicesListRepository();
  final UserLoginProvider _userLoginProvider = UserLoginProvider();

  ApiResponse<List<Marker>> deviceListMarkers = ApiResponse.loading();
  final List<Marker> markersList = [];

  bool get isLoading => _isLoading;
  bool get hasError => deviceListMarkers.hasError;
  String get errorMessage => deviceListMarkers.errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Utils

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return 'green';
      case 'ack':
        return 'red';
      case 'engine':
        return 'yellow';
      default:
        return 'blue';
    }
  }

  /// API Parsing

  List<DevicesModel> _parseResponse(Map<String, dynamic> json) {
    final items = (json['items'] ?? []) as List;

    final normalized = items.map((item) {
      final data = Map<String, dynamic>.from(item);

      data['icon'] = {'path': data['path'] ?? ''};
      data['icon_color'] =
          _getStatusColor((data['online'] ?? '').toString());

      data['lat'] = _toDouble(data['lat']);
      data['lng'] = _toDouble(data['lng']);
      data['course'] = _toDouble(data['course']);
      data['speed'] = _toDouble(data['speed']);

      data.putIfAbsent('tail', () => []);
      data.putIfAbsent('addr', () => '');

      return data;
    }).toList();

    return [
      DevicesModel(id: 0, title: 'All Vehicles', items: normalized),
    ];
  }

  ///Main API

  Future<void> fetchDeviceMarkersFromApi(BuildContext context) async {
    _setLoading(true);
    deviceListMarkers = ApiResponse.loading();
    notifyListeners();

    try {
      final authKey = await _userLoginProvider.getUserApiHashString();
      if (authKey.isEmpty) {
        throw Exception('Authentication failed');
      }

      final response = await _repository.getDevicesListApiNew(authKey);
      final deviceGroups = _parseResponse(response);

      markersList
        ..clear()
        ..addAll(await _createMarkers(deviceGroups, context));

      deviceListMarkers = ApiResponse.complete(markersList);
    } on FirebaseException catch (e) {
      deviceListMarkers = ApiResponse.error(
        e.code == 'apns-token-not-set'
            ? 'Notifications not configured'
            : (e.message ?? 'Firebase error'),
      );
    } catch (e) {
      deviceListMarkers = ApiResponse.error(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Marker Builder

  Future<List<Marker>> _createMarkers(
      List<DevicesModel> groups,
      BuildContext context,
      ) async {
    final List<Marker> markers = [];
    final icon = await _getMarkerIcon();

    for (final group in groups) {
      final items = group.items ?? [];
      for (int i = 0; i < items.length; i++) {
        final device = items[i];

        final lat = _toDouble(device['lat']);
        final lng = _toDouble(device['lng']);
        final bearing = _toDouble(device['course']);

        markers.add(
          Marker(
            markerId: MarkerId(device['id'].toString()),
            position: LatLng(lat, lng),
            rotation: bearing,
            icon: icon,
            infoWindow: InfoWindow(
              title: device['name']?.toString() ?? 'Unknown',
              snippet: device['path']?.toString() ?? '',
            ),
            onTap: () => _onMarkerTap(
              context,
              device,
              lat,
              lng,
              bearing,
              i,
            ),
          ),
        );
      }
    }

    return markers;
  }

  Future<BitmapDescriptor> _getMarkerIcon() async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        'assets/images/car_icon6.png',
      );
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Navigation

  void _onMarkerTap(
      BuildContext context,
      Map<String, dynamic> device,
      double lat,
      double lng,
      double bearing,
      int index,
      ) {
    Navigator.pushNamed(
      context,
      RoutesName.singledevicemap,
      arguments: DeviceOnMapInitialData(
        groupID: 0,
        itemID: index,
        initialLat: lat,
        initialLng: lng,
        initialDirection: bearing,
        deviceId: _toInt(device['id']),
        markerImage: BitmapDescriptor.defaultMarker,
      ),
    );
  }

  ///State

  void reset() {
    deviceListMarkers = ApiResponse.loading();
    markersList.clear();
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void retryFetchMarkers(BuildContext context) {
    fetchDeviceMarkersFromApi(context);
  }
}