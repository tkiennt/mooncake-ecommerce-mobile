import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../driver/storage/driver_storage.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  bool _isFatalNetworkError = false;
  bool _isAccountNotFound = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập số điện thoại.';
        _isFatalNetworkError = false;
        _isAccountNotFound = false;
      });
      return;
    }
    if (pass.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu.';
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
      final result = await authRepo.login(
        phoneNumber: phone,
        password: pass,
      );

      final storage = ref.read(storageServiceProvider);
      await storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await storage.saveUserJson(jsonEncode(result.user.toJson()));

      await ref.read(authProvider.notifier).loadStoredSession();

      // Đăng nhập tài khoản luôn vào luồng khách; chế độ tài xế chỉ bật khi
      // người dùng chọn "Tôi là tài xế".
      await DriverStorage.setDriverModeActive(false);

      if (mounted) {
        context.go('/');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space2XL,
              vertical: AppTokens.spaceLG,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      boxShadow: AppTokens.shadowCard,
                    ),
                    child: const Icon(Icons.nightlight_round, color: AppColors.accent, size: 42),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
                const Text(
                  'NGUYỆT PHỐ B2B',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spaceXS),
                const Text(
                  'Sàn Phân Phối Bánh Trung Thu Doanh Nghiệp',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space2XL),

                // Main Content: Error / Empty / Loading Skeleton / Form
                if (_isFatalNetworkError)
                  AppErrorState(
                    title: 'Không thể kết nối máy chủ',
                    message: _errorMessage ?? 'Đã có lỗi xảy ra khi kết nối tới máy chủ Nguyệt Phố.',
                    onRetry: _handleLogin,
                    retryLabel: 'Thử lại ngay',
                    secondaryActionLabel: 'Đăng nhập lại',
                    onSecondaryAction: () {
                      setState(() {
                        _isFatalNetworkError = false;
                        _errorMessage = null;
                      });
                    },
                  )
                else if (_isAccountNotFound)
                  AppEmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Tài khoản chưa tồn tại',
                    message: 'Số điện thoại này chưa được đăng ký tài khoản khách hàng trên hệ thống Nguyệt Phố B2B.',
                    actionLabel: 'Đăng ký tài khoản mới',
                    onAction: () => context.push('/register'),
                    secondaryActionLabel: 'Đăng nhập số khác',
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
                  _buildLoginForm(),

                const SizedBox(height: AppTokens.space2XL),

                // Back / Skip to Browse (tap target >= 44px)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                    child: TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
                      label: const Text(
                        'Khám phá sàn không cần đăng nhập',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSkeleton(width: 180, height: 22),
          const SizedBox(height: AppTokens.spaceLG),
          const AppSkeleton(height: 48, borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput))),
          const SizedBox(height: AppTokens.spaceMD),
          const AppSkeleton(height: 48, borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusInput))),
          const SizedBox(height: AppTokens.spaceLG),
          const AppSkeleton(height: AppTokens.minTapTarget, borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusDefault))),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
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
          const Text(
            'Đăng nhập tài khoản',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTokens.spaceLG),

          // Error banner with retry button (D11 - no mock fallback)
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
                      onPressed: _isLoading ? null : _handleLogin,
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
            const SizedBox(height: AppTokens.spaceMD),
          ],

          // Phone input
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              hintText: 'Nhập số điện thoại đã đăng ký',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMD),

          // Password input
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
              suffixIcon: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppTokens.minTapTarget,
                  minHeight: AppTokens.minTapTarget,
                ),
                child: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceSM),

          // Forgot password link (tap target >= 44px)
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMD),

          // Submit button
          CustomButton(
            title: 'Đăng nhập',
            size: ButtonSize.large,
            loading: _isLoading,
            onPress: _handleLogin,
          ),
          const SizedBox(height: AppTokens.spaceLG),

          // Register link (tap target >= 44px)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
            child: Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text(
                        'Đăng ký ngay',
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
          ),
          const SizedBox(height: AppTokens.spaceLG),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
                child: Text(
                  'HOẶC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppTokens.spaceLG),

          // Nút phụ: Tôi là tài xế – nhập mã chuyến
          OutlinedButton.icon(
            onPressed: () async {
              final trips = await DriverStorage.getSavedTrips();
              if (context.mounted) {
                if (trips.isNotEmpty) {
                  context.push('/driver/trips');
                } else {
                  context.push('/driver/entry');
                }
              }
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.accent, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
              ),
              backgroundColor: AppColors.accentGoldBg,
            ),
            icon: const Icon(Icons.local_shipping_outlined, color: AppColors.accent),
            label: const Text(
              'Tôi là tài xế – nhập mã chuyến',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
