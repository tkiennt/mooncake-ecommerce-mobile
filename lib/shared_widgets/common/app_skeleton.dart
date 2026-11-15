import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class AppSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const AppSkeleton.circle({
    super.key,
    required double radius,
  })  : width = radius * 2,
        height = radius * 2,
        borderRadius = null,
        shape = BoxShape.circle;

  const AppSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14.0,
    this.borderRadius,
  }) : shape = BoxShape.rectangle;

  /// Shimmer wrapper với tông vàng ngà ấm áp hoàng gia
  static Widget shimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }

  /// Khung xương cho thẻ sản phẩm tương thích AppProductCard
  static Widget productCard() {
    return shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image frame 1:1
            const AspectRatio(
              aspectRatio: 1.0,
              child: ColoredBox(color: AppColors.shimmerBase),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title line 1 & 2
                  AppSkeleton.text(width: 130, height: 13),
                  const SizedBox(height: 6),
                  AppSkeleton.text(width: 90, height: 13),
                  const SizedBox(height: 10),
                  // Price line
                  Row(
                    children: [
                      const AppSkeleton(width: 80, height: 16),
                      const Spacer(),
                      AppSkeleton.text(width: 40, height: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // B2B wholesale / MOQ info line
                  const AppSkeleton.text(width: 100, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lưới khung xương sản phẩm 2 cột
  static Widget productGrid({int count = 4}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: count,
      itemBuilder: (_, __) => productCard(),
    );
  }

  /// Khung xương cho item dạng danh sách (list tile)
  static Widget listTile() {
    return shimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceMD,
        ),
        child: Row(
          children: [
            const AppSkeleton(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput)),
            ),
            const SizedBox(width: AppTokens.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.text(width: 160, height: 14),
                  const SizedBox(height: 8),
                  AppSkeleton.text(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Khung xương cho thẻ Đơn hàng / Báo giá RFQ / Hợp đồng
  static Widget orderCard() {
    return shimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceSM,
        ),
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSkeleton.text(width: 110, height: 14),
                const AppSkeleton(
                  width: 80,
                  height: 22,
                  borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusSM)),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.border),
            Row(
              children: [
                const AppSkeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusSM)),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton.text(width: 140, height: 13),
                      const SizedBox(height: 6),
                      AppSkeleton.text(width: 80, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? BorderRadius.circular(AppTokens.radiusSM)),
        ),
      ),
    );
  }
}
