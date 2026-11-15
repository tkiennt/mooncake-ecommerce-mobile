import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/lucian/announcement_pill.dart';
import '../../shared_widgets/lucian/trust_security_badges.dart';
import '../../shared_widgets/lucian/tear_off_coupon.dart';
import '../../shared_widgets/lucian/b2b_price_calculator.dart';
import '../../shared_widgets/lucian/review_filter_stars.dart';
import '../../shared_widgets/antd/antd_steps.dart';
import '../../shared_widgets/antd/antd_otp_input.dart';
import 'dev_mode_sheet.dart';

class UiCatalogScreen extends StatefulWidget {
  const UiCatalogScreen({super.key});

  @override
  State<UiCatalogScreen> createState() => _UiCatalogScreenState();
}

class _UiCatalogScreenState extends State<UiCatalogScreen> {
  int _currentStep = 1;
  int? _selectedStar = 5;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: const AppHeader(
          title: 'UI Showcase',
          showBack: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'Chế độ xem UI Catalog chỉ khả dụng trong môi trường Debug (kDebugMode).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  title: 'Quay lại',
                  size: ButtonSize.small,
                  onPress: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppHeader(
        title: 'UI Showcase · AntD & Lucian',
        showBack: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hệ Thống Component Hoàng Gia B2B',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kết hợp chuẩn cấu trúc Ant Design với vi tương tác tinh tế của Lucian Labs. Bảo tồn 100% theme Crimson (#8C1524) & Imperial Gold (#D48806).',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    title: 'Mở Thanh Công Cụ Dev Mode',
                    icon: const Icon(Icons.developer_mode, size: 16, color: Colors.white),
                    size: ButtonSize.small,
                    onPress: () => showDevModeSheet(context),
                  ),
                ],
              ),
            ),

            // 1. Lucian Announcement Pill
            _buildSectionHeader('1. Lucian Announcement Pill (#012)'),
            const AnnouncementPill(),

            // 2. Lucian Trust Security Badges
            _buildSectionHeader('2. Lucian Trust Security Badges (#064)'),
            const TrustSecurityBadges(),

            // 3. Lucian Tear-Off Coupon
            _buildSectionHeader('3. Lucian Tear-Off Coupon (#088)'),
            TearOffCoupon(
              onApply: (code) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mã coupon $code đã kích hoạt!')),
                );
              },
            ),

            // 4. Lucian B2B Price Calculator
            _buildSectionHeader('4. Lucian B2B Price Calculator (#278)'),
            B2BPriceCalculator(
              onApplyTier: (result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã chọn ${result.quantity} hộp · Giảm ${result.effectiveDiscount.toInt()}%',
                    ),
                  ),
                );
              },
            ),

            // 5. Lucian Review Filter Stars
            _buildSectionHeader('5. Lucian Review Filter Stars (#182)'),
            ReviewFilterStars(
              selectedStar: _selectedStar,
              onSelectStar: (star) => setState(() => _selectedStar = star),
            ),

            // 6. Ant Design Steps
            _buildSectionHeader('6. Ant Design Steps Indicator'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AntdSteps(
                current: _currentStep,
                items: const [
                  StepItemData(title: 'Thiết lập', desc: 'Chọn mẫu & SL'),
                  StepItemData(title: 'Nhận bid', desc: 'So sánh báo giá'),
                  StepItemData(title: 'Ký HĐ', desc: 'Đặt cọc 30%'),
                ],
              ),
            ),
            Center(
              child: CustomButton(
                title: 'Bước kế tiếp',
                size: ButtonSize.small,
                variant: ButtonVariant.outline,
                onPress: () => setState(() => _currentStep = (_currentStep + 1) % 3),
              ),
            ),

            // 7. Ant Design OTP Input
            _buildSectionHeader('7. Ant Design OTP Input (6 số)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AntdOtpInput(
                onComplete: (otp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mã OTP hoàn tất: $otp')),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
