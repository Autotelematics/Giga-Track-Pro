import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/models/user_login_model.dart';
import 'package:trackerapp/utils/logger.dart';

class UserLoginProvider with ChangeNotifier {
  String? _userApiHash;
  String? _userId;
  String? _status;
  bool _alertSounds = true;
  double _fuelPrice = 259.0;
  bool _isLoading = false;

  // Permissions map
  Map<String, Map<String, bool>> _permissions = {};

  // Getters
  String? get userApiHash => _userApiHash;
  String? get userId => _userId;
  String? get status => _status;
  bool get alertSounds => _alertSounds;
  double get fuelPrice => _fuelPrice;
  bool get isLoading => _isLoading;
  Map<String, Map<String, bool>> get permissions => _permissions;

  // Helper methods to check specific permissions
  bool hasPermission(String category, String action) {
    return _permissions[category]?[action] ?? false;
  }

  bool canView(String category) => hasPermission(category, 'view');
  bool canEdit(String category) => hasPermission(category, 'edit');
  bool canRemove(String category) => hasPermission(category, 'remove');

  Future<bool> saveUserSession(
      UserLoginData user,
      String userID, {
        Map<String, dynamic>? permissions,
      })
  async {
    try {
      _setLoading(true);

      final SharedPreferences sp = await SharedPreferences.getInstance();

      await sp.setString('status', user.status.toString());
      await sp.setString('userid', userID);
      await sp.setString('userApiHash', user.userApiHash.toString());

      _userId = userID;
      _status = user.status.toString();
      _userApiHash = user.userApiHash.toString();

      // ✅ Save permissions if provided
      if (permissions != null && permissions.isNotEmpty) {
        AppLogger.info('📝 Saving permissions: $permissions');

        // 🔍 Print all permissions in detail
        _printAllPermissions(permissions);

        await _savePermissions(sp, permissions);
      } else {
        AppLogger.warning('⚠️ No permissions provided to save');
      }

      if (sp.getBool('playAlertSounds') == null) {
        await sp.setBool('playAlertSounds', true);
        _alertSounds = true;
      } else {
        _alertSounds = sp.getBool('playAlertSounds') ?? true;
      }

      if (sp.getDouble('fuelPrice') == null) {
        await sp.setDouble('fuelPrice', 259.0);
        _fuelPrice = 259.0;
      } else {
        _fuelPrice = sp.getDouble('fuelPrice') ?? 259.0;
      }

      _notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user session: $e');
      }
      _setLoading(false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 🔍 Print all permissions in detail
  void _printAllPermissions(Map<String, dynamic> permissions) {
    print('═══════════════════════════════════════════════════');
    print('📋 ALL PERMISSIONS DATA');
    print('═══════════════════════════════════════════════════');

    if (permissions.isEmpty) {
      print('⚠️ No permissions found');
      return;
    }

    // Print total number of permission categories
    print('📊 Total Categories: ${permissions.length}');
    print('───────────────────────────────────────────────────');

    // Iterate through each category
    permissions.forEach((category, value) {
      print('📁 Category: $category');

      if (value is Map) {
        // Print each permission action
        print('   ┌─────────────────────────────────────────────');

        // Count total permissions in this category
        int totalActions = value.length;
        print('   │ Total Actions: $totalActions');

        // Print each action with its value
        value.forEach((action, permissionValue) {
          String statusIcon = permissionValue == true ? '✅' : '❌';
          String statusText = permissionValue == true ? 'ALLOWED' : 'DENIED';
          print('   │ $statusIcon $action: $statusText');
        });

        print('   └─────────────────────────────────────────────');
      } else {
        print('   ⚠️ Invalid permission format for category: $category');
      }
      print('');
    });

    print('═══════════════════════════════════════════════════');

    // 🔍 Print summary of permissions
    _printPermissionsSummary(permissions);
  }

  // 📊 Print summary of permissions
  void _printPermissionsSummary(Map<String, dynamic> permissions) {
    print('📊 PERMISSIONS SUMMARY');
    print('───────────────────────────────────────────────────');

    int totalCategories = permissions.length;
    int totalPermissions = 0;
    int allowedPermissions = 0;
    int deniedPermissions = 0;

    List<String> fullyAllowed = [];
    List<String> partiallyAllowed = [];
    List<String> fullyDenied = [];

    permissions.forEach((category, value) {
      if (value is Map) {
        int categoryTotal = value.length;
        int categoryAllowed = 0;
        int categoryDenied = 0;

        value.forEach((action, permissionValue) {
          totalPermissions++;
          if (permissionValue == true) {
            categoryAllowed++;
            allowedPermissions++;
          } else {
            categoryDenied++;
            deniedPermissions++;
          }
        });

        // Categorize the permission level
        if (categoryAllowed == categoryTotal && categoryTotal > 0) {
          fullyAllowed.add(category);
        } else if (categoryDenied == categoryTotal && categoryTotal > 0) {
          fullyDenied.add(category);
        } else {
          partiallyAllowed.add(category);
        }
      }
    });

    print('📌 Total Categories: $totalCategories');
    print('📌 Total Permissions: $totalPermissions');
    print('📌 Allowed: $allowedPermissions');
    print('📌 Denied: $deniedPermissions');
    print('');

    if (fullyAllowed.isNotEmpty) {
      print('✅ FULLY ALLOWED Categories:');
      fullyAllowed.forEach((category) {
        print('   • $category');
      });
      print('');
    }

    if (partiallyAllowed.isNotEmpty) {
      print('⚠️ PARTIALLY ALLOWED Categories:');
      partiallyAllowed.forEach((category) {
        print('   • $category');
      });
      print('');
    }

    if (fullyDenied.isNotEmpty) {
      print('❌ FULLY DENIED Categories:');
      fullyDenied.forEach((category) {
        print('   • $category');
      });
      print('');
    }

    print('───────────────────────────────────────────────────');

    // 🔍 Print specific permission checks
    _printSpecificPermissionChecks(permissions);
  }

  // 🎯 Print specific important permissions
  void _printSpecificPermissionChecks(Map<String, dynamic> permissions) {
    print('🎯 IMPORTANT PERMISSION CHECKS');
    print('───────────────────────────────────────────────────');

    // List of important categories to check
    List<String> importantCategories = [
      'devices',
      'alerts',
      'geofences',
      'routes',
      'drivers',
      'reports',
      'history',
      'send_command',
      'maintenance',
      'camera',
      'tasks',
      'chat'
    ];

    importantCategories.forEach((category) {
      if (permissions.containsKey(category)) {
        var value = permissions[category];
        if (value is Map) {
          bool canView = value['view'] ?? false;
          bool canEdit = value['edit'] ?? false;
          bool canRemove = value['remove'] ?? false;

          print('📌 $category:');
          print('   👁️ View: ${canView ? "✅" : "❌"}');
          print('   ✏️ Edit: ${canEdit ? "✅" : "❌"}');
          print('   🗑️ Remove: ${canRemove ? "✅" : "❌"}');

          // Determine access level
          if (canView && canEdit && canRemove) {
            print('   🔓 FULL ACCESS');
          } else if (canView && !canEdit && !canRemove) {
            print('   👁️ VIEW ONLY');
          } else if (!canView && !canEdit && !canRemove) {
            print('   🔒 NO ACCESS');
          } else {
            print('   🔐 PARTIAL ACCESS');
          }
          print('');
        }
      } else {
        print('❌ $category: NOT FOUND');
        print('');
      }
    });

    print('═══════════════════════════════════════════════════');
  }

  // Save permissions to SharedPreferences
  Future<void> _savePermissions(
      SharedPreferences sp,
      Map<String, dynamic> permissionsData,
      ) async {
    try {
      AppLogger.info('🔄 Processing permissions...');

      // Convert permissions to a map of maps
      Map<String, Map<String, bool>> processedPermissions = {};

      permissionsData.forEach((category, value) {
        if (value is Map) {
          Map<String, bool> actions = {};
          value.forEach((action, permissionValue) {
            if (permissionValue is bool) {
              actions[action.toString()] = permissionValue;
            }
          });
          processedPermissions[category] = actions;
        }
      });

      _permissions = processedPermissions;

      // Save to SharedPreferences as string
      String permissionsString = _permissionsToString(processedPermissions);
      await sp.setString('permissions', permissionsString);

      AppLogger.success('✅ Permissions saved successfully');
      AppLogger.info('📋 Saved permissions string: $permissionsString');
      AppLogger.info('📋 Processed permissions: $processedPermissions');

      // 🔍 Verify the saved data
      String? verifyString = sp.getString('permissions');
      AppLogger.info('🔍 Verification - Retrieved from storage: $verifyString');

    } catch (e) {
      AppLogger.error('❌ Error saving permissions', e);
    }
  }

  // Convert permissions map to string for storage
  String _permissionsToString(Map<String, Map<String, bool>> permissions) {
    List<String> entries = [];
    permissions.forEach((category, actions) {
      List<String> actionStrings = [];
      actions.forEach((action, value) {
        actionStrings.add('$action:$value');
      });
      entries.add('$category:${actionStrings.join(',')}');
    });
    return entries.join('|');
  }

  // Parse permissions from string
  Map<String, Map<String, bool>> _stringToPermissions(String permissionsString) {
    Map<String, Map<String, bool>> result = {};

    if (permissionsString.isEmpty) return result;

    List<String> categoryEntries = permissionsString.split('|');
    for (String entry in categoryEntries) {
      List<String> parts = entry.split(':');
      if (parts.length == 2) {
        String category = parts[0];
        List<String> actionStrings = parts[1].split(',');
        Map<String, bool> actions = {};
        for (String actionString in actionStrings) {
          List<String> actionParts = actionString.split(':');
          if (actionParts.length == 2) {
            actions[actionParts[0]] = actionParts[1] == 'true';
          }
        }
        result[category] = actions;
      }
    }

    return result;
  }

  Future<UserLoginData> getUserApiHash() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? userApiHash = sp.getString('userApiHash');

      _userApiHash = userApiHash;
      _notifyListeners();

      return UserLoginData(userApiHash: userApiHash);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user API hash: $e');
      }
      return UserLoginData(userApiHash: null);
    }
  }

  Future<void> clearSessionOnly() async {
    try {
      AppLogger.info('🧹 Clearing session only...');

      final SharedPreferences sp = await SharedPreferences.getInstance();

      // Clear specific keys
      await sp.remove('userApiHash');
      await sp.remove('userid');
      await sp.remove('status');
      await sp.remove('permissions'); // Clear permissions too

      // Reset state immediately
      _userApiHash = null;
      _userId = null;
      _status = null;
      _alertSounds = true;
      _fuelPrice = 259.0;
      _permissions = {}; // Reset permissions

      _notifyListeners();

      // Delete FCM token in background (don't wait)
      FirebaseMessaging.instance.deleteToken().then((_) {
        AppLogger.info('FCM token deleted in background');
      }).catchError((e) {
        AppLogger.warning('FCM token deletion in background failed: $e');
      });

      AppLogger.success('Session cleared successfully');
    } catch (e) {
      AppLogger.error('Error clearing session', e);
    }
  }

  Future<String> getUserApiHashString() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final String? userApiHash = sp.getString('userApiHash');

      _userApiHash = userApiHash;
      _notifyListeners();

      return userApiHash ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user API hash string: $e');
      }
      return '';
    }
  }

  Future<void> loadUserData() async {
    try {
      _setLoading(true);

      final SharedPreferences sp = await SharedPreferences.getInstance();

      _userApiHash = sp.getString('userApiHash');
      _userId = sp.getString('userid');
      _status = sp.getString('status');
      _alertSounds = sp.getBool('playAlertSounds') ?? true;
      _fuelPrice = sp.getDouble('fuelPrice') ?? 259.0;

      // Load permissions
      String? permissionsString = sp.getString('permissions');
      if (permissionsString != null && permissionsString.isNotEmpty) {
        _permissions = _stringToPermissions(permissionsString);
        AppLogger.info('📋 Loaded permissions: $_permissions');

        // 🔍 Print loaded permissions for debugging
        print('═══════════════════════════════════════════════════');
        print('📋 LOADED PERMISSIONS FROM STORAGE');
        print('═══════════════════════════════════════════════════');
        _printLoadedPermissions(_permissions);
      } else {
        _permissions = {};
        AppLogger.warning('⚠️ No permissions found in storage');
      }

      _notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 🔍 Print loaded permissions
  void _printLoadedPermissions(Map<String, Map<String, bool>> permissions) {
    if (permissions.isEmpty) {
      print('⚠️ No permissions loaded');
      return;
    }

    print('📊 Total Categories: ${permissions.length}');
    print('───────────────────────────────────────────────────');

    permissions.forEach((category, actions) {
      print('📁 $category:');
      actions.forEach((action, value) {
        String statusIcon = value ? '✅' : '❌';
        print('   $statusIcon $action: ${value ? "ALLOWED" : "DENIED"}');
      });
      print('');
    });

    print('═══════════════════════════════════════════════════');
  }

  Future<void> updateAlertSounds(bool value) async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool('playAlertSounds', value);

      _alertSounds = value;
      _notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating alert sounds: $e');
      }
    }
  }

  Future<void> updateFuelPrice(double price) async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setDouble('fuelPrice', price);

      _fuelPrice = price;
      _notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating fuel price: $e');
      }
    }
  }

  Future<bool> userSessionRemove() async {
    try {
      final sp = await SharedPreferences.getInstance();

      // Clear memory
      _userApiHash = null;
      _userId = null;
      _status = null;
      _alertSounds = true;
      _fuelPrice = 259.0;
      _permissions = {}; // Reset permissions

      // Remove preferences
      await Future.wait([
        sp.remove('userApiHash'),
        sp.remove('userid'),
        sp.remove('status'),
        sp.remove('permissions'), // Remove permissions
      ]);

      notifyListeners();

      // Delete FCM token in background
      FirebaseMessaging.instance.deleteToken().catchError((e) {
        if (kDebugMode) {
          print('Delete token error: $e');
        }
      });

      AppLogger.success('User session removed successfully');

      return true;
    } catch (e) {
      AppLogger.error('Error removing user session', e);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  bool get isUserLoggedIn => _userApiHash != null && _userApiHash!.isNotEmpty;

  Future<void> clearAllData() async {
    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.clear();

      _userApiHash = null;
      _userId = null;
      _status = null;
      _alertSounds = true;
      _fuelPrice = 259.0;
      _permissions = {};

      _notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing data: $e');
      }
    }
  }

  // ✅ Public method to print current permissions (can be called from anywhere)
  void printCurrentPermissions() {
    print('═══════════════════════════════════════════════════');
    print('📋 CURRENT PERMISSIONS IN MEMORY');
    print('═══════════════════════════════════════════════════');

    if (_permissions.isEmpty) {
      print('⚠️ No permissions in memory');
      print('═══════════════════════════════════════════════════');
      return;
    }

    print('📊 Total Categories: ${_permissions.length}');
    print('───────────────────────────────────────────────────');

    _permissions.forEach((category, actions) {
      print('📁 $category:');
      actions.forEach((action, value) {
        String statusIcon = value ? '✅' : '❌';
        print('   $statusIcon $action: ${value ? "ALLOWED" : "DENIED"}');
      });
      print('');
    });

    print('═══════════════════════════════════════════════════');
  }

  // ✅ Get all permissions as a formatted string
  String getAllPermissionsAsString() {
    if (_permissions.isEmpty) {
      return 'No permissions available';
    }

    StringBuffer buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('📋 ALL PERMISSIONS');
    buffer.writeln('═══════════════════════════════════════════════════');

    _permissions.forEach((category, actions) {
      buffer.writeln('📁 $category:');
      actions.forEach((action, value) {
        String statusIcon = value ? '✅' : '❌';
        buffer.writeln('   $statusIcon $action: ${value ? "ALLOWED" : "DENIED"}');
      });
      buffer.writeln('');
    });

    buffer.writeln('═══════════════════════════════════════════════════');
    return buffer.toString();
  }
}