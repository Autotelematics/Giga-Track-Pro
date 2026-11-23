import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/alert_list_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class AlertListRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<AlertsListModel> alertsTypeListApi(String hashkey) async {
    try {
      dynamic response = await _apiServices
          .getApiResponse(AppUrl.baseURL + AppUrl.getAlertsTypeList + hashkey);
      return response = AlertsListModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeAlertValueApi(
      String hashkey, String alertID, String activationStatus) async {
    try {
      dynamic response = await _apiServices.getApiResponse(
          '${AppUrl.baseURL}${AppUrl.changeAlertValue}$hashkey&id=$alertID&active=$activationStatus');
         } catch (e) {
      rethrow;
    }
  }
}
