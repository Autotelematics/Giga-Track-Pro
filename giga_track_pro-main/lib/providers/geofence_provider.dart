import 'package:flutter/foundation.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/geo_fence_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/geo_fence_list_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class GeofenceProvider with ChangeNotifier {
  final GeoFenceListRepository _repository = GeoFenceListRepository();

  bool _disposed = false;

  ApiResponse<GeoFenceModel> geoFenceResponse = ApiResponse.loading();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setResponse(ApiResponse<GeoFenceModel> response) {
    if (_disposed) return;
    geoFenceResponse = response;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  /// 🔹 Fetch Geofence List
  Future<void> fetchGeofences() async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();
      final data = await _repository.geoFenceListFromAPI(apiKey);

      _setResponse(ApiResponse.complete(data));
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }

  /// 🔹 Delete Geofence
  Future<void> deleteGeofence(String fenceID) async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();
      await _repository.deleteGeoFenceActivationStatus(apiKey, fenceID);

      Utils.toastMessage('Geofence deleted successfully');
      await fetchGeofences();
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }

  /// 🔹 Change Status
  Future<void> changeGeofenceStatus(String fenceID, int status) async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();
      await _repository.changeGeoFenceActivationStatus(apiKey, fenceID, status);

      Utils.toastMessage('Geofence status updated');
      await fetchGeofences();
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }
}