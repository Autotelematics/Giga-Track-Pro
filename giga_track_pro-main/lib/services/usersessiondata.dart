import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/data/globalsharedveriables.dart';
import 'package:trackerapp/models/user_login_model.dart';
import 'package:trackerapp/providers/all_devices_on_map_provider.dart';
import 'package:trackerapp/providers/auth_provider.dart';
import 'package:trackerapp/providers/device_live_tracking_provider.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/providers/get_devices_list_provider.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/services/fcm_token_service.dart';
import 'package:trackerapp/utils/logger.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

class UserSessionData {
  UserSessionData._internal();

  static final UserSessionData _instance = UserSessionData._internal();
  factory UserSessionData() => _instance;

  final UserLoginProvider _userLoginProvider = UserLoginProvider();
  final FcmTokenService _fcmTokenService = FcmTokenService();

  // Flag to prevent duplicate submissions during login
  bool _isSubmittingToken = false;

  /// Main entry point - check user session on app start (NON-BLOCKING)
  Future<void> checkUserSession(BuildContext context) async {
    AppLogger.info('🔍 Checking user session...');
    try {
      final userData = await _userLoginProvider.getUserApiHash();

      if (_isUserLoggedOut(userData)) {
        AppLogger.info('🚪 User is not logged in, redirecting to login');
        _goToLogin(context);
        return;
      }

      final apiHash = userData.userApiHash!;
      AppLogger.info('✅ User session found: ${_maskApiHash(apiHash)}');

      // Show welcome message
      _showWelcomeMessage();

      // IMMEDIATELY navigate to home (DO NOT BLOCK)
      _goToHome(context);

      // Submit FCM token in background AFTER navigation (fire and forget)
      _submitFcmTokenInBackground(apiHash);

    } catch (e, stackTrace) {
      AppLogger.error('Session check failed', e, stackTrace);
      _goToLogin(context);
    }
  }

  /// ✅ NEW: Public method to submit FCM token (used by Login)
  Future<void> submitFcmToken(String apiHash) async {
    AppLogger.info('🔄 Submitting FCM token...');

    if (_isSubmittingToken) {
      AppLogger.warning('Token submission already in progress, skipping duplicate');
      return;
    }

    _isSubmittingToken = true;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        AppLogger.info('Waiting 1 second for iOS APNS token...');
        await Future.delayed(const Duration(seconds: 1));
      }

      await _fcmTokenService.submitToken(apiHash);
      AppLogger.success('✅ FCM token submitted successfully');
    } catch (e) {
      AppLogger.warning('⚠️ FCM token submission failed: $e');
    } finally {
      _isSubmittingToken = false;
    }
  }

  /// Submit FCM token after successful login (NON-BLOCKING)
  Future<void> onLoginSuccess(String apiHash, BuildContext context) async {
    AppLogger.info('🔄 Submitting FCM token after login...');

    if (_isSubmittingToken) {
      AppLogger.warning('Token submission already in progress, skipping duplicate');
      return;
    }

    _isSubmittingToken = true;

    try {
      // Navigate to home IMMEDIATELY (DO NOT WAIT for token)
      _goToHome(context);

      // Submit token in background
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        AppLogger.info('Waiting 1 second for iOS APNS token...');
        await Future.delayed(const Duration(seconds: 1));
      }

      await _fcmTokenService.submitToken(apiHash);
      AppLogger.success('✅ FCM token submitted successfully during login');
    } catch (e) {
      AppLogger.warning('⚠️ FCM token submission during login failed: $e');
    } finally {
      _isSubmittingToken = false;
    }
  }

  /// Background token submission (fire and forget - NON-BLOCKING)
  void _submitFcmTokenInBackground(String apiHash) {
    // Use a longer delay for iOS
    final delay = defaultTargetPlatform == TargetPlatform.iOS
        ? const Duration(seconds: 2)
        : const Duration(milliseconds: 500);

    // Fire and forget - NEVER block navigation
    Future.delayed(delay, () {
      unawaited(
          _fcmTokenService.submitToken(apiHash).then((_) {
            AppLogger.success('✅ FCM token submitted successfully in background');
          }).catchError((e) {
            AppLogger.warning('⚠️ FCM token submission in background failed: $e');
          })
      );
    });
  }

  /// Complete logout and state cleanup across the entire application (INSTANT NON-BLOCKING)
  static Future<void> performLogout(BuildContext context) async {
    AppLogger.info('🚀 Initiating instant logout...');

    // 1. Navigate to Login Screen IMMEDIATELY (Zero delay for user)
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.login,
        (_) => false,
      );
    }

    // 2. Perform cleanup, provider resets, SharedPreferences clearing, and FCM token deletion in background
    Future.microtask(() async {
      try {
        try {
          if (context.mounted) {
            context.read<AuthProvider>().logout();
            context.read<GetDevicesListProvider>().reset();
            context.read<AlertsProvider>().reset();
            context.read<AllDevicesOnMapProvider>().reset();
            context.read<VehicleTrackingProvider>().reset();
            await context.read<UserLoginProvider>().userSessionRemove();
          }
        } catch (e) {
          AppLogger.warning('Error resetting providers during background logout: $e');
        }

        vehicleNames.clear();
        vehiclesNamesIdMap.clear();

        try {
          final sp = await SharedPreferences.getInstance();
          await sp.clear();
        } catch (e) {
          AppLogger.warning('Error clearing SharedPreferences: $e');
        }

        try {
          await FcmTokenService().deleteToken();
        } catch (e) {
          AppLogger.warning('Error deleting FCM token: $e');
        }

        AppLogger.success('✅ Logout background cleanup completed successfully');
      } catch (e) {
        AppLogger.warning('⚠️ Background logout cleanup error: $e');
      }
    });
  }

  /// Clean up on logout (NON-BLOCKING)
  Future<void> onLogout(BuildContext context) async {
    await performLogout(context);
  }

  /// Check if user is logged out
  bool _isUserLoggedOut(UserLoginData user) {
    return user.userApiHash == null || user.userApiHash!.isEmpty;
  }

  /// Show welcome message with personalized greeting
  void _showWelcomeMessage() {
    final hour = DateTime.now().hour;
    final greeting = _getGreeting(hour);
    AppLogger.info('👋 $greeting');
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    if (hour < 21) return 'Good Evening!';
    return 'Good Night!';
  }

  /// Navigation methods (IMMEDIATE, NON-BLOCKING)
  void _goToLogin(BuildContext context) {
    _navigate(context, RoutesName.login, log: '🔐 Redirecting to login');
  }

  void _goToHome(BuildContext context) {
    _navigate(context, RoutesName.home, log: '🏠 Navigating to home');
  }

  void _navigate(BuildContext context, String route, {String? log}) {
    if (log != null) AppLogger.info(log);

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
            (route) => false,
      );
    }
  }

  String _maskApiHash(String apiHash) {
    if (apiHash.length <= 8) return apiHash;
    return '${apiHash.substring(0, 4)}...${apiHash.substring(apiHash.length - 4)}';
  }
}

// Helper for unawaited futures
void unawaited(Future<void> future) {}
