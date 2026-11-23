import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/providers/user_login_provider.dart';

class PermissionHelper {
  // ✅ Get permissions from anywhere
  static Map<String, Map<String, bool>> getPermissions(BuildContext context) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    return userLoginProvider.permissions;
  }

  // ✅ Check if user can view a specific category
  static bool canView(BuildContext context, String category) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    return userLoginProvider.canView(category);
  }

  // ✅ Check if user can edit a specific category
  static bool canEdit(BuildContext context, String category) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    return userLoginProvider.canEdit(category);
  }

  // ✅ Check if user can remove a specific category
  static bool canRemove(BuildContext context, String category) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    return userLoginProvider.canRemove(category);
  }

  // ✅ Check if user has a specific permission
  static bool hasPermission(BuildContext context, String category, String action) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    return userLoginProvider.hasPermission(category, action);
  }

  // ✅ Get permission level for a category (full, view-only, partial, none)
  static String getPermissionLevel(BuildContext context, String category) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);

    bool canView = userLoginProvider.canView(category);
    bool canEdit = userLoginProvider.canEdit(category);
    bool canRemove = userLoginProvider.canRemove(category);

    if (canView && canEdit && canRemove) {
      return 'FULL_ACCESS';
    } else if (canView && !canEdit && !canRemove) {
      return 'VIEW_ONLY';
    } else if (!canView && !canEdit && !canRemove) {
      return 'NO_ACCESS';
    } else {
      return 'PARTIAL_ACCESS';
    }
  }

  // ✅ Print all permissions from anywhere
  static void printAllPermissions(BuildContext context) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    userLoginProvider.printCurrentPermissions();
  }

  // ✅ Get all permissions as a string
  static String getAllPermissionsAsString(BuildContext context) {
    final userLoginProvider = Provider.of<UserLoginProvider>(context, listen: false);
    return userLoginProvider.getAllPermissionsAsString();
  }
}