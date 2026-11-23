import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trackerapp/data/response/api_response.dart';
import 'package:trackerapp/models/get_report_model.dart';
import 'package:trackerapp/models/view_report_intial_data.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_report_repository.dart';
import 'package:trackerapp/utils/utils.dart';

enum ReportFetchState { idle, requesting, polling, downloading, ready, error }

class GetReportProvider with ChangeNotifier {
  final GetReportRepository _repository = GetReportRepository();

  ApiResponse<GetReportModel> reportResponse = ApiResponse.loading();

  ReportFetchState _fetchState = ReportFetchState.idle;
  ReportFetchState get fetchState => _fetchState;

  Uint8List? pdfBytes;

  String _pollingMessage = 'Generating report...';
  String get pollingMessage => _pollingMessage;

  int _pollAttempts = 0;
  static const int _maxPollAttempts = 40;
  static const Duration _pollInterval = Duration(seconds: 5);
  static const Duration _initialDelay = Duration(seconds: 3);

  Timer? _pollTimer;
  bool _disposed = false;
  String? _pendingPollUrl;

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  void _setResponse(ApiResponse<GetReportModel> response) {
    if (_disposed) return;
    reportResponse = response;
    notifyListeners();
  }

  void _setState(ReportFetchState state) {
    if (_disposed) return;
    _fetchState = state;
    notifyListeners();
  }

  Future<String> _getApiKey() async {
    return await UserLoginProvider().getUserApiHashString();
  }

  Future<void> fetchReports(ViewReportInitialData data) async {
    if (_disposed) return;

    _pollTimer?.cancel();
    _pollAttempts = 0;
    _pendingPollUrl = null;
    pdfBytes = null;

    _setState(ReportFetchState.requesting);
    _setResponse(ApiResponse.loading());

    try {
      final apiKey = await _getApiKey();

      final query =
          '&date_from=${data.fromDate}'
          '&date_to=${data.toDate}'
          '&from_time=${data.fromTime}'
          '&to_time=${data.toTime}'
          '&devices[]=${data.deviceID}'
          '&format=${data.reportFormat}'
          '&type=${data.reportType}';

      final result = await _repository.getReportsApi(apiKey, query);

      if (_disposed) return;
      if (result.isReady && result.url != null) {
        await _downloadPdfBytes(result.url!, result);
      } else if (result.isQueued && result.url != null) {
        _pendingPollUrl = result.url;
        _startPolling();
      } else {
        _setState(ReportFetchState.error);
        _setResponse(
            ApiResponse.error('Unable to generate report. Please try again.'));
      }
    } catch (e) {
      if (_disposed) return;
      _setState(ReportFetchState.error);
      _setResponse(ApiResponse.error(e.toString()));
      Utils.toastMessage(e.toString());
    }
  }

  void _startPolling() {
    if (_disposed || _pendingPollUrl == null) return;
    _setState(ReportFetchState.polling);
    _updatePollingMessage();

    Future.delayed(_initialDelay, () {
      if (_disposed) return;
      _doPoll();
    });
  }

  void _doPoll() async {
    if (_disposed || _pendingPollUrl == null) return;

    _pollAttempts++;
    _updatePollingMessage();

    if (_pollAttempts > _maxPollAttempts) {
      _setState(ReportFetchState.error);
      _setResponse(ApiResponse.error(
        'Report is taking too long.\nPlease try a smaller date range or try again later.',
      ));
      return;
    }

    try {
      final result = await _repository.checkReportStatus(_pendingPollUrl!);

      if (_disposed) return;
      if (result.isReady) {
        _pollTimer?.cancel();
        await _downloadPdfBytes(_pendingPollUrl!, result);
      } else if (result.isQueued) {
        _schedulNextPoll();
      } else {
        _setState(ReportFetchState.error);
        _setResponse(
            ApiResponse.error('Report generation failed. Please try again.'));
      }
    } catch (e) {
      if (_disposed) return;
      if (_pollAttempts >= _maxPollAttempts) {
        _setState(ReportFetchState.error);
        _setResponse(ApiResponse.error(e.toString()));
      } else {
        _schedulNextPoll();
      }
    }
  }

  /// PDF URL se bytes download karo
  Future<void> _downloadPdfBytes(String url, GetReportModel model) async {
    if (_disposed) return;

    try {
      _setState(ReportFetchState.downloading);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 120));

      if (_disposed) return;

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Verify PDF signature
        if (bytes.length > 4 &&
            bytes[0] == 0x25 && // %
            bytes[1] == 0x50 && // P
            bytes[2] == 0x44 && // D
            bytes[3] == 0x46) { // F
          pdfBytes = bytes;
          _setState(ReportFetchState.ready);
          _setResponse(ApiResponse.complete(model));
        } else {
          throw Exception('Invalid PDF data received');
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (_disposed) return;
      _setState(ReportFetchState.error);
      _setResponse(ApiResponse.error('Failed to download PDF: ${e.toString()}'));
    }
  }

  void _schedulNextPoll() {
    if (_disposed) return;
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, _doPoll);
  }

  void _updatePollingMessage() {
    final elapsed = _pollAttempts * _pollInterval.inSeconds;
    if (_pollAttempts <= 3) {
      _pollingMessage = 'Generating report...';
    } else if (elapsed < 60) {
      _pollingMessage = 'Still generating, please wait...';
    } else {
      _pollingMessage =
      'Large report detected.\nThis may take a few more seconds...';
    }
    if (!_disposed) notifyListeners();
  }
}