import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/get_report_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class GetReportRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();

  /// Initial report generation request
  Future<GetReportModel> getReportsApi(
      String hashkey, String getReportDateTime) async {
    try {
      dynamic response = await _apiServices.getApiResponse(
        AppUrl.baseURL + AppUrl.generateReports + hashkey + getReportDateTime,
      );
      return GetReportModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Poll the report URL to check if generation is complete
  Future<GetReportModel> checkReportStatus(String reportUrl) async {
    try {
      dynamic response = await _apiServices.getApiResponse(reportUrl);
      return GetReportModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}