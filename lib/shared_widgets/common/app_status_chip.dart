import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum AppStatusType {
  order,
  rfq,
  contract,
  delivery,
  general,
}

enum AppStatusChipSize {
  small,
  medium,
}

class AppStatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final IconData? icon;

  const AppStatusConfig({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.icon,
  });
}

class AppStatusChip extends StatelessWidget {
  final String status;
  final AppStatusType type;
  final String? customLabel;
  final AppStatusChipSize size;
  final bool showDot;
  final bool showBorder;
  final IconData? customIcon;

  const AppStatusChip({
    super.key,
    required this.status,
    this.type = AppStatusType.general,
    this.customLabel,
    this.size = AppStatusChipSize.medium,
    this.showDot = true,
    this.showBorder = true,
    this.customIcon,
  });

  static AppStatusConfig resolveConfig(String rawStatus, AppStatusType type) {
    final s = rawStatus.trim().toLowerCase();

    // 1. Chờ xử lý / Chờ xác nhận / Chờ ký / Chờ thanh toán -> Cam (Warning)
    if ([
      'pending',
      'created',
      'unpaid',
      'awaitingpayment',
      'awaiting_payment',
      'draft',
      'pendingsignature',
      'awaitingsignature',
      'readyforshipment',
      'ready_for_shipment',
      'open',
      'openforbidding',
      'open_for_bidding',
    ].contains(s)) {
      String label;
      switch (s) {
        case 'draft':
          label = 'Bản nháp';
          break;
        case 'pendingsignature':
        case 'awaitingsignature':
          label = 'Chờ ký số';
          break;
        case 'open':
        case 'openforbidding':
        case 'open_for_bidding':
          label = 'Đang nhận báo giá';
          break;
        case 'readyforshipment':
        case 'ready_for_shipment':
          label = 'Chờ lấy hàng';
          break;
        case 'unpaid':
        case 'awaitingpayment':
          label = 'Chờ thanh toán';
          break;
        default:
          label = type == AppStatusType.order ? 'Chờ xác nhận' : 'Chờ xử lý';
      }
      return AppStatusConfig(
        label: label,
        bgColor: AppColors.warningBg,
        textColor: AppColors.warning,
        borderColor: AppColors.warning.withValues(alpha: 0.35),
        icon: Icons.access_time_filled,
      );
    }

    // 2. Đang sản xuất / Đang xử lý / Đã xác nhận / Xét thầu -> Xanh dương (Info)
    if ([
      'processing',
      'in_production',
      'inproduction',
      'confirmed',
      'active',
      'signed',
      'underreview',
      'under_review',
    ].contains(s)) {
      String label;
      switch (s) {
        case 'confirmed':
          label = 'Đã xác nhận';
          break;
        case 'underreview':
        case 'under_review':
          label = 'Đang xét thầu';
          break;
        case 'active':
        case 'signed':
          label = 'Đang thực hiện';
          break;
        default:
          label = 'Đang sản xuất';
      }
      return AppStatusConfig(
        label: label,
        bgColor: AppColors.infoBg,
        textColor: AppColors.info,
        borderColor: AppColors.info.withValues(alpha: 0.35),
        icon: Icons.precision_manufacturing_outlined,
      );
    }

    // 3. Đang giao / Vận chuyển -> Tím (Purple)
    if ([
      'shipping',
      'shipped',
      'delivering',
      'intransit',
      'in_transit',
      'outfordelivery',
      'out_for_delivery',
    ].contains(s)) {
      return AppStatusConfig(
        label: 'Đang giao hàng',
        bgColor: AppColors.statusPurpleBg,
        textColor: AppColors.statusPurple,
        borderColor: AppColors.statusPurple.withValues(alpha: 0.35),
        icon: Icons.local_shipping_outlined,
      );
    }

    // 4. Hoàn thành / Đã giao / Đã chọn xưởng -> Xanh lá (Success)
    if ([
      'delivered',
      'completed',
      'success',
      'successful',
      'awarded',
      'paid',
    ].contains(s)) {
      String label;
      switch (s) {
        case 'delivered':
          label = 'Đã giao thành công';
          break;
        case 'awarded':
          label = 'Đã chọn xưởng';
          break;
        case 'paid':
          label = 'Đã thanh toán';
          break;
        default:
          label = 'Hoàn tất';
      }
      return AppStatusConfig(
        label: label,
        bgColor: AppColors.successBg,
        textColor: AppColors.success,
        borderColor: AppColors.success.withValues(alpha: 0.35),
        icon: Icons.check_circle_outline,
      );
    }

    // 5. Đã huỷ / Lỗi / Khiếu nại / Từ chối -> Đỏ (Error)
    if ([
      'cancelled',
      'canceled',
      'rejected',
      'expired',
      'failed',
      'disputed',
      'returned',
      'terminated',
    ].contains(s)) {
      String label;
      switch (s) {
        case 'disputed':
          label = 'Đang khiếu nại';
          break;
        case 'expired':
          label = 'Hết hạn';
          break;
        case 'failed':
          label = 'Giao thất bại';
          break;
        default:
          label = 'Đã hủy';
      }
      return AppStatusConfig(
        label: label,
        bgColor: AppColors.errorBg,
        textColor: AppColors.error,
        borderColor: AppColors.error.withValues(alpha: 0.35),
        icon: Icons.cancel_outlined,
      );
    }

    // Mặc định fallback
    return AppStatusConfig(
      label: rawStatus.isNotEmpty ? rawStatus : 'Chờ xử lý',
      bgColor: AppColors.surfaceHover,
      textColor: AppColors.textSecondary,
      borderColor: AppColors.border,
      icon: Icons.info_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = resolveConfig(status, type);
    final text = customLabel ?? config.label;
    final isSmall = size == AppStatusChipSize.small;

    final double fontSize = isSmall ? 10.5 : 12.0;
    final EdgeInsets padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
        border: showBorder
            ? Border.all(color: config.borderColor, width: 0.8)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: isSmall ? 5 : 6,
              height: isSmall ? 5 : 6,
              decoration: BoxDecoration(
                color: config.textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (customIcon != null || config.icon != null) ...[
            Icon(
              customIcon ?? config.icon,
              size: isSmall ? 11 : 13,
              color: config.textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
