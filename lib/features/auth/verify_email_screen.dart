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
  bool _isFatalNetworkError = false;
  bool _showManualEmailInput = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialEmail = widget.email ?? widget.identifier ?? '';
    _emailController = TextEditingController(text: initialEmail);
    if (initialEmail.isEmpty) {
      _showManualEmailInput = false; // Will display AppEmptyState until user taps action
    }
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
      setState(() {
        _errorMessage = 'Bạn hãy nhập email đã đăng ký nhé.';
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFatalNetworkError = false;
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
            content: Text('Xác thực thành công! Bạn đăng nhập để tiếp tục nhé.'),
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
      await authRepo.resendVerification(email);

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
      appBar: const AppHeader(title: 'Xác thực email', showBack: true),
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
                  message: _errorMessage ?? 'Chưa xác thực được mã, bạn thử lại sau nhé.',
                  onRetry: () => _handleVerify(),
                  retryLabel: 'Thử lại ngay',
                  secondaryActionLabel: 'Đăng nhập lại',
                  onSecondaryAction: () => context.go('/login'),
                )
              else if (hasNoEmail)
                AppEmptyState(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Chưa có thông tin xác thực',
                  message: 'Chưa có email để kích hoạt. Bạn hãy nhập email hoặc đăng ký tài khoản mới nhé.',
                  actionLabel: 'Nhập email xác thực',
                  onAction: () {
                    setState(() {
                      _showManualEmailInput = true;
                    });
                  },
                  secondaryActionLabel: 'Đăng ký tài khoản',
                  onSecondaryAction: () => context.push('/register'),
                )
              else if (_isLoading)
                _buildLoadingSkeleton()
              else
                _buildVerificationContent(),

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
              primaryButtonTitle: 'Xác nhận kích hoạt',
              primaryButtonLoading: _isLoading,
              onPrimaryPressed: _isLoading ? null : () => _handleVerify(),
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
          const AppSkeleton(width: 60, height: 60, shape: BoxShape.circle),
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
          const SizedBox(height: AppTokens.space2XL),
          const AppSkeleton(height: AppTokens.minTapTarget, borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusDefault))),
        ],
      ),
    );
  }

  Widget _buildVerificationContent() {
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
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 38),
          ),
        ),
        const SizedBox(height: AppTokens.spaceLG),
        const Text(
          'Nhập mã xác nhận',
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
              ? 'Mã xác nhận 6 chữ số đã gửi tới email:\n$_currentEmail'
              : 'Bạn kiểm tra hộp thư đến hoặc thư rác để lấy mã xác nhận nhé.',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.space2XL),

        // Card container
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // Editable Email if needed
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: AppTokens.space2XL),

              // 6-digit OTP input: wrapped with FittedBox + ConstrainedBox to guarantee no overflow at 375px
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FittedBox(
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
