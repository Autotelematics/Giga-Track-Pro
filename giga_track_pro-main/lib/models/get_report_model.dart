class GetReportModel {
  int? status;
  String? url;

  GetReportModel({this.status, this.url});

  GetReportModel.fromJson(Map<String, dynamic> json) {
    status = json["status"];
    url = json["url"];
  }

  bool get isReady => status == 1;
  bool get isQueued => status == 3;
  bool get isFailed => status == 0 || status == 2;
}