class ViewReportInitialData {
  final String fromDate;
  final String toDate;
  final String fromTime;
  final String toTime;
  final int deviceID;
  final String reportFormat;
  final int reportType;

  const ViewReportInitialData(
      this.fromDate,
      this.toDate,
      this.deviceID,
      this.reportFormat,
      this.reportType, {
        this.fromTime = '00:00:00',
        this.toTime   = '23:59:59',
      });
}