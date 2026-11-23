import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class AppColors {
  // ==================== PRIMARY COLORS ====================
  static const Color primary = Color(0xFFE63946);
  static const Color primaryLight = Color(0xFFFF6B6B);
  static const Color primaryDark = Color(0xFFC62828);

  // ==================== SECONDARY COLORS ====================
  static const Color secondary = Color(0xFF2B2D42);
  static const Color secondaryLight = Color(0xFF4A4D6E);

  // ==================== SURFACE COLORS ====================
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFFF5F5F5);
  static const Color surfaceDarker = Color(0xFFEEEEEE);

  // ==================== TEXT COLORS ====================
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);

  // ==================== STATUS COLORS ====================
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ==================== VEHICLE STATUS COLORS ====================
  static const Color statusRunning = Color(0xFF22C55E);
  static const Color statusStopped = Color(0xFFEF4444);
  static const Color statusIdle = Color(0xFFF59E0B);
  static const Color statusOffline = Color(0xFF3B82F6);
  static const Color statusNoData = Color(0xFF9CA3AF);
  static const Color statusExpired = Color(0xFFDC2626);

  // ==================== BORDER & INPUT ====================
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBackground = Color(0xFFF9FAFB);

  // ==================== LEGACY SUPPORT ====================
  static const Color buttonColor = Color(0xFFE63946);
  static const Color appBarColor = surface;
  static const Color backgroundColor = surface;
  static const Color cardBackground = surface;

  // ==================== GRADIENTS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  // ==================== BACKGROUND DECORATIONS ====================
  static const Decoration appScreenBackgroundImage = BoxDecoration(
    color: surface,
  );

  // ==================== BORDER RADIUS ====================
  static RoundedRectangleBorder cardBorderShape =
  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

  static const BorderRadius popupmenuborder = BorderRadius.all(Radius.circular(12));

  // ✅ Increased radius to make it smoother (was 8)
  static const BorderRadius StatusDshboardBarborderRadius = BorderRadius.all(Radius.circular(12));

  static const BorderRadius statusDashboardBorderRadius = BorderRadius.all(Radius.circular(12));

  // ==================== SHADOWS ====================
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 15,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> alertShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ==================== TEXT STYLES ====================
  static const TextStyle appTitleTextStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: onSurface,
  );

  static const TextStyle settingTextstyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );

  static const TextStyle settingPageButtonTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  // ==================== GF TYPOGRAPHY ====================
  static const GFTypographyType deviceOnMapSligePanelHeading =
      GFTypographyType.typo5;

  // ==================== STRING CONSTANTS ====================
  static const String logoPath = 'assets/images/company_logo.png';
  static const String errorMessage =
      'trying to load data. Please check internet connection';
}