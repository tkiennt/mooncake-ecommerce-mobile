import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _rfqBids = true;
  bool _contractUpdates = true;
  bool _deliveryAlerts = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Cài Đặt Thông Báo', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _rfqBids,
                  activeColor: AppColors.primary,
                  title: const Text('Báo giá mới từ xưởng sản xuất', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Nhận thông báo khi có xưởng nộp hồ sơ đấu thầu RFQ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => setState(() => _rfqBids = val),
                ),
                const Divider(height: 1, color: AppColors.border),
                SwitchListTile(
                  value: _contractUpdates,
                  activeColor: AppColors.primary,
                  title: const Text('Hợp đồng & Đặt cọc ký quỹ', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Thông báo ký số và tiến độ giải ngân ký quỹ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => setState(() => _contractUpdates = val),
                ),
                const Divider(height: 1, color: AppColors.border),
                SwitchListTile(
                  value: _deliveryAlerts,
                  activeColor: AppColors.primary,
                  title: const Text('Hành trình xe lạnh & PoD', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cảnh báo nhiệt độ và chuẩn bị nhận hàng', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => setState(() => _deliveryAlerts = val),
                ),
                const Divider(height: 1, color: AppColors.border),
                SwitchListTile(
                  value: _promotions,
                  activeColor: AppColors.primary,
                  title: const Text('Ưu đãi mùa vụ 2026', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Các chương trình chiết khấu thêm theo đợt', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => setState(() => _promotions = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
