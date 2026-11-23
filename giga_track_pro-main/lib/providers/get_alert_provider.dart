import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/get_alerts_list_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_alert_list_repository.dart';
import 'package:trackerapp/utils/logger.dart';

class AlertsProvider with ChangeNotifier {
  final AlertsRepository _repository = AlertsRepository();
  GetAlertsModel? _model;
  GetAlertsModel? _lastValidModel;
  bool _isLoading = false;
  bool _isLoadMore = false;
  bool _isAutoRefreshing = false;
  bool _isManualRefreshing = false;
  bool _isLiveEnabled = true;
  bool _hasMoreData = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int? _grandTotal;
  UserLoginProvider userLoginProvider = UserLoginProvider();
  Timer? _autoRefreshTimer;
  Timer? _countdownTimer;

  int _countdownSeconds = 20;

  // FILTERS
  String? _deviceIdFilter;
  String? _alertTypeFilter;
  String? _searchQuery;
  DateTime? _fromDateFilter;
  DateTime? _toDateFilter;
  bool _isTodayFilter = false;

  final Set<int> _selectedAlertIds = {};
  bool _isSelectionMode = false;

  // ==================== GETTERS ====================
  GetAlertsModel? get model => _model ?? _lastValidModel;
  bool get isLoading => _isLoading;
  bool get isLoadMore => _isLoadMore;
  bool get isAutoRefreshing => _isAutoRefreshing;
  bool get isManualRefreshing => _isManualRefreshing;
  bool get isLiveEnabled => _isLiveEnabled;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMoreData && _currentPage <= _totalPages;
  String? get alertTypeFilter => _alertTypeFilter;
  String? get deviceIdFilter => _deviceIdFilter;
  DateTime? get fromDateFilter => _fromDateFilter;
  DateTime? get toDateFilter => _toDateFilter;
  bool get isTodayFilter => _isTodayFilter;
  Set<int> get selectedAlertIds => _selectedAlertIds;
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedAlertIds.length;
  int get countdownSeconds => _countdownSeconds;

