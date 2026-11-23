import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:trackerapp/models/get_device_live_tracking_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class GetDeviceLiveTrackingRepository {
  UserLoginProvider userLoginProvider = UserLoginProvider();

  Future<GetDeviceLiveTrackingModel?> getDeviceLiveTrackingApi({
    required int deviceId,
  }) async {
    try {
      final userApiKey = await userLoginProvider.getUserApiHashString();
      final url = Uri.parse(
          "${AppUrl.baseURL}${AppUrl.getDeviceLiveTrackingEp}$userApiKey&id=$deviceId");
      final headers = {"Content-Type": "application/json"};
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return getDeviceLiveTrackingModelFromJson(response.body);
      } else {
        final decodedBody = jsonDecode(response.body);
        final message = decodedBody['message'] ?? 'API Error ${response.statusCode}';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }
}