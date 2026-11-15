import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/sticky_bottom_bar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isFatalNetworkError = false;
  bool _isAccountNotFound = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Bạn hãy nhập email đã đăng ký nhé.';
        _isFatalNetworkError = false;
        _isAccountNotFound = false;
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Email chưa đúng định dạng.';
        _isFatalNetworkError = false;
        _isAccountNotFound = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFatalNetworkError = false;
      _isAccountNotFound = false;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.forgotPassword(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã xác nhận khôi phục mật khẩu đã gửi tới email của bạn.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/reset-password', extra: email);
      }
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (mounted) {
        final msg = err.message.toLowerCase();
        final isNotFound = err.statusCode == 404 ||
            msg.contains('không tìm thấy') ||
            msg.contains('không tồn tại');
        final isNetwork = err.statusCode == 0 ||
            err.statusCode == 502 ||
            err.statusCode == 503 ||
            msg.contains('kết nối') ||
            msg.contains('socket');

        setState(() {
          _errorMessage = err.message;
          _isAccountNotFound = isNotFound;
          _isFatalNetworkError = isNetwork;
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
      resizeToAvoidBottomInset: true,
      appBar: const AppHeader(title: 'Quên mật khẩu', showBack: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space2XL,
            vertical: AppTokens.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isFatalNetworkError)
                AppErrorState(
                  title: 'Không kết nối được',
                  message: _errorMessage ?? 'Không gửi được yêu cầu, bạn kiểm tra lại mạng rồi thử lại nhé.',
                  onRetry: _handleSubmit,
                  retryLabel: 'Thử lại ngay',
                  secondaryActionLabel: 'Đăng nhập lại',
                  onSecondaryAction: () => context.go('/login'),
                )
              else if (_isAccountNotFound)
                AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Không tìm thấy tài khoản',
                  message: 'Email này chưa được đăng ký trên Nguyệt Phố.',
                  actionLabel: 'Đăng ký tài khoản mới',
                  onAction: () => context.push('/register'),
                  secondaryActionLabel: 'Thử lại email khác',
                  onSecondaryAction: () {
                    setState(() {
                      _isAccountNotFound = false;
                      _errorMessage = null;
                    });
                  },
                )
              else if (_isLoading)
                _buildLoadingSkeleton()
              else
                _buildForgotPasswordForm(),

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
      bottomNavigationBar: (_isFatalNetworkError || _isAccountNotFound)
          ? null
          : StickyBottomBar(
              primaryButtonTitle: 'Gửi mã khôi phục',
              primaryButtonLoading: _isLoading,
              onPrimaryPressed: _isLoading ? null : _handleSubmit,
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
          const AppSkeleton(width: 180, height: 20),
          const SizedBox(height: AppTokens.spaceSM),
          const AppSkeleton(width: 260, height: 14),
          const SizedBox(height: AppTokens.space2XL),
          const AppSkeleton(
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput)),
          ),
          const SizedBox(height: AppTokens.space2XL),
          const AppSkeleton(
            height: AppTokens.minTapTarget,
            borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusDefault)),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
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
            child: const Icon(Icons.lock_reset_outlined, color: AppColors.primary, size: 38),
          ),
        ),
        const SizedBox(height: AppTokens.spaceLG),
        const Text(
          'Khôi phục mật khẩu',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spaceSM),
        const Text(
          'Nhập địa chỉ email đã đăng ký để nhận mã xác nhận đặt lại mật khẩu mới.',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.space2XL),

        Container(
          padding: const EdgeInsets.all(AppTokens.spaceXL),
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
                          onPressed: _isLoading ? null : _handleSubmit,
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ email *',
                  hintText: 'Nhập email đã đăng ký',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