  List<Item> get filteredItems {
    final items = model?.items ?? [];
    if (_searchQuery == null || _searchQuery!.trim().isEmpty) return items;
    final query = _searchQuery!.toLowerCase().trim();
    return items.where((item) {
      return item.deviceName.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, int> get alertTypeCounts {
    final map = Map<String, int>.from(model?.counts ?? {});
    map['All'] = _grandTotal ?? model?.total ?? 0;
    return map;
  }

  // ==================== FILTER METHODS ====================
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setAlertTypeFilter(String? type) {
    _alertTypeFilter = type;
  }

  void setDeviceIdFilter(String? deviceId) {
    _deviceIdFilter = deviceId;
  }

  void setDateRangeFilter({
    required DateTime from,
    required DateTime to,
  }) {
    _fromDateFilter = from;
    _toDateFilter = to;
    _isTodayFilter = false;
  }

  Future<void> applyTodayFilter(BuildContext context) async {
    final now = DateTime.now();
    _fromDateFilter = DateTime(now.year, now.month, now.day);
    _toDateFilter = DateTime(now.year, now.month, now.day);
    _isTodayFilter = true;
    _alertTypeFilter = null;
    _deviceIdFilter = null;
    _searchQuery = null;

    await fetchAlerts(isRefresh: true, context: context, showLoading: true, isManual: true);
  }

  void clearFilters(BuildContext context) {
    _deviceIdFilter = null;
    _alertTypeFilter = null;
    _searchQuery = null;
    _fromDateFilter = null;
    _toDateFilter = null;
    _isTodayFilter = false;
    fetchAlerts(isRefresh: true, context: context, showLoading: true, isManual: true);
  }

  // ==================== SELECTION METHODS ====================
  void enterSelectionMode(int alertId) {
    _isSelectionMode = true;
    _selectedAlertIds.add(alertId);
    notifyListeners();
  }

  void toggleSelection(int alertId) {
    if (_selectedAlertIds.contains(alertId)) {
      _selectedAlertIds.remove(alertId);
    } else {
      _selectedAlertIds.add(alertId);
    }
    if (_selectedAlertIds.isEmpty) _isSelectionMode = false;
    notifyListeners();
  }

  void selectAll() {
    final items = model?.items ?? [];
    _selectedAlertIds.addAll(items.map((e) => e.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedAlertIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // ==================== LIVE REFRESH CONTROL ====================
  void toggleLiveRefresh() {
    _isLiveEnabled = !_isLiveEnabled;
    if (_isLiveEnabled) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
    notifyListeners();
  }

  // ==================== AUTO-REFRESH & COUNTDOWN ====================
  void startAutoRefresh() {
    if (!_isLiveEnabled) return;
    stopAutoRefresh();

    _countdownSeconds = 20;
    notifyListeners();

    _startCountdown();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
          (_) => _autoRefresh(),
    );
    AppLogger.info('🔄 Auto-refresh started for alerts');
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    AppLogger.info('⏹️ Auto-refresh stopped for alerts');
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isLiveEnabled) return;
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
      } else {
        _countdownSeconds = 20;
      }
      notifyListeners();
    });
  }

  Future<void> _autoRefresh() async {
    if (_isLoading || _isLoadMore || !_isLiveEnabled || _isAutoRefreshing || _isManualRefreshing) return;

    AppLogger.info('🔄 Auto-refreshing alerts in background...');
    await fetchAlerts(
      isRefresh: true,
      context: null,
      showLoading: false,
      isAutoRefresh: true,
      isManual: false,
    );

    _countdownSeconds = 20;
    notifyListeners();
  }

  void resetCountdown() {
    _countdownSeconds = 20;
    notifyListeners();
  }

  // ==================== MAIN FETCH METHOD ====================
  Future<void> fetchAlerts({
    bool isRefresh = false,
    BuildContext? context,
    bool showLoading = true,
    bool isAutoRefresh = false,
    bool isManual = false,
  }) async {
    if (_isLoading && !isAutoRefresh && !isManual) return;
    if (!isRefresh && _isLoadMore) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _grandTotal = null;
    }

    if (isManual) {
      _isManualRefreshing = true;
    } else if (isAutoRefresh) {
      _isAutoRefreshing = true;
    } else if (_currentPage == 1) {
      if (showLoading && _model == null && _lastValidModel == null) {
        _isLoading = true;
      }
    } else {
      _isLoadMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final userApiKeyString = await userLoginProvider.getUserApiHashString();

      final result = await _getAlertsWithRetry(
        page: _currentPage,
        token: userApiKeyString,
        deviceId: _deviceIdFilter,
        alertType: _alertTypeFilter,
        from: _fromDateFilter == null ? null : _startOfDayIso(_fromDateFilter!),
        to: _toDateFilter == null ? null : _endOfDayIso(_toDateFilter!),
      );

      if (result != null) {
        final pageSize = result.perPage > 0 ? result.perPage : 20;
        _totalPages = result.perPage > 0
            ? (result.total / result.perPage).ceil()
            : (result.total > 0 ? (result.total / 20).ceil() : 1);

        if (_deviceIdFilter == null &&
            _alertTypeFilter == null &&
            _fromDateFilter == null &&
            _toDateFilter == null) {
          _grandTotal = result.total;
        }

        final existingItems = isRefresh
            ? const <Item>[]
            : (_lastValidModel?.items ?? const <Item>[]);
        final newItems = isRefresh
            ? result.items
            : [
                ...existingItems,
                ...result.items
                    .where((n) => !existingItems.any((o) => o.id == n.id)),
              ];

        _lastValidModel = result.copyWith(items: newItems);
        _model = _lastValidModel;

        if (result.items.length < pageSize) {
          _hasMoreData = false;
        } else {
          _hasMoreData = true;
        }

        _selectedAlertIds
            .removeWhere((id) => !newItems.any((item) => item.id == id));

        if (_hasMoreData && _currentPage <= _totalPages) {
          _currentPage++;
        }
      } else if (_model == null) {
        throw Exception('Unable to load alerts right now. Please try again.');
      }
    } catch (e) {
      if (_model == null) {
        _errorMessage = _friendlyErrorMessage(e);
      } else if (_isLoadMore) {
        AppLogger.warning('Pagination fetch error: $e');
      } else if (isAutoRefresh) {
        AppLogger.warning('Auto-refresh background error: $e');
      }
    } finally {
      _isLoading = false;
      _isLoadMore = false;
      _isAutoRefreshing = false;
      _isManualRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore(BuildContext context) async {
    if (_isLoadMore || !hasMore || _isLoading || _isAutoRefreshing || _isManualRefreshing) return;
    await fetchAlerts(context: context, showLoading: false);
  }

  // ==================== DELETE ====================
  Future<bool> deleteSelectedAlerts() async {
    if (_selectedAlertIds.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final userApiKeyString = await userLoginProvider.getUserApiHashString();
      final success = await _repository.deleteAlerts(
        alertIds: List<int>.from(_selectedAlertIds),
        userApiHashKey: userApiKeyString,
      );

      if (success && _lastValidModel != null) {
        final remaining = _lastValidModel!.items
            .where((item) => !_selectedAlertIds.contains(item.id))
            .toList();
        _lastValidModel = _lastValidModel!.copyWith(
          items: remaining,
          total: (_lastValidModel!.total - _selectedAlertIds.length)
              .clamp(0, _lastValidModel!.total),
        );
        _model = _lastValidModel;
        _selectedAlertIds.clear();
        _isSelectionMode = false;
      }
      return success;
    } catch (e) {
      AppLogger.error('Delete alerts failed', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== API HELPERS ====================
  Future<GetAlertsModel?> _getAlertsWithRetry({
    required int page,
    required String token,
    String? deviceId,
    String? alertType,
    String? from,
    String? to,
  }) async {
    const maxAttempts = 3;
    for (int i = 1; i <= maxAttempts; i++) {
      try {
        final result = await _repository.getAlerts(
          page: page,
          userApiHashKey: token,
          deviceId: deviceId,
          alertType: alertType,
          from: from,
          to: to,
        );
        if (result != null) return result;
      } catch (e) {
        AppLogger.warning('Alert fetch attempt $i failed: $e');
        if (i == maxAttempts) rethrow;
      }
      if (i < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 450 * i));
      }
    }
    return null;
  }

  String _startOfDayIso(DateTime date) =>
      '${DateFormat('yyyy-MM-dd').format(date)}T00:00:00';

  String _endOfDayIso(DateTime date) =>
      '${DateFormat('yyyy-MM-dd').format(date)}T23:59:59';

  String _friendlyErrorMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('network is unreachable') ||
        text.contains('timed out') ||
        text.contains('clientexception')) {
      return 'Network connection issue. Please check internet and try again.';
    }
    final raw = error.toString().trim();
    return raw.startsWith('Exception:')
        ? raw.replaceFirst('Exception:', '').trim()
        : raw;
  }

  // ==================== LIFECYCLE ====================
  void reset() {
    stopAutoRefresh();
    _model = null;
    _lastValidModel = null;
    _isLoading = false;
    _isLoadMore = false;
    _isAutoRefreshing = false;
    _isManualRefreshing = false;
    _hasMoreData = true;
    _errorMessage = null;
    _currentPage = 1;
    _totalPages = 1;
    _grandTotal = null;
    _deviceIdFilter = null;
    _alertTypeFilter = null;
    _searchQuery = null;
    _fromDateFilter = null;
    _toDateFilter = null;
    _isTodayFilter = false;
    _selectedAlertIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
