import 'package:flutter/material.dart';

/// Nguyệt Phố B2B - Design Tokens & Theme Colors
/// Đồng bộ 100% với Web Theme và React Native (Crimson Luxury & Warm Gold)
class AppColors {
  // Brand Primary
  static const Color primary = Color(0xFF8C1524); // Đỏ Crimson hoàng gia
  static const Color primaryDark = Color(0xFF5E0E18); // Đỏ sẫm
  static const Color primaryLight = Color(0xFFB82338); // Đỏ son sáng
  static const Color primaryTint = Color(0xFFFFF1F0); // Đỏ nhạt nền

  // Brand Accent (Imperial Gold)
  static const Color accent = Color(0xFFD48806); // Vàng Gold hoàng gia
  static const Color accentGoldLight = Color(0xFFFAAD14); // Vàng tươi
  static const Color accentGoldBg = Color(0xFFFFFBE6); // Vàng nhạt background

  // Neutrals & Backgrounds
  static const Color background = Color(0xFFFDFBF7); // Nền giấy lụa ngà
  static const Color surface = Color(0xFFFFFFFF); // Bề mặt thẻ trắng
  static const Color surfaceHover = Color(0xFFF7F4EC); // Bề mặt hover
  static const Color border = Color(0xFFE8E1D5); // Viền nhạt
  static const Color borderDark = Color(0xFFD3C7B5); // Viền đậm hơn

  // Text
  static const Color textPrimary = Color(0xFF1F1F1F); // Chữ chính đậm
  static const Color textSecondary = Color(0xFF6B6861); // Chữ phụ
  static const Color textMuted = Color(0xFF9E9A90); // Chữ mờ
  static const Color textWhite = Color(0xFFFFFFFF); // Chữ trắng

  // Semantic Status
  static const Color success = Color(0xFF389E0D); // Xanh lá hoàn thành
  static const Color successBg = Color(0xFFF6FFED);
  static const Color warning = Color(0xFFD46B08); // Cam cảnh báo
  static const Color warningBg = Color(0xFFFFF7E6);
  static const Color error = Color(0xFFCF1322); // Đỏ lỗi
  static const Color errorBg = Color(0xFFFFF1F0);
  static const Color info = Color(0xFF0958D9); // Xanh dương thông tin
  static const Color infoBg = Color(0xFFE6F4FF);

  // Shadows & Glows
  static const Color shadowColor = Color(0xFF1F1F1F);
  static const Color glowGold = Color(0x47D48806); // 28% opacity
  static const Color glowCrimson = Color(0x388C1524); // 22% opacity
}
