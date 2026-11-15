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

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? identifier;
  final String? email;

  const VerifyEmailScreen({super.key, this.identifier, this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final TextEditingController _emailController;
  String _otpCode = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.email ?? widget.identifier ?? '';
    _emailController = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String get _currentEmail => _emailController.text.trim();

  Future<void> _handleVerify([String? code]) async {
    final otp = (code ?? _otpCode).trim();
    final email = _currentEmail;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ email đã đăng ký.');
      return;
    }
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ 6 chữ số mã xác thực OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyEmail(
        email: email,
        code: otp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực tài khoản thành công! Vui lòng đăng nhập để tiếp tục.'),
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
      await authRepo.resendVerification(email);

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
      appBar: const AppHeader(title: 'Xác Thực Email', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nhập mã xác thực Email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentEmail.isNotEmpty
                  ? 'Mã OTP 6 chữ số đã được gửi qua email:\n$_currentEmail'
                  : 'Vui lòng kiểm tra hộp thư đến hoặc thư rác trong email của bạn để lấy mã OTP kích hoạt.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Card container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
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
                            onPressed: _isLoading ? null : () => _handleVerify(),
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
                    const SizedBox(height: 18),
                  ],

                  // Editable Email if needed
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Email nhận OTP',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6-digit OTP input
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AntdOtpInput(
                      length: 6,
                      countdownSeconds: 60,
                      onComplete: (otp) {
                        _otpCode = otp;
                        _handleVerify(otp);
                      },
                      onResend: _handleResend,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    title: 'Xác nhận kích hoạt',
                    size: ButtonSize.large,
                    loading: _isLoading,
                    onPress: () => _handleVerify(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Back to Login
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
              label: const Text(
                'Quay lại màn hình đăng nhập',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
