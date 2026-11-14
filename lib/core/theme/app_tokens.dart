import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Nguyệt Phố B2B - Unified Design Tokens
/// Tái tạo Ant Design v5 Tokens và Lucian UX/UI Micro-tokens
class AppTokens {
  // Border Radii (Ant Design)
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
}
