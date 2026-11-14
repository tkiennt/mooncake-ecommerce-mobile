import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Nguyễn Văn Kiên');
  final _companyController = TextEditingController(text: 'Tập đoàn B2B Mooncake');
  final _phoneController = TextEditingController(text: '0901234567');
  final _emailController = TextEditingController(text: 'khachhang@nguyetpho.vn');
  final _taxIdController = TextEditingController(text: '0101234567');

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Chỉnh Sửa Hồ Sơ', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên người đại diện'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Tên công ty / Doanh nghiệp'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxIdController,
                    decoration: const InputDecoration(labelText: 'Mã số thuế (MST xuất hóa đơn)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email công ty'),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    title: 'Lưu thay đổi',
                    size: ButtonSize.large,
                    width: double.infinity,
                    onPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hồ sơ đã được lưu thành công!')),
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
