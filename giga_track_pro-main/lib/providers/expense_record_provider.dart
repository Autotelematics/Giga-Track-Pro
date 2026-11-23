import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trackerapp/models/database_helper.dart';
import 'package:trackerapp/models/expense_record_model.dart';

class ExpenseRecordProvider extends ChangeNotifier {
  List<ExpenseRecord> _expenseRecords = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<ExpenseRecord> get expenseRecords => _expenseRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalAmount => _calculateTotal();

  ExpenseRecordProvider() {
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchExpenseRecords('');
    });
  }

  Future<void> fetchExpenseRecords(String vehicleId,
      {bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        _setLoading(true);
      }
      _setError(null);

      _expenseRecords =
          await DatabaseHelper.getExpenseRecordsForVehicle(vehicleId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load expenses');
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchCurrentMonthExpenses(String vehicleId) async {
    try {
      _setLoading(true);
      _setError(null);

      _expenseRecords =
          await DatabaseHelper.getExpenseRecordsForCurrentMonth(vehicleId);
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load current month expenses');
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> addExpense(ExpenseRecord record) async {
    try {
      _setError(null);
      await DatabaseHelper.insertExpenseRecord(record);
      await fetchExpenseRecords(record.vehicleId, isRefresh: true);
    } catch (e) {
      _setError('Failed to add expense');
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseRecord record) async {
    try {
      _setError(null);
      await DatabaseHelper.updateExpenseRecord(record);
      await fetchExpenseRecords(record.vehicleId, isRefresh: true);
    } catch (e) {
      _setError('Failed to update expense');
      rethrow;
    }
  }

  Future<void> deleteExpense(int recordId, String vehicleId) async {
    try {
      _setError(null);
      _expenseRecords.removeWhere((e) => e.id == recordId);
      _notifyListeners();

      await DatabaseHelper.deleteExpenseRecord(recordId);
      await fetchExpenseRecords(vehicleId, isRefresh: true);
    } catch (e) {
      _setError('Failed to delete expense');
      await fetchExpenseRecords(vehicleId, isRefresh: true);
      rethrow;
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var record in _expenseRecords) {
      total += record.amount;
    }
    return total;
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
