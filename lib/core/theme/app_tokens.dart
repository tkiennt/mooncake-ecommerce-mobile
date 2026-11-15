import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Nguyệt Phố B2B - Unified Design Tokens
/// Tái tạo Ant Design v5 Tokens và Lucian UX/UI Micro-tokens
class AppTokens {
  // Spacing Scale
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double space2XL = 24.0;
  static const double space3XL = 32.0;

  // Standard Border Radii (Chuẩn hóa 3 nấc mục 3 benchmark)
  static const double radiusCard = 12.0;
  static const double radiusInput = 8.0;
  static const double radiusPill = 999.0;

  // Border Radii (Ant Design & Legacy)
  static const double radiusXS = 2.0;
  static const double radiusSM = 4.0;
  static const double radiusDefault = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;

  // Border Radii (Lucian UX/UI)
  static const double lucianRadiusSm = 6.0;
  static const double lucianRadiusMd = 10.0;
  static const double lucianRadiusLg = 14.0;
  static const double lucianRadiusXl = 20.0;
  static const double lucianRadiusPill = 999.0;

  // Minimum Tap Target (Apple & Material HIG / Benchmark P0)
  static const double minTapTarget = 44.0;

  // Box Shadows
  static const List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Color(0x0F1F1F1F), // 6% black
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x148C1524), // 8% crimson
      offset: Offset(0, 4),
      blurRadius: 10,
    ),
  ];

  static const List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: Color(0x1F1F1F1F), // 12% black
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  // Elevation Tokens
  static const List<BoxShadow> elevationSubtle = shadowSubtle;
  static const List<BoxShadow> elevationCard = shadowCard;
  static const List<BoxShadow> elevationSticky = [
    BoxShadow(
      color: Color(0x141F1F1F), // 8% black
      offset: Offset(0, -3),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowGold = [
    BoxShadow(
      color: AppColors.glowGold,
      offset: Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> glowCrimson = [
    BoxShadow(
      color: AppColors.glowCrimson,
      offset: Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  // Type Scale (Roboto/VN)
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22.0,
    height: 28.0 / 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    height: 22.0 / 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14.0,
    height: 20.0 / 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11.0,
    height: 14.0 / 11.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}
