import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class DeliveryPoDScreen extends StatelessWidget {
  final String? orderId;

  const DeliveryPoDScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Giám Sát Vận Chuyển & PoD', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ColdChain Monitor Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.info.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.ac_unit, color: AppColors.info, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Cảm Biến Xe Lạnh Vận Chuyển',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.info),
                      ),
                      Spacer(),
                      Text('Trực tiếp', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ColdChainMetric(label: 'Nhiệt độ thùng xe', value: '21.5°C', status: 'Đạt chuẩn (20-25°C)'),
                      _ColdChainMetric(label: 'Độ ẩm không khí', value: '55%', status: 'Tối ưu bảo quản'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.info),
                      SizedBox(width: 6),
                      Text(
                        'Vị trí: Đang di chuyển trên đường Phạm Hùng (còn 15 phút)',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Proof of Delivery (PoD) Form Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Biên Bản Bàn Giao Hàng Hóa (PoD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  const Text(
                    'Kiểm tra tính nguyên vẹn của thùng hàng, tem niêm phong và ký xác nhận hoàn thành đơn hàng.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Camera photo evidence box
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 6),
                          const Text('Chụp ảnh thực tế kiện hàng bàn giao', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    title: 'Xác nhận đã nhận đủ số lượng & nguyên vẹn',
                    size: ButtonSize.large,
                    width: double.infinity,
                    onPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xác nhận biên bản PoD thành công!')),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColdChainMetric extends StatelessWidget {
  final String label;
  final String value;
  final String status;

  const _ColdChainMetric({required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.info)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(status, style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
