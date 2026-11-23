import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/get_alerts_list_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class AlertsRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();
  final String _baseUrl = AppUrl.baseURL;

  /// GET ALERTS LIST
  Future<GetAlertsModel?> getAlerts({
    required int page,
    required String userApiHashKey,
    String? deviceId,
    String? alertType,
    String? from,
    String? to,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_api_hash': userApiHashKey,
        'page': page.toString(),
        'limit': '20',
        'per_page': '20',
      };
      if (deviceId != null && deviceId.trim().isNotEmpty) {
        queryParams['device_id'] = deviceId;
      }

      if (alertType != null && alertType.trim().isNotEmpty) {
        queryParams['type'] = alertType;
      }

      if (from != null && from.trim().isNotEmpty) {
        queryParams['date_from'] = from;
      }

      if (to != null && to.trim().isNotEmpty) {
        queryParams['date_to'] = to;
      }

      final uri = Uri.parse('${AppUrl.baseURL}${AppUrl.getAlertListEndPoint}')
          .replace(queryParameters: queryParams);

      log('GET ALERTS URL: $uri');

      final dynamic response =
      await _apiServices.getApiResponse(uri.toString());

      if (response is Map<String, dynamic>) {
        return GetAlertsModel.fromJson(response);
      }

      return null;
    } catch (e) {
      log('ERROR FETCHING ALERTS: $e');
      rethrow;
    }
  }

  /// DELETE ALERTS
  Future<bool> deleteAlerts({
    required List<int> alertIds,
    required String userApiHashKey,
  }) async {
    try {
      final ids = alertIds.join(',');
      final endpointPath = AppUrl.deleteEp.split('?').first;

      final uri = Uri.parse('$_baseUrl$endpointPath').replace(
        queryParameters: {
          'user_api_hash': userApiHashKey,
          'id': ids,
        },
      );

      log('DELETE ALERTS URL: $uri');

      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      log('STATUS CODE: ${response.statusCode}');
      log('RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 1 || data['success'] == true;
      }

      return false;
    } catch (e) {
      log('ERROR DELETING ALERTS: $e');
      return false;
    }
  }
}