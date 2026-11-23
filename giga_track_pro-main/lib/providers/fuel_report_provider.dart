import 'package:flutter/cupertino.dart';
import 'package:trackerapp/data/network/networkAPIservices.dart';   // ← Yeh import zaroori hai
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/device_history_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_device_history_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class FuelReportProvider with ChangeNotifier {
  final DeviceHistoryRepository _repository = DeviceHistoryRepository();

  ApiResponse<DeviceHistoryModel> historyResponse = ApiResponse.loading();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setResponse(ApiResponse<DeviceHistoryModel> response) {
    if (_disposed) return;
    historyResponse = response;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  Future<void> fetchDeviceHistory({
    required String deviceID,
    required String fromDate,
    required String toDate,
    required String fromTime,
    required String toTime,
  }) async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();

      final query = '&device_id=$deviceID'
          '&from_date=$fromDate'
          '&from_time=$fromTime'
          '&to_date=$toDate'
          '&to_time=$toTime';

      final data = await _repository.deviceHistoryApi(apiKey, query);

      _setResponse(ApiResponse.complete(data));
    } catch (e) {
      if (_disposed) return;

      String errorMessage = e.toString();

      // Clean Error Messages for User
      if (errorMessage.toLowerCase().contains("expired")) {
        errorMessage = "Expired";
      } else if (errorMessage.toLowerCase().contains("timeout")) {
        errorMessage = "Request timeout. Please check your internet connection.";
      } else if (errorMessage.toLowerCase().contains("no internet")) {
        errorMessage = "No internet connection. Please check your connection.";
      }

      _setResponse(ApiResponse.error(errorMessage));

      Utils.toastMessage(errorMessage);
    }
  }
}