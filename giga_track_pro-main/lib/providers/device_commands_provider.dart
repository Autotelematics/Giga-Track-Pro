import 'package:flutter/foundation.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/device_commnad_list_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/device_command_list_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class DeviceCommandsProvider with ChangeNotifier {
  final GetDeviceCommandList _repository = GetDeviceCommandList();

  ApiResponse<List<DeviceCommandsListsModel>> commandsResponse =
  ApiResponse.loading();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setResponse(
      ApiResponse<List<DeviceCommandsListsModel>> response) {
    if (_disposed) return;
    commandsResponse = response;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  /// Refresh UI
  void refresh() {
    if (_disposed) return;
    notifyListeners();
  }


  void resetToLoading() {
    _setResponse(ApiResponse.loading());
  }

  /// Fetch Device Commands
  Future<void> fetchDeviceCommands(String deviceID) async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();
      final data =
      await _repository.getDeviceCommandsListApi(apiKey, deviceID);

      _setResponse(ApiResponse.complete(data));
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }
}