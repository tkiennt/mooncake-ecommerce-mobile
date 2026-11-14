import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contracts = [
      {
        'number': 'HD-2026-991',
        'title': 'Hợp đồng cung cấp 500 hộp bánh trung thu sơn mài',
        'supplier': 'Xưởng Bánh Kinh Đô Nghệ Nhân',
        'value': '195.000.000 ₫',
        'deposit': '58.500.000 ₫ (30%)',
        'status': 'AwaitingSignature',
      },
      {
        'number': 'HD-2026-880',
        'title': 'Hợp đồng 200 hộp bánh dinh dưỡng hạt hữu cơ',
        'supplier': 'Healthy Mooncake Lab',
        'value': '93.600.000 ₫',
        'deposit': 'Đã hoàn tất',
        'status': 'SignedAndInProduction',
      },
    ];

    return Scaffold(
      appBar: const AppHeader(title: 'Hợp Đồng B2B', showBack: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contracts.length,
        itemBuilder: (context, index) {
          final c = contracts[index];
          final isPending = c['status'] == 'AwaitingSignature';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTokens.shadowSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['number']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.warningBg : AppColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPending ? 'Chờ ký số' : 'Đang thực hiện',
                        style: TextStyle(
                          color: isPending ? AppColors.warning : AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 6),
                Text('Đối tác sản xuất: ${c['supplier']}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Giá trị: ${c['value']} · Đặt cọc: ${c['deposit']}', style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
                if (isPending)
                  CustomButton(
                    title: 'Ký số hợp đồng ngay',
                    size: ButtonSize.medium,
                    width: double.infinity,
                    onPress: () {
                      context.push('/contract-sign', extra: {'contractNumber': c['number']});
                    },
                  )
                else
                  CustomButton(
                    title: 'Xem biên bản bàn giao & Xe lạnh',
                    variant: ButtonVariant.outline,
                    size: ButtonSize.medium,
                    width: double.infinity,
                    onPress: () => context.push('/delivery-pod'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
