import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class AuthRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<dynamic> loginApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.postAPIresponse(
        AppUrl.baseURL + AppUrl.loginEndPoint,
        data,
      );
      print("response body is that $response");
      return response;
    } catch (e) {
      rethrow;
    }
  }
}