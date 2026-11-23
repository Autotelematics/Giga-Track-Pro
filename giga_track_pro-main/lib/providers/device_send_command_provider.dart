import 'package:flutter/material.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/command_result_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/send_command_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class SendDeviceCommandProvider with ChangeNotifier {
  final SendCommandRepository _repository = SendCommandRepository();

  ApiResponse<CommandResultModel> commandResponse =
  ApiResponse.loading();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setResponse(ApiResponse<CommandResultModel> response) {
    if (_disposed) return;
    commandResponse = response;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  /// Send Device Command
  Future<void> sendCommand(String command, String deviceID) async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());
      final apiKey = await _getApiKey();
      final result = await _repository.deviceCommandResultApi(
        apiKey,
        command,
        deviceID,
      );
      Utils.toastMessage(result.message.toString());
      _setResponse(ApiResponse.complete(result));
    } catch (e) {
      if (_disposed) return;
      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }
}