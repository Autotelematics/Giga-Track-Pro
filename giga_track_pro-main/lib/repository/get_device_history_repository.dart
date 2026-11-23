import 'dart:convert';
import 'dart:developer';
import 'package:trackerapp/data/app_exeptions.dart';
import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/device_history_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class DeviceHistoryRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  Future<DeviceHistoryModel> deviceHistoryApi(
      String hashKey,
      String deviceHistoryDateTime,
      ) async {
    try {
      final url = AppUrl.baseURL +
          AppUrl.getDeviceHistoryEndPoint +
          hashKey +
          deviceHistoryDateTime;

      final response = await _apiServices.getApiResponse(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      log("📡 DEVICE HISTORY API RESPONSE: ${jsonEncode(response)}");

      final model = DeviceHistoryModel.fromJson(response);
      return model;
    } catch (e, stackTrace) {
      log("❌ REPO ERROR: $e");
      log("STACKTRACE: $stackTrace");
      if (e is FetchDataException) {
        rethrow;
      }
      throw FetchDataException(e.toString());
    }
  }
}