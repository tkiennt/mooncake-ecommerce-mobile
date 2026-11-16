import 'package:flutter_test/flutter_test.dart';
import 'package:mooncake_mobile/core/theme/app_colors.dart';
import 'package:mooncake_mobile/core/theme/app_theme.dart';

void main() {
  group('AppTheme & AppColors Tests', () {
    test('AppColors brand primary & accent are defined correctly', () {
      expect(AppColors.primary.value, 0xFF8C1524);
      expect(AppColors.accent.value, 0xFFD48806);
      expect(AppColors.background.value, 0xFFFDFBF7);
    });

    test('AppTheme returns a valid ThemeData object', () {
      final theme = AppTheme.lightTheme;
      expect(theme.primaryColor, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });
  });
}
