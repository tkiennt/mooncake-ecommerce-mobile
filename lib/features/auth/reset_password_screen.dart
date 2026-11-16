import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared_widgets/antd/antd_otp_input.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/sticky_bottom_bar.dart';

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
  bool _isFatalNetworkError = false;
  bool _showManualEmailInput = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.email ?? widget.phoneNumber ?? '';
    _emailController = TextEditingController(text: initialEmail);
    if (initialEmail.isEmpty) {
      _showManualEmailInput = false;
    }
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
      setState(() {
        _errorMessage = 'Bạn hãy nhập email đã nhận mã xác nhận nhé.';
        _isFatalNetworkError = false;
      });
      return;
    }
    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'Bạn hãy nhập đủ 6 chữ số của mã xác nhận nhé.';
        _isFatalNetworkError = false;
      });
      return;
    }
    if (newPass.isEmpty) {
      setState(() {
        _errorMessage = 'Bạn hãy nhập mật khẩu mới nhé.';
        _isFatalNetworkError = false;
      });
      return;
    }
    if (newPass.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu mới cần ít nhất 6 ký tự.';
        _isFatalNetworkError = false;
      });
      return;
    }
    if (newPass != confirmPass) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận chưa khớp với mật khẩu mới.';
        _isFatalNetworkError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFatalNetworkError = false;
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
            content: Text('Đặt lại mật khẩu thành công! Bạn đăng nhập với mật khẩu mới nhé.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (mounted) {
        final msg = err.message.toLowerCase();
        final isNetwork = err.statusCode == 0 ||
            err.statusCode == 502 ||
            err.statusCode == 503 ||
            msg.contains('kết nối') ||
            msg.contains('socket');

        setState(() {
          _errorMessage = err.message;
          _isFatalNetworkError = isNetwork;
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
        const SnackBar(content: Text('Bạn hãy nhập email trước khi gửi lại mã nhé.')),
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _isFatalNetworkError = false;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.forgotPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi lại mã xác nhận tới $email.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (mounted) {
        final msg = err.message.toLowerCase();
        final isNetwork = err.statusCode == 0 ||
            err.statusCode == 502 ||
            err.statusCode == 503 ||
            msg.contains('kết nối') ||
            msg.contains('socket');

        setState(() {
          _errorMessage = err.message;
          _isFatalNetworkError = isNetwork;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNoEmail = _currentEmail.isEmpty && !_showManualEmailInput;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: const AppHeader(title: 'Đặt lại mật khẩu', showBack: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceLG,
            vertical: AppTokens.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isFatalNetworkError)
                AppErrorState(
                  title: 'Không kết nối được',
                  message: _errorMessage ?? 'Chưa đặt lại được mật khẩu, bạn thử lại sau nhé.',
                  onRetry: _handleResetPassword,
                  retryLabel: 'Thử lại ngay',
                  secondaryActionLabel: 'Đăng nhập lại',
                  onSecondaryAction: () => context.go('/login'),
                )
              else if (hasNoEmail)
                AppEmptyState(
                  icon: Icons.lock_reset_outlined,
                  title: 'Chưa có thông tin khôi phục',
                  message: 'Bạn hãy yêu cầu mã xác nhận qua email trước khi tạo mật khẩu mới nhé.',
                  actionLabel: 'Nhập email thủ công',
                  onAction: () {
                    setState(() {
                      _showManualEmailInput = true;
                    });
                  },
                  secondaryActionLabel: 'Yêu cầu mã khôi phục',
                  onSecondaryAction: () => context.push('/forgot-password'),
                )
              else if (_isLoading)
                _buildLoadingSkeleton()
              else
                _buildResetForm(),

              const SizedBox(height: AppTokens.space2XL),

              // Back to Login (tap target >= 44px)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                  child: TextButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
                    label: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (hasNoEmail || _isFatalNetworkError)
          ? null
          : StickyBottomBar(
              primaryButtonTitle: 'Lưu mật khẩu mới',
              primaryButtonLoading: _isLoading,
              onPrimaryPressed: _isLoading ? null : _handleResetPassword,
            ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppSkeleton(width: 68, height: 68, shape: BoxShape.circle),
          const SizedBox(height: AppTokens.spaceLG),
          const AppSkeleton(width: 200, height: 20),
          const SizedBox(height: AppTokens.spaceMD),
          const AppSkeleton(width: 260, height: 14),
          const SizedBox(height: AppTokens.space2XL),
          // OTP input shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: const AppSkeleton(
                width: 38,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput)),
              ),
            )),
          ),
          const SizedBox(height: AppTokens.spaceXL),
          const AppSkeleton(height: 48, borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput))),
          const SizedBox(height: AppTokens.spaceMD),
          const AppSkeleton(height: 48, borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput))),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        const SizedBox(height: AppTokens.spaceMD),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.password_outlined, color: AppColors.primary, size: 38),
          ),
        ),
        const SizedBox(height: AppTokens.spaceLG),
        const Text(
          'Thiết lập mật khẩu mới',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spaceSM),
        Text(
          _currentEmail.isNotEmpty
              ? 'Nhập mã xác nhận 6 số đã gửi tới email:\n$_currentEmail'
              : 'Nhập mã xác nhận và mật khẩu mới để hoàn tất đặt lại mật khẩu.',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.space2XL),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMD,
            vertical: AppTokens.spaceXL,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.shadowCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner with retry
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMD,
                    vertical: AppTokens.spaceSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppTokens.spaceSM),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                        child: TextButton(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ email *',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: AppTokens.spaceXL),

              // 6-digit OTP (responsive no overflow at 375px)
              const Text(
                'Mã xác nhận (6 chữ số):',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AntdOtpInput(
                    length: 6,
                    countdownSeconds: 60,
                    onComplete: (otp) {
                      _otpCode = otp;
                    },
                    onResend: _handleResend,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceXL),

              // New Password
              TextField(
                controller: _newPassController,
                obscureText: !_showNewPass,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới *',
                  hintText: 'Tối thiểu 6 ký tự',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  suffixIcon: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppTokens.minTapTarget,
                      minHeight: AppTokens.minTapTarget,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showNewPass ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _showNewPass = !_showNewPass),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),

              // Confirm New Password
              TextField(
                controller: _confirmPassController,
                obscureText: !_showConfirmPass,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleResetPassword(),
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới *',
                  hintText: 'Nhập lại mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textMuted),
                  suffixIcon: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppTokens.minTapTarget,
                      minHeight: AppTokens.minTapTarget,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _showConfirmPass ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _showConfirmPass = !_showConfirmPass),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
