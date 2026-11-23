import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/geo_fence_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class GeoFenceListRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<GeoFenceModel> geoFenceListFromAPI(String hashkey) async {
    try {
      final response = await _apiServices.getApiResponse(
          '${AppUrl.baseURL}${AppUrl.getGeoFenceListEndPoint}$hashkey');
      return GeoFenceModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeGeoFenceActivationStatus(
      String hashkey, String fenceID, int fenceStatus) async {
    try {
      await _apiServices.getApiResponse(
          '${AppUrl.baseURL}${AppUrl.changeGeoFenceActivationEndPoint}$hashkey&id=$fenceID&active=$fenceStatus');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGeoFenceActivationStatus(
      String hashkey, String fenceID) async {
    try {
      await _apiServices.getApiResponse(
          '${AppUrl.baseURL}${AppUrl.deleteGeoFenceEndPoint}$hashkey&geofence_id=$fenceID');
    } catch (e) {
      rethrow;
    }
  }
}