import 'package:flutter/material.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/alert_list_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/alert_type_list_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class AlertsProvider with ChangeNotifier {
  final AlertListRepository _repository = AlertListRepository();

  ApiResponse<AlertsListModel> alertsResponse = ApiResponse.loading();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setResponse(ApiResponse<AlertsListModel> response) {
    if (_disposed) return;
    alertsResponse = response;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  /// 🔹 Fetch Alerts List
  Future<void> fetchAlerts() async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();
      final data = await _repository.alertsTypeListApi(apiKey);

      _setResponse(ApiResponse.complete(data));
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }

  /// 🔹 Change Alert Status
  Future<void> changeAlertStatus(String alertID, String status) async {
    if (_disposed) return;

    try {
      final apiKey = await _getApiKey();

      await _repository.changeAlertValueApi(apiKey, alertID, status);

      await fetchAlerts(); // refresh list after update
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }
}