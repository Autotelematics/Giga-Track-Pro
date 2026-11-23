import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:trackerapp/models/database_helper.dart';
import 'package:trackerapp/models/vehicle_maintancne_model.dart';
import 'package:trackerapp/services/local_notification.dart';
import 'package:trackerapp/utils/logger.dart';
import 'package:intl/intl.dart';

class DeviceMaintenanceProvider extends ChangeNotifier {
  List<VehicleMaintenance> _maintenanceList = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<VehicleMaintenance> get maintenanceList => _maintenanceList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get upcomingCount => _maintenanceList.length;

  bool get hasUpcoming => _maintenanceList.isNotEmpty;
  VehicleMaintenance? get nextMaintenance =>
      _maintenanceList.isNotEmpty ? _maintenanceList.first : null;

  DeviceMaintenanceProvider() {
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_maintenanceList.isNotEmpty) {
        fetchMaintenanceList('', isRefresh: true);
      }
    });
  }

  Future<void> fetchMaintenanceList(String vehicleId,
      {bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        _setLoading(true);
      }
      _setError(null);

      _maintenanceList =
      await DatabaseHelper.getVehicleMaintenances(vehicleId);

      _maintenanceList.sort((a, b) {
        final dateA = a.maintenanceDate;
        final dateB = b.maintenanceDate;
        return dateA.compareTo(dateB);
      });

      log('✅ Maintenance fetched: ${_maintenanceList.length} items');
      _notifyListeners();
    } catch (e, stackTrace) {
      log('❌ Error fetching maintenance: $e');
      log('STACKTRACE: $stackTrace');
      _setError('Failed to load maintenance schedule');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMaintenance(VehicleMaintenance maintenance) async {
    try {
      _setError(null);

      final id = await DatabaseHelper.insertVehicleMaintenance(maintenance);
      maintenance.maintenanceId = id;

      // Add to list instantly (optimistic update)
      _maintenanceList.add(maintenance);
      _maintenanceList.sort((a, b) {
        final dateA = a.maintenanceDate;
        final dateB = b.maintenanceDate;
        return dateA.compareTo(dateB);
      });
      _notifyListeners();

      // ✅ Show immediate confirmation
      LocalNotificationService.show(
        title: 'Maintenance Reminder Added',
        body: 'Reminder for ${maintenance.maintenanceVehicleName} (${maintenance.maintenanceType}) is set.',
      );

      // ✅ Schedule future reminder
      final now = DateTime.now();
      DateTime notifyTime = maintenance.maintenanceDate.subtract(const Duration(minutes: 5));

      AppLogger.info('DEBUG: Current Time: $now');
      AppLogger.info('DEBUG: Maintenance Date: ${maintenance.maintenanceDate}');

      // If 5 minutes before is already in the past, schedule at the exact maintenance time
      if (notifyTime.isBefore(now)) {
        AppLogger.info('DEBUG: 5-min lead time passed, switching to exact time');
        notifyTime = maintenance.maintenanceDate;
      }

      AppLogger.info('DEBUG: Final Notify Time: $notifyTime');

      if (notifyTime.isAfter(now)) {
        AppLogger.info('🚀 Calling LocalNotificationService.schedule with ID: $id');
        await LocalNotificationService.schedule(
          id: id,
          title: 'Maintenance Due Soon',
          body: 'Vehicle: ${maintenance.maintenanceVehicleName}\nType: ${maintenance.maintenanceType} is due at ${DateFormat('HH:mm').format(maintenance.maintenanceDate)}',
          scheduledDate: notifyTime,
        );
      } else {
        AppLogger.warning('⚠️ Not scheduling because notifyTime ($notifyTime) is in the past relative to now ($now)');
      }

      log('✅ Maintenance added successfully');
    } catch (e, stackTrace) {
      log('❌ Error adding maintenance: $e');
      log('STACKTRACE: $stackTrace');
      _setError('Failed to add maintenance');
      rethrow;
    }
  }

  Future<void> updateMaintenance(VehicleMaintenance maintenance) async {
    try {
      _setError(null);

      await DatabaseHelper.updateVehicleMaintenance(maintenance);

      // Update in list instantly
      final index = _maintenanceList.indexWhere(
            (m) => m.maintenanceId == maintenance.maintenanceId,
      );
      if (index != -1) {
        _maintenanceList[index] = maintenance;
      }
      _notifyListeners();

      log('✅ Maintenance updated successfully');
    } catch (e, stackTrace) {
      log('❌ Error updating maintenance: $e');
      log('STACKTRACE: $stackTrace');
      _setError('Failed to update maintenance');
      rethrow;
    }
  }

  Future<void> deleteMaintenance(VehicleMaintenance maintenance) async {
    try {
      _setError(null);

      final maintenanceId = maintenance.maintenanceId;
      final vehicleId = maintenance.maintenanceVehicleId;

      log('🗑️ Deleting maintenance: ID=$maintenanceId');

      // Remove from local list instantly
      final originalLength = _maintenanceList.length;
      _maintenanceList.removeWhere((m) => m.maintenanceId == maintenanceId);

      // Only notify if item was actually removed
      if (_maintenanceList.length < originalLength) {
        _notifyListeners();
      }

      // Delete from database
      await DatabaseHelper.deleteVehicleMaintenance(maintenanceId.toString());

      log('✅ Maintenance deleted: ID=$maintenanceId, Remaining=${_maintenanceList.length}');
    } catch (e, stackTrace) {
      log('❌ Error deleting maintenance: $e');
      log('STACKTRACE: $stackTrace');

      // Re-fetch on error to restore state
      await fetchMaintenanceList(maintenance.maintenanceVehicleId,
          isRefresh: true);
      _setError('Failed to delete maintenance');
      rethrow;
    }
  }

  Future<void> refresh({String vehicleId = ''}) async {
    await fetchMaintenanceList(vehicleId, isRefresh: true);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    _notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}