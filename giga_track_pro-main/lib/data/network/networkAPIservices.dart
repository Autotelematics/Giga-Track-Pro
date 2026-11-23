import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:trackerapp/data/app_exeptions.dart';
import 'package:http/http.dart' as http;

class NetworkApiServices {
  static const Duration _defaultTimeout = Duration(seconds: 120);

  Future<dynamic> getApiResponse(String url) async {
    try {

      final response = await http
          .get(Uri.parse(url))
          .timeout(_defaultTimeout);

      print('API Response Status Code: ${response.statusCode}');

      final contentType = response.headers['content-type'] ?? '';
      final bodyPreview = response.body.length > 100
          ? response.body.substring(0, 100)
          : response.body;
      print('API Response Body: $bodyPreview');

      return returnResponse(response);
    } on SocketException {
      throw FetchDataException('No internet connection', 'Alert');
    } on TimeoutException {
      throw FetchDataException('Request timeout. Please try again.', 'Alert');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> postAPIresponse(String url, dynamic data) async {
    try {
      final response = await http
          .post(Uri.parse(url), body: data)
          .timeout(_defaultTimeout);
      return returnResponse(response);
    } on SocketException {
      throw FetchDataException('No internet connection');
    } on TimeoutException {
      throw FetchDataException('Request timeout');
    }
  }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        final contentType = response.headers['content-type'] ?? '';

        // Server ne direct PDF bytes bheje hain
        if (contentType.contains('application/pdf') ||
            response.body.trimLeft().startsWith('%PDF')) {
          // URL wapis karo as-is — PdfViewer directly use karega
          return {
            'status': 1,
            'url': response.request?.url.toString() ?? '',
          };
        }

        // Normal JSON response
        try {
          return jsonDecode(response.body);
        } catch (_) {
          throw FetchDataException('Invalid response from server');
        }

      case 400:
        dynamic decodedJson;
        try {
          decodedJson = jsonDecode(response.body);
        } catch (_) {
          decodedJson = null;
        }

        String errorMessage = "Something went wrong";
        if (decodedJson != null && decodedJson is Map<String, dynamic>) {
          if (decodedJson['message'] != null) {
            errorMessage = decodedJson['message'].toString();
          } else if (decodedJson['errors'] != null) {
            errorMessage = decodedJson['errors'].toString();
          }
        }

        if (errorMessage.toLowerCase().contains("expired")) {
          errorMessage = "Expired";
        }

        throw FetchDataException(errorMessage);

      case 401:
      case 403:
      case 404:
        dynamic decodedJson;
        try {
          decodedJson = jsonDecode(response.body);
        } catch (_) {
          decodedJson = null;
        }

        if (decodedJson != null && decodedJson is Map<String, dynamic> && decodedJson['message'] != null) {
          throw FetchDataException(decodedJson['message'].toString());
        }

        if (response.statusCode == 404) {
          throw FetchDataException("Resource not found");
        }

        throw FetchDataException(
            "Session expired or access denied. Please login again.");

      case 500:
        throw FetchDataException("Server error. Please try again later.");

      default:
        throw FetchDataException('Error occurred (${response.statusCode})');
    }
  }
}