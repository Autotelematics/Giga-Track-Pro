import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:trackerapp/repository/fcm_token_submission.dart';
import 'package:trackerapp/utils/logger.dart';

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final FcmTokenRepository _fcmRepo = FcmTokenRepository();
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 1);

  // Cache for simulator check
  bool? _isSimulator;

  /// Submit FCM token with proper iOS APNS handling (NON-BLOCKING)
  Future<void> submitToken(String apiHash, {bool retryOnFailure = true}) async {
    if (apiHash.isEmpty) {
      AppLogger.warning('Cannot submit FCM token: apiHash is empty');
      return;
    }

    // Check if running on simulator
    if (await _isRunningOnSimulator()) {
      AppLogger.info('ℹ️ Skipping FCM token submission on simulator');
      return;
    }

    try {
      // For iOS, wait for APNS token to be available
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }

      // Get token with retry mechanism
      final token = await _getFcmTokenWithRetry();

      if (token == null || token.isEmpty) {
        AppLogger.warning('FCM token is null or empty, skipping submission');
        return;
      }

      // Submit token with retry mechanism
      await _submitWithRetry(apiHash, token, retryOnFailure);

      AppLogger.success('FCM token submitted successfully: ${_maskToken(token)}');

    } catch (e) {
      AppLogger.error('FCM token submission failed', e);
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Check if running on iOS simulator
  Future<bool> _isRunningOnSimulator() async {
    // Return cached value if available
    if (_isSimulator != null) {
      return _isSimulator!;
    }

    try {
      // Check if running on iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // For iOS, check if it's a simulator
        // On iOS, we can check using Platform.isIOS and some runtime checks
        // A simpler approach: try to get APNS token with a short timeout
        try {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken()
              .timeout(const Duration(seconds: 2));

          if (apnsToken != null && apnsToken.isNotEmpty) {
            // Got APNS token, likely a real device
            _isSimulator = false;
            AppLogger.info('✅ Detected real iOS device');
            return false;
          }
        } catch (e) {
          // If APNS token fails, it might be a simulator
          if (e.toString().contains('apns-token-not-set')) {
            // Check if it's a simulator by trying to get device info
            // We'll use a heuristic: simulator often has specific behavior
            _isSimulator = await _detectSimulatorByHeuristics();
            if (_isSimulator!) {
              AppLogger.info('📱 Detected iOS simulator');
            }
            return _isSimulator!;
          }
        }
      }

      // For Android or other platforms
      _isSimulator = false;
      return false;

    } catch (e) {
      AppLogger.warning('Error detecting simulator: $e');
      _isSimulator = false;
      return false;
    }
  }

  /// Detect simulator using various heuristics
  Future<bool> _detectSimulatorByHeuristics() async {
    try {
      // Try multiple approaches to detect simulator

      // Approach 1: Check if we can get APNS token quickly
      try {
        final token = await FirebaseMessaging.instance.getToken()
            .timeout(const Duration(seconds: 3));
        if (token != null && token.isNotEmpty) {
          // Got token, not simulator
          return false;
        }
      } catch (_) {
        // Likely simulator
      }

      // Approach 2: Check if APNS token is available
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken()
            .timeout(const Duration(seconds: 3));
        if (apnsToken != null && apnsToken.isNotEmpty) {
          return false;
        }
      } catch (e) {
        // APNS token not available, likely simulator
        if (e.toString().contains('apns-token-not-set')) {
          AppLogger.info('APNS token not available (simulator detected)');
          return true;
        }
      }

      // If we can't determine, assume it's a real device for safety
      return false;

    } catch (_) {
      return false;
    }
  }


  /// Wait for APNS token to be available (iOS only) - NON-BLOCKING
  Future<void> _waitForApnsToken() async {
    // Skip if simulator
    if (await _isRunningOnSimulator()) {
      AppLogger.info('⏭️ Skipping APNS token wait on simulator');
      return;
    }

    AppLogger.info('Waiting for APNS token...');

    int attempts = 0;
    const maxAttempts = 30; // 30 seconds max wait

    while (attempts < maxAttempts) {
      try {
        // Check if APNS token is available
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

        if (apnsToken != null && apnsToken.isNotEmpty) {
          AppLogger.success('APNS token received: ${apnsToken.substring(0, 10)}...');
          return;
        }
      } catch (e) {
        // APNS token not ready yet
        if (e.toString().contains('apns-token-not-set')) {
          if (attempts % 5 == 0) {
            AppLogger.info('APNS token not ready yet, waiting... (${attempts + 1}/$maxAttempts)');
          }
        } else {
          AppLogger.warning('Error checking APNS token: $e');
        }
      }

      attempts++;
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    AppLogger.warning('APNS token still not available after ${maxAttempts}s, proceeding anyway');
  }

  /// Get FCM token with retry mechanism (NON-BLOCKING)
  Future<String?> _getFcmTokenWithRetry() async {
    // Skip if simulator
    if (await _isRunningOnSimulator()) {
      AppLogger.info('⏭️ Skipping FCM token retrieval on simulator');
      return null;
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        final token = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            AppLogger.warning('FCM token retrieval timeout');
            return null;
          },
        );

        if (token != null && token.isNotEmpty) {
          return token;
        }

        AppLogger.warning('FCM token is empty, retrying...');
      } catch (e) {
        lastException = e as Exception?;
        // If it's APNS error on iOS, wait a bit longer
        if (defaultTargetPlatform == TargetPlatform.iOS &&
            e.toString().contains('apns-token-not-set')) {
          AppLogger.info('APNS token still not set, waiting 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          AppLogger.warning('Error getting FCM token: $e');
        }
      }

      attempts++;
      if (attempts < _maxRetries) {
        await Future.delayed(_retryDelay * attempts);
      }
    }

    if (lastException != null) {
      AppLogger.error('Failed to get FCM token after $_maxRetries attempts', lastException);
    }
    return null;
  }

  /// Submit with retry logic (NON-BLOCKING)
  Future<void> _submitWithRetry(String apiHash, String token, bool retryOnFailure) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        await _fcmRepo.fcmTokenSubmissionApi(apiHash, token);
        return; // Success
      } catch (e) {
        lastException = e as Exception?;
        attempts++;

        if (attempts < _maxRetries && retryOnFailure) {
          AppLogger.info('Retry $attempts/$_maxRetries for FCM token submission');
          await Future.delayed(_retryDelay * attempts);
        }
      }
    }

    // All retries failed
    if (lastException != null) {
      throw lastException;
    }
  }

  /// Delete FCM token (for logout) - NON-BLOCKING
  Future<void> deleteToken() async {
    try {
      // Skip if simulator
      if (await _isRunningOnSimulator()) {
        AppLogger.info('⏭️ Skipping FCM token deletion on simulator');
        return;
      }

      await FirebaseMessaging.instance.deleteToken();
      AppLogger.info('FCM token deleted successfully');
    } catch (e) {
      AppLogger.warning('Failed to delete FCM token: $e');
    }
  }

  /// Mask token for logging
  String _maskToken(String token) {
    if (token.length <= 12) return token;
    return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
  }

  /// Check if token is valid and active
  Future<bool> isTokenValid() async {
    try {
      // Skip if simulator
      if (await _isRunningOnSimulator()) {
        return false;
      }

      final token = await FirebaseMessaging.instance.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get token for manual use
  Future<String?> getToken() async {
    try {
      // Skip if simulator
      if (await _isRunningOnSimulator()) {
        AppLogger.info('⏭️ Skipping FCM token retrieval on simulator');
        return null;
      }

      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      AppLogger.error('Error getting FCM token', e);
      return null;
    }
  }
}