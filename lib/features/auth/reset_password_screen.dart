import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared_widgets/antd/antd_otp_input.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;
  final String? email;

  const ResetPasswordScreen({super.key, this.phoneNumber, this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _emailController;
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String _otpCode = '';
  bool _showNewPass = false;
  bool _showConfirmPass = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.email ?? widget.phoneNumber ?? '';
    _emailController = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String get _currentEmail => _emailController.text.trim();

  Future<void> _handleResetPassword() async {
    final email = _currentEmail;
    final otp = _otpCode.trim();
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ email đã nhận mã OTP.');
      return;
    }
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ 6 chữ số mã xác thực OTP.');
      return;
    }
    if (newPass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu mới.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không trùng khớp với mật khẩu mới.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(
        email: email,
        token: otp,
        newPassword: newPass,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập với mật khẩu mới.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
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

  Future<void> _handleResend() async {
    final email = _currentEmail;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email trước khi yêu cầu gửi lại mã.')),
      );
      return;
    }

    setState(() => _errorMessage = null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.forgotPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi lại mã OTP tới email $email.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (mounted) {
        setState(() {
          _errorMessage = err.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Đặt Lại Mật Khẩu', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.password_outlined, color: AppColors.primary, size: 36),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Thiết lập mật khẩu mới',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _currentEmail.isNotEmpty
                  ? 'Nhập mã OTP 6 số đã được gửi tới email:\n$_currentEmail'
                  : 'Nhập mã OTP và mật khẩu mới để hoàn tất khôi phục tài khoản.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

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
                  // Error banner with retry
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
                            onPressed: _isLoading ? null : _handleResetPassword,
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

                  // Email input
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Email *',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6-digit OTP
                  const Text(
                    'Mã xác thực OTP (6 chữ số):',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AntdOtpInput(
                    length: 6,
                    countdownSeconds: 60,
                    onComplete: (otp) {
                      _otpCode = otp;
                    },
                    onResend: _handleResend,
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  TextField(
                    controller: _newPassController,
                    obscureText: !_showNewPass,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới *',
                      hintText: 'Tối thiểu 6 ký tự',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPass ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showNewPass = !_showNewPass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm New Password
                  TextField(
                    controller: _confirmPassController,
                    obscureText: !_showConfirmPass,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới *',
                      hintText: 'Nhập lại mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPass ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showConfirmPass = !_showConfirmPass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    title: 'Lưu mật khẩu mới',
                    size: ButtonSize.large,
                    loading: _isLoading,
                    onPress: _handleResetPassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Back to Login
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
                label: const Text(
                  'Quay lại màn hình đăng nhập',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
