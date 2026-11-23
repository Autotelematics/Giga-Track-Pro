import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:trackerapp/res/components/app_end_point.dart';

class ChangePasswordRepository {

  Future<Map<String, dynamic>> changePasswordFromApi(
      String hashkey, String password) async {
    try {
      final url =
          '${AppUrl.baseURL}${AppUrl.changePasswordEndPoint}$hashkey&password=$password&password_confirmation=$password';
      dynamic response = await http
        .get(Uri.parse(url));
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      return responseBody;


    } catch (e, stackTrace) {
      print("Error: $e");
      print("StackTrace: $stackTrace");

      rethrow;
    }
  }
}