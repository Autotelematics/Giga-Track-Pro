import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/device_commnad_list_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class GetDeviceCommandList {
  final NetworkApiServices _apiServices = NetworkApiServices();
  List<DeviceCommandsListsModel> devicesCommandsList = [];

  Future<List<DeviceCommandsListsModel>> getDeviceCommandsListApi(
      String hashkey, String deviceID) async {
    try {
      dynamic response = await _apiServices.getApiResponse('${AppUrl.baseURL}${AppUrl.getDeviceCommandsEndPoint}$hashkey&device_id=$deviceID');

      devicesCommandsList = List.from(response)
          .map((e) => DeviceCommandsListsModel.fromJson(e))
          .toList();

      return devicesCommandsList;
    } catch (e) {
      rethrow;
    }
  }
}
