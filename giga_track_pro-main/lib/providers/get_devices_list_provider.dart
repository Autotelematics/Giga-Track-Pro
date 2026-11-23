import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trackerapp/models/get_device_list_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_devices_list_repository.dart';

class GetDevicesListProvider with ChangeNotifier {
  final GetDevicesListRepository repository;
  BuildContext? _context;
  bool _isFilterOpen = false;
  bool get isFilterOpen => _isFilterOpen;

  void toggleFilter() {
    _isFilterOpen = !_isFilterOpen;
    notifyListeners();
  }

  bool _isLoading = false;
  bool _showLoading = true;
  String? _error;
  List<Item> _filteredVehicles = [];
  UserLoginProvider userLoginProvider = UserLoginProvider();

  String _filterStatus = 'all';
  String _searchQuery = '';

  GetDevicesListModel? _lastValidModel;
  Timer? _timer;

  // Public getters
  bool get isLoading => _isLoading;
  bool get showLoading => _showLoading;
  String? get error => _error;
  GetDevicesListModel? get vehicleData => _lastValidModel;
  GetDevicesListModel? get model => _lastValidModel;
  List<Item> get filteredVehicles => _filteredVehicles;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  GetDevicesListProvider(this.repository);

  void init(BuildContext context) {
    _context = context;
    startPeriodicUpdates();
    fetchData();
  }

  void startPeriodicUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchData(isPeriodic: true));
  }

  Future<void> fetchData({bool isPeriodic = false}) async {
    final context = _context;
    if (context == null) return;

    final hasValidData = _lastValidModel?.items?.isNotEmpty == true;
    final shouldShowLoading = !isPeriodic && !hasValidData;

    if (shouldShowLoading) {
      _showLoading = true;
      notifyListeners();
    }

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _fetchWithRetry(context);
      if (data != null && data.items != null && data.items!.isNotEmpty) {
        _lastValidModel = data;
        _error = null;
        _applyFilters();
      } else {
        _filteredVehicles = hasValidData ? _filteredVehicles : [];
        notifyListeners();
      }
    } catch (e) {
      if (!hasValidData) {
        _error = _friendlyErrorMessage(e);
        _filteredVehicles = [];
        notifyListeners();
      } else {
        _error = null;
      }
    } finally {
      _isLoading = false;
      _showLoading = false;
      notifyListeners();
    }
  }

  Future<GetDevicesListModel?> _fetchWithRetry(BuildContext context) async {
    Future<String> userApiKey = userLoginProvider.getUserApiHashString();
    String userApiKeyString = await userApiKey;
    const maxAttempts = 3;
    Object? lastError;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final raw = await repository.getDevicesListApiNew(userApiKeyString);
        return GetDevicesListModel.fromJson(raw);
      } catch (e) {
        lastError = e;
        if (!_isLikelyNetworkError(e) || attempt == maxAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    if (lastError != null) throw lastError;
    return null;
  }
  bool _isLikelyNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('connection closed') ||
        text.contains('network is unreachable') ||
        text.contains('timed out') ||
        text.contains('clientexception');
  }

  String _friendlyErrorMessage(Object error) {
    if (_isLikelyNetworkError(error)) {
      return "Unable to reach server right now. Please check internet and tap Retry.";
    }
    final text = error.toString().trim();
    if (text.startsWith('Exception:')) {
      return text.replaceFirst('Exception:', '').trim();
    }
    return text;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
  }

  void setFilter(String status) {
    if (_filterStatus == status) return;
    _filterStatus = status;
    _applyFilters();
  }

  void _applyFilters() {
    if (_lastValidModel?.items == null) {
      _filteredVehicles = [];
      notifyListeners();
      return;
    }

    var filtered = List<Item>.from(_lastValidModel!.items!);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((v) =>
      v.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
          false)
          .toList();
    }
    else {
      switch (_filterStatus) {
        case 'running':
          filtered = filtered.where((v) => v.online == 'online').toList();
          break;
        case 'stopped':
          filtered = filtered.where((v) => v.online == 'ack').toList();
          break;
        case 'idle':
          filtered = filtered.where((v) => v.online == 'engine').toList();
          break;
        case 'offline':
          filtered = filtered
              .where((v) =>
          v.online == 'offline' &&
              v.time?.toLowerCase() != 'not connected' &&
              v.time?.toLowerCase() != 'expired')
              .toList();
          break;
        case 'nodata':
          filtered = filtered
              .where((v) =>
          v.online == 'offline' &&
              v.time?.toLowerCase() == 'not connected')
              .toList();
          break;
        case 'expired':
          filtered = filtered
              .where((v) =>
          v.online == 'offline' &&
              v.time?.toLowerCase() == 'expired')
              .toList();
          break;
        case 'parked':
          filtered = filtered.where((v) => v.online == 'black').toList();
          break;
      }
    }

    _filteredVehicles = filtered;
    notifyListeners();
  }

  int getCountForStatus(String status) {
    final items = List<Item>.from(_lastValidModel?.items ?? []);
    if (items.isEmpty) return 0;

    switch (status) {
      case 'all':
        return items.length;
      case 'running':
        return items.where((i) => i.online == 'online').length;
      case 'stopped':
        return items.where((i) => i.online == 'ack').length;
      case 'idle':
        return items.where((i) => i.online == 'engine').length;
      case 'offline':
        return items
            .where((i) =>
        i.online == 'offline' &&
            i.time?.toLowerCase() != 'not connected' &&
            i.time?.toLowerCase() != 'expired')
            .length;
      case 'nodata':
        return items
            .where((i) =>
        i.online == 'offline' &&
            i.time?.toLowerCase() == 'not connected')
            .length;
      case 'expired':
        return items
            .where((i) =>
        i.online == 'offline' && i.time?.toLowerCase() == 'expired')
            .length;
      case 'parked':
        return items.where((i) => i.online == 'black').length;
      default:
        return 0;
    }
  }

  String formatDuration(int seconds) {
    if (seconds < 60) return "$seconds sec";
    int minutes = seconds ~/ 60;
    seconds = seconds % 60;
    if (minutes < 60) {
      return seconds > 0 ? "$minutes min $seconds sec" : "$minutes min";
    }
    int hours = minutes ~/ 60;
    minutes = minutes % 60;
    if (hours < 24) {
      String hr = "$hours hr";
      String min = minutes > 0 ? " $minutes min" : "";
      return seconds > 0 ? "$hr$min $seconds sec" : min.isNotEmpty ? "$hr$min" : hr;
    }
    int days = hours ~/ 24;
    hours = hours % 24;
    String d = "$days d";
    String h = hours > 0 ? " $hours h" : "";
    String m = minutes > 0 ? " $minutes m" : "";
    return seconds > 0 ? "$d$h$m $seconds s" : m.isNotEmpty ? "$d$h$m" : h.isNotEmpty ? "$d$h" : d;
  }

  int parseStopDuration(String duration) {
    final regex = RegExp(r'((\d+)h)?\s*((\d+)min)?\s*((\d+)s)?');
    final match = regex.firstMatch(duration);
    if (match == null) return 0;
    int hours = int.tryParse(match.group(2) ?? '0') ?? 0;
    int minutes = int.tryParse(match.group(4) ?? '0') ?? 0;
    int seconds = int.tryParse(match.group(6) ?? '0') ?? 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _lastValidModel = null;
    _filteredVehicles = [];
    _searchQuery = '';
    _filterStatus = 'all';
    _isLoading = false;
    _showLoading = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}