import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class CreateRfqScreen extends StatefulWidget {
  const CreateRfqScreen({super.key});

  @override
  State<CreateRfqScreen> createState() => _CreateRfqScreenState();
}

class _CreateRfqScreenState extends State<CreateRfqScreen> {
  final _titleController = TextEditingController(text: 'Đặt 500 hộp quà trung thu doanh nghiệp');
  final _qtyController = TextEditingController(text: '500');
  final _budgetController = TextEditingController(text: '200000000');
  final _notesController = TextEditingController(text: 'Yêu cầu in laser logo FPT lên nắp gỗ, giao hàng xe lạnh tận nơi.');
  bool _customPackaging = true;
  bool _sampleBoxNeeded = true;

  @override
  void dispose() {
    _titleController.dispose();
    _qtyController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Tạo Yêu Cầu Báo Giá (RFQ)',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                  const Text('Thông Tin Đơn Hàng Doanh Nghiệp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề yêu cầu báo giá'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Số lượng hộp'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Ngân sách dự kiến (₫)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Yêu cầu quy cách, hương vị & in ấn'),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: _customPackaging,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cần thiết kế bao bì & in logo công ty', style: TextStyle(fontSize: 13)),
                    onChanged: (val) => setState(() => _customPackaging = val!),
                  ),
                  CheckboxListTile(
                    value: _sampleBoxNeeded,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gửi 01 hộp mẫu thử nguyên seal tận nơi trước khi ký HĐ', style: TextStyle(fontSize: 13)),
                    onChanged: (val) => setState(() => _sampleBoxNeeded = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              title: 'Gửi yêu cầu nhận báo giá xưởng',
              size: ButtonSize.large,
              onPress: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yêu cầu báo giá đã được phát hành tới các xưởng sản xuất!')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
