import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/command_result_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class SendCommandRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<CommandResultModel> deviceCommandResultApi(
      String hashkey, String deviceCommand, String deviceID) async {
    try {
      dynamic response = await _apiServices.getApiResponse(
          '${AppUrl.baseURL}${AppUrl.sendDeviceCommandEndPoint}$hashkey&device_id=$deviceID&type=$deviceCommand');
      return response = CommandResultModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
