import 'package:trackerapp/data/network/networkAPIservices.dart';
import 'package:trackerapp/models/report_type_model.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class ReportTypeRepository {
  final NetworkApiServices _apiServices = NetworkApiServices();
  Future<ReportTypeModel> reportTypesApi(String hashkey) async {
    try {
      dynamic response = await _apiServices
          .getApiResponse(AppUrl.baseURL + AppUrl.generateReportType + hashkey);
      return response = ReportTypeModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
