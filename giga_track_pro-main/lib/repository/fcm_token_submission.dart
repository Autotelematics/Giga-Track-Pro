import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/fcm_token_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class FcmTokenRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<FCMTokenModel> fcmTokenSubmissionApi(
      String hashkey, String fcmToken) async {
    try {
      dynamic response = await _apiServices.getApiResponse(
          '${AppUrl.baseURL}${AppUrl.fcmAlertTokenEndPoint}$hashkey&token=$fcmToken');
      return response = FCMTokenModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
