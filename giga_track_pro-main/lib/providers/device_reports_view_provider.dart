import 'package:flutter/foundation.dart';
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/report_type_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/reporttype_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class ReportTypeProvider with ChangeNotifier {
  final ReportTypeRepository _repository = ReportTypeRepository();

  ApiResponse<ReportTypeModel> reportTypeResponse =
  ApiResponse.loading();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setResponse(ApiResponse<ReportTypeModel> response) {
    if (_disposed) return;
    reportTypeResponse = response;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  /// Fetch Report Types
  Future<void> fetchReportTypes() async {
    if (_disposed) return;

    try {
      _setResponse(ApiResponse.loading());

      final apiKey = await _getApiKey();
      final data = await _repository.reportTypesApi(apiKey);

      _setResponse(ApiResponse.complete(data));
    } catch (e) {
      if (_disposed) return;

      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }
}