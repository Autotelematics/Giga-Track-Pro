import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:trackerapp/models/user_login_model.dart';
import 'package:trackerapp/repository/auth_repository.dart';
import 'package:trackerapp/utils/utils.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  String? _error;
  UserLoginData? _userData;
  bool _isPasswordHidden = true;
  Map<String, dynamic>? _permissions;

  bool get isPasswordHidden => _isPasswordHidden;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserLoginData? get userData => _userData;
  bool get isLoggedIn => _userData?.userApiHash != null;
  Map<String, dynamic>? get permissions => _permissions;

  void togglePasswordVisibility() {
    _isPasswordHidden = !_isPasswordHidden;
    notifyListeners();
  }

  Future<bool> loginApi(
      Map<String, dynamic> loginData,
      BuildContext context,
      ) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authRepository.loginApi(loginData);

      if (response != null && response['status'] == 1) {
        _userData = UserLoginData.fromJson(response);

        // ✅ Extract and store permissions from response
        _permissions = response['permissions'] ?? {};

        // Log permissions for debugging
        log('📋 Permissions received: $_permissions');

        // ✅ Check if user has any permissions
        if (!_hasAnyPermission(_permissions)) {
          log('❌ User has no permissions');
          _setError('You don\'t have permission to use this app');
          if (context.mounted) {
            Utils.flushBarErrorMessage('You don\'t have permission to use this app', context);
          }
          return false;
        }

        // ✅ Check if user has at least view permission for any category
        if (!_hasAnyViewPermission(_permissions)) {
          log('❌ User has no view permissions');
          _setError('You don\'t have permission to view any data');
          if (context.mounted) {
            Utils.flushBarErrorMessage('You don\'t have permission to view any data', context);
          }
          return false;
        }

        return true;
      } else {
        final message = response?['message'] ?? 'Login failed';
        _setError(message);

        if (context.mounted) {
          Utils.flushBarErrorMessage(message, context);
        }
        return false;
      }
    } catch (e) {
      log('Login Error: $e');

      const message = 'Incorrect email or password';
      _setError(message);

      if (context.mounted) {
        Utils.flushBarErrorMessage(message, context);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Check if user has any permission at all
  bool _hasAnyPermission(Map<String, dynamic>? permissions) {
    if (permissions == null || permissions.isEmpty) {
      return false;
    }

    // Check if any category has at least one true permission
    for (var category in permissions.values) {
      if (category is Map) {
        for (var value in category.values) {
          if (value == true) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // ✅ Check if user has any view permission
  bool _hasAnyViewPermission(Map<String, dynamic>? permissions) {
    if (permissions == null || permissions.isEmpty) {
      return false;
    }

    // Check if any category has view permission true
    for (var category in permissions.values) {
      if (category is Map) {
        if (category['view'] == true) {
          return true;
        }
      }
    }
    return false;
  }

  // ✅ Get the first available category the user has access to
  String? getFirstAccessibleCategory() {
    if (_permissions == null || _permissions!.isEmpty) {
      return null;
    }

    for (var entry in _permissions!.entries) {
      if (entry.value is Map) {
        var category = entry.value as Map;
        if (category['view'] == true) {
          return entry.key;
        }
      }
    }
    return null;
  }

  void logout() {
    _userData = null;
    _permissions = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}