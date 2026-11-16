import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/product.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/app_section_header.dart';
import '../../shared_widgets/common/app_price_tag.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/app_product_card.dart';
import '../../shared_widgets/common/quantity_b2b_stepper.dart';
import '../../shared_widgets/common/milestone_timeline.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/sticky_bottom_bar.dart';
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
  int _stepperQty = 50;

  final Product _sampleProductWithTier = Product(
    id: 'demo-p1',
    name: 'Hộp Quà Thập Cẩm Gà Quay Vi Cá Hoàng Gia (4 Bánh)',
    basePrice: 450000,
    soldCount: 1280,
    minOrderQty: 10,
    rating: 4.9,
    shopVerified: true,
    isCustomPackagingSupported: true,
    tierPricing: [
      TierPricing(minQty: 50, discountPercent: 20),
      TierPricing(minQty: 200, discountPercent: 35),
    ],
  );

  final Product _sampleProductRegular = Product(
    id: 'demo-p2',
    name: 'Bánh Nướng Đậu Xanh Hạt Sen 1 Trứng 150g',
    basePrice: 95000,
    soldCount: 350,
    minOrderQty: 1,
    rating: 4.6,
    shopVerified: false,
    isCustomPackagingSupported: false,
    tierPricing: const [],
  );

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
        title: 'UI Showcase · Shared Widgets',
        showBack: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro Card
            Container(
              margin: const EdgeInsets.all(AppTokens.spaceLG),
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hệ Thống Component & Token B2B Hoàng Gia',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bộ 10 widget dùng chung chuẩn hóa theo nhận diện Nguyệt Phố: Đỏ son (#8C1524), Vàng Gold (#D48806) và Nền giấy lụa ngà (#FDFBF7).',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
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

            // 1. AppSectionHeader
            _buildSectionHeader('1. AppSectionHeader (Tiêu đề mục + Gạch nhấn vàng)'),
            AppSectionHeader(
              title: 'Sản phẩm B2B bán chạy',
              subtitle: 'Chiết khấu xưởng từ 50 hộp trở lên',
              onAction: () {},
              actionLabel: 'Xem tất cả',
            ),

            // 2. AppPriceTag
            _buildSectionHeader('2. AppPriceTag (Định dạng VNĐ & Khoảng giá sỉ)'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppPriceTag(price: 150000, size: AppPriceTagSize.small),
                  AppPriceTag(price: 250000, originalPrice: 320000, size: AppPriceTagSize.medium),
                  AppPriceTag(price: 120000, maxPrice: 180000, size: AppPriceTagSize.medium),
                  AppPriceTag(price: 1850000, size: AppPriceTagSize.large),
                ],
              ),
            ),

            // 3. AppStatusChip
            _buildSectionHeader('3. AppStatusChip (5 trạng thái chuẩn hóa: Cam, Xanh dương, Tím, Xanh lá, Đỏ)'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppStatusChip(status: 'pending', type: AppStatusType.order),
                  AppStatusChip(status: 'in_production', type: AppStatusType.order),
                  AppStatusChip(status: 'shipping', type: AppStatusType.order),
                  AppStatusChip(status: 'completed', type: AppStatusType.order),
                  AppStatusChip(status: 'cancelled', type: AppStatusType.order),
                  AppStatusChip(status: 'OpenForBidding', type: AppStatusType.rfq),
                  AppStatusChip(status: 'PendingSignature', type: AppStatusType.contract),
                  AppStatusChip(status: 'Disputed', type: AppStatusType.contract),
                ],
              ),
            ),

            // 4. QuantityB2BStepper
            _buildSectionHeader('4. QuantityB2BStepper (Nút +/- + Mốc sỉ 50/100/200/500 + Nhập tự do D14)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: QuantityB2BStepper(
                value: _stepperQty,
                onChanged: (val) => setState(() => _stepperQty = val),
              ),
            ),

            // 5. AppProductCard (D15: Tag giá sỉ chỉ khi có tierPricing)
            _buildSectionHeader('5. AppProductCard (D15: Tag sỉ khi có tier & Thẻ thường không bịa số)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppProductCard(
                      product: _sampleProductWithTier,
                      onPress: (p) {},
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),
                  Expanded(
                    child: AppProductCard(
                      product: _sampleProductRegular,
                      onPress: (p) {},
                    ),
                  ),
                ],
              ),
            ),

            // 6. MilestoneTimeline
            _buildSectionHeader('6. MilestoneTimeline (Tiến độ đơn hàng / Hợp đồng / PoD)'),
            const MilestoneTimeline(
              orientation: Axis.horizontal,
              items: [
                MilestoneItem(
                  title: 'Đặt cọc 30%',
                  timestamp: '09:30 15/07',
                  status: MilestoneStepStatus.completed,
                ),
                MilestoneItem(
                  title: 'Sản xuất',
                  timestamp: '11:00 16/07',
                  status: MilestoneStepStatus.current,
                ),
                MilestoneItem(
                  title: 'Giao xe lạnh',
                  status: MilestoneStepStatus.upcoming,
                ),
                MilestoneItem(
                  title: 'Ký nhận PoD',
                  status: MilestoneStepStatus.upcoming,
                ),
              ],
            ),

            // 7. AppSkeleton
            _buildSectionHeader('7. AppSkeleton (Shimmer tông vàng ngà ấm áp)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: AppSkeleton.orderCard(),
            ),

            // 8. AppEmptyState
            _buildSectionHeader('8. AppEmptyState (Giao diện rỗng tiếng Việt + CTA)'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: AppEmptyState(
                title: 'Chưa có yêu cầu báo giá nào',
                message: 'Hãy gửi yêu cầu báo giá (RFQ) để nhận bảng giá sỉ cạnh tranh từ các xưởng uy tín.',
                actionLabel: 'Tạo RFQ mới',
                onAction: () {},
              ),
            ),

            // 9. AppErrorState
            _buildSectionHeader('9. AppErrorState (Thông báo lỗi kết nối + Nút thử lại D11)'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: AppErrorState(
                title: 'Không thể tải danh sách sản phẩm',
                message: 'Kết nối mạng bị gián đoạn. Vui lòng kiểm tra lại đường truyền internet.',
                retryLabel: 'Thử lại ngay',
                onRetry: () {},
              ),
            ),

            // 10. StickyBottomBar Demo
            _buildSectionHeader('10. StickyBottomBar (Đổ bóng ngược + Tóm tắt giá + SafeArea)'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
              child: StickyBottomBar(
                totalLabel: 'Tổng tạm tính (50 hộp)',
                totalAmount: 18000000,
                subtitle: 'Đã áp dụng chiết khấu sỉ 20%',
                primaryButtonTitle: 'Xác nhận đặt hàng',
                onPrimaryPressed: () {},
              ),
            ),

            // Ant Design & Lucian Reference Widgets
            const Divider(height: 48, thickness: 1, color: AppColors.border),
            _buildSectionHeader('Phần mở rộng: Lucian & Ant Design micro-interactions'),
            const AnnouncementPill(),
            const TrustSecurityBadges(),
            TearOffCoupon(
              onApply: (code) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mã coupon $code đã kích hoạt!')),
                );
              },
            ),
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
            ReviewFilterStars(
              selectedStar: _selectedStar,
              onSelectStar: (star) => setState(() => _selectedStar = star),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: 8),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: 8),
              child: AntdOtpInput(
                onComplete: (otp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mã OTP hoàn tất: $otp')),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.spaceLG,
        top: AppTokens.spaceLG,
        bottom: AppTokens.spaceXS,
        right: AppTokens.spaceLG,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
