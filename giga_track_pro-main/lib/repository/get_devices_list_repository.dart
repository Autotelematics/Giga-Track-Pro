import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class GetDevicesListRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<Map<String, dynamic>> getDevicesListApiNew(String hashkey) async {
    try {
      dynamic response = await _apiServices
          .getApiResponse(AppUrl.baseURL + AppUrl.getDevicesEndPoint + hashkey);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}