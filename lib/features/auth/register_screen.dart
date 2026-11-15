import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$').hasMatch(phone);
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final company = _companyController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ và tên người đại diện.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập số điện thoại.');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(() => _errorMessage = 'Số điện thoại không hợp lệ (gồm 10 số, bắt đầu bằng 03, 05, 07, 08, 09).');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ email nhận mã xác thực.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Địa chỉ email không đúng định dạng.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải chứa ít nhất 6 ký tự.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không trùng khớp.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.register(
        fullName: name,
        phone: phone,
        email: email,
        password: password,
        companyName: company.isNotEmpty ? company : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng kiểm tra mã OTP gửi tới email.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/verify-email', extra: email);
      }
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (mounted) {
        setState(() {
          _errorMessage = err.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Đăng Ký Tài Khoản', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTokens.shadowCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Đăng ký đối tác doanh nghiệp',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhận ngay bảng giá chiết khấu đặc quyền cho mùa trăng 2026',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Error banner with retry (D11)
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 13, color: AppColors.error),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Thử lại',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Full Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên người đại diện *',
                      hintText: 'Ví dụ: Nguyễn Văn A',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại liên hệ *',
                      hintText: 'Ví dụ: 0901234567',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email (Required for OTP verification as per D10 & BE contract)
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Email *',
                      hintText: 'Ví dụ: contact@doanhnghiep.vn',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                      helperText: 'Mã xác thực OTP kích hoạt tài khoản sẽ gửi về email này',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Company
                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Tên công ty / Tổ chức (tùy chọn)',
                      hintText: 'Ví dụ: Công ty TNHH Giải Pháp Công Nghệ',
                      prefixIcon: Icon(Icons.business_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu *',
                      hintText: 'Tối thiểu 6 ký tự',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu *',
                      hintText: 'Nhập lại mật khẩu phía trên',
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    title: 'Đăng ký ngay',
                    size: ButtonSize.large,
                    loading: _isLoading,
                    onPress: _handleRegister,
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
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
