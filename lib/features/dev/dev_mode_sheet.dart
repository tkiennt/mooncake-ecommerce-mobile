import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/order.dart';
import '../../data/models/rfq.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';

/// Shows the Dev Mode Sheet as a modal bottom sheet
void showDevModeSheet(BuildContext context) {
  if (!kDebugMode) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const DevModeSheet(),
  );
}

/// Floating trigger widget for quick access to Dev Mode Sheet
class DevModeFloatingTrigger extends StatelessWidget {
  const DevModeFloatingTrigger({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => showDevModeSheet(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x558C1524),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.developer_mode, color: AppColors.accent, size: 18),
              SizedBox(width: 6),
              Text(
                'DEV MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DevRouteCategory {
  final String title;
  final List<DevRouteItem> routes;

  const DevRouteCategory({
    required this.title,
    required this.routes,
  });
}

class DevRouteItem {
  final String path;
  final String name;
  final IconData icon;
  final Object? extra;

  const DevRouteItem({
    required this.path,
    required this.name,
    required this.icon,
    this.extra,
  });
}

class DevModeSheet extends ConsumerStatefulWidget {
  const DevModeSheet({super.key});

  @override
  ConsumerState<DevModeSheet> createState() => _DevModeSheetState();
}

class _DevModeSheetState extends ConsumerState<DevModeSheet> {
  bool _isLoggingIn = false;
  bool _isCheckingBackend = false;
  bool? _backendConnected;
  int? _backendStatusCode;
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    if (!mounted) return;
    setState(() {
      _isCheckingBackend = true;
      _backendError = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get(
        ApiEndpoints.categories,
      );
      if (mounted) {
        setState(() {
          _backendConnected = response.statusCode == 200;
          _backendStatusCode = response.statusCode;
          _isCheckingBackend = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendConnected = false;
          _backendStatusCode = null;
          _backendError = e.toString();
          _isCheckingBackend = false;
        });
      }
    }
  }

  Future<void> _quickLoginCustomer({
    required String phone,
    required String password,
    required String customerLabel,
  }) async {
    setState(() => _isLoggingIn = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.login(
        phoneNumber: phone,
        password: password,
      );

      final storage = ref.read(storageServiceProvider);
      await storage.saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await storage.saveUserJson(jsonEncode(result.user.toJson()));

      await ref.read(authProvider.notifier).loadStoredSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đăng nhập thành công: ${result.user.fullName} ($customerLabel)'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final err = ApiClient.handleError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${err.message}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  List<DevRouteCategory> _buildRouteCategories() {
    return [
      DevRouteCategory(
        title: 'Màn hình chính (Tabs)',
        routes: const [
          DevRouteItem(path: '/', name: 'Trang chủ (HomeScreen)', icon: Icons.home),
          DevRouteItem(path: '/search', name: 'Tìm kiếm sản phẩm', icon: Icons.search),
          DevRouteItem(path: '/cart', name: 'Giỏ hàng & Đặt hàng', icon: Icons.shopping_cart),
          DevRouteItem(path: '/orders', name: 'Lịch sử đơn hàng', icon: Icons.receipt_long),
          DevRouteItem(path: '/profile', name: 'Trang cá nhân', icon: Icons.person),
        ],
      ),
      DevRouteCategory(
        title: 'Xác thực & Tài khoản (Auth)',
        routes: const [
          DevRouteItem(path: '/login', name: 'Đăng nhập', icon: Icons.login),
          DevRouteItem(path: '/register', name: 'Đăng ký tài khoản', icon: Icons.app_registration),
          DevRouteItem(
            path: '/verify-email',
            name: 'Xác thực OTP Email',
            icon: Icons.mark_email_read,
            extra: 'devseed.customer1@mooncake.local',
          ),
          DevRouteItem(path: '/forgot-password', name: 'Quên mật khẩu', icon: Icons.lock_reset),
          DevRouteItem(
            path: '/reset-password',
            name: 'Đặt lại mật khẩu',
            icon: Icons.password,
            extra: '0900000005',
          ),
          DevRouteItem(path: '/edit-profile', name: 'Sửa hồ sơ cá nhân', icon: Icons.manage_accounts),
        ],
      ),
      DevRouteCategory(
        title: 'Mua sắm & Đơn hàng',
        routes: [
          const DevRouteItem(path: '/product-detail', name: 'Chi tiết sản phẩm', icon: Icons.cake),
          const DevRouteItem(path: '/checkout', name: 'Thanh toán (Checkout)', icon: Icons.payment),
          const DevRouteItem(
            path: '/payment-result?success=true&orderCode=DH-2026-DEV',
            name: 'Kết quả thanh toán VNPay',
            icon: Icons.check_circle_outline,
          ),
          DevRouteItem(
            path: '/order-detail',
            name: 'Chi tiết đơn hàng mẫu',
            icon: Icons.description,
            extra: Order(
              id: 'dev-order-001',
              orderCode: 'DH-2026-DEV01',
              status: 'Confirmed',
              totalAmount: 1850000,
              finalAmount: 1850000,
              shippingAddress: 'Tòa nhà FPT, Phố Duy Tân, Cầu Giấy, Hà Nội',
              recipientName: 'DevSeed Nguyễn Văn An',
              recipientPhone: '0900000005',
              createdAt: DateTime.now(),
              shopName: 'Tiệm Bánh Kinh Đô Truyền Thống',
            ),
          ),
        ],
      ),
      DevRouteCategory(
        title: 'Doanh nghiệp B2B (RFQ, Hợp đồng, PoD)',
        routes: [
          const DevRouteItem(path: '/create-rfq', name: 'Tạo yêu cầu báo giá RFQ', icon: Icons.post_add),
          const DevRouteItem(path: '/rfq-list', name: 'Danh sách báo giá RFQ', icon: Icons.format_list_bulleted),
          DevRouteItem(
            path: '/rfq-detail-bidding',
            name: 'Chi tiết & đấu thầu RFQ',
            icon: Icons.gavel,
            extra: Rfq(
              id: 'dev-rfq-001',
              rfqNumber: 'RFQ-2026-DEV',
              title: 'Đơn báo giá hộp bánh nướng B2B trung thu',
              targetQuantity: 100,
              expectedDeliveryDate: DateTime.now().add(const Duration(days: 30)),
              status: 'Open',
              targetBudget: 25000000,
            ),
          ),
          const DevRouteItem(path: '/contracts', name: 'Hợp đồng sỉ B2B', icon: Icons.assignment),
          const DevRouteItem(
            path: '/contract-sign',
            name: 'Ký kết hợp đồng số',
            icon: Icons.draw,
            extra: {
              'contractNumber': 'HDBD-2026-DEV',
              'supplierName': 'Tiệm Bánh Kinh Đô Truyền Thống',
              'customerName': 'Tập Đoàn FPT',
              'totalValue': 25000000.0,
            },
          ),
          const DevRouteItem(path: '/delivery-pod', name: 'Chứng từ giao nhận PoD', icon: Icons.local_shipping),
        ],
      ),
      DevRouteCategory(
        title: 'Tương tác, Cửa hàng & Trợ lý AI',
        routes: const [
          DevRouteItem(path: '/ai-assistant', name: 'Trợ lý AI Nguyệt Phố', icon: Icons.auto_awesome),
          DevRouteItem(path: '/notifications', name: 'Trung tâm thông báo', icon: Icons.notifications),
          DevRouteItem(path: '/notification-settings', name: 'Cài đặt thông báo', icon: Icons.tune),
          DevRouteItem(path: '/review-form', name: 'Đánh giá sản phẩm/đơn', icon: Icons.rate_review),
          DevRouteItem(path: '/reviews/transaction', name: 'Đánh giá giao dịch B2B', icon: Icons.reviews),
          DevRouteItem(path: '/wishlist', name: 'Danh sách yêu thích', icon: Icons.favorite),
          DevRouteItem(
            path: '/shop/devseed-tiem-banh-kinh-do',
            name: 'Shop Kinh Đô (PublicShopScreen)',
            icon: Icons.storefront,
          ),
          DevRouteItem(path: '/chat', name: 'Chat xưởng B2B', icon: Icons.chat),
        ],
      ),
      DevRouteCategory(
        title: 'Công cụ phát triển (Dev Tools)',
        routes: const [
          DevRouteItem(path: '/ui-catalog', name: 'UI Catalog (AntD & Lucian)', icon: Icons.palette),
        ],
      ),
    ];
  }

  void _navigateToRoute(DevRouteItem routeItem) {
    Navigator.of(context).pop();
    if (routeItem.extra != null) {
      context.push(routeItem.path, extra: routeItem.extra);
    } else {
      context.push(routeItem.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final authState = ref.watch(authProvider);
    final routeCategories = _buildRouteCategories();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.developer_mode, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Bảng Điều Khiển Dev Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Backend Status Badge
                _buildBackendStatusCard(),
                const SizedBox(height: 14),

                // 2. Auth Session Card
                _buildAuthSessionCard(authState),
                const SizedBox(height: 14),

                // 3. Quick Customer Login Action
                _buildQuickLoginCard(),
                const SizedBox(height: 20),

                // 4. All App Routes Navigator
                _buildRoutesSection(routeCategories),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendStatusCard() {
    final isOnline = _backendConnected == true;
    final isChecking = _isCheckingBackend;

    Color badgeBg;
    Color badgeTextColor;
    String statusText;
    IconData statusIcon;

    if (isChecking) {
      badgeBg = AppColors.warningBg;
      badgeTextColor = AppColors.warning;
      statusText = 'Đang kiểm tra kết nối...';
      statusIcon = Icons.sync;
    } else if (isOnline) {
      badgeBg = AppColors.successBg;
      badgeTextColor = AppColors.success;
      statusText = 'Backend Online (HTTP ${_backendStatusCode ?? 200} OK)';
      statusIcon = Icons.check_circle;
    } else {
      badgeBg = AppColors.errorBg;
      badgeTextColor = AppColors.error;
      statusText = 'Backend Mất kết nối / Lỗi';
      statusIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KẾT NỐI BACKEND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: _isCheckingBackend ? null : _checkBackendHealth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: _isCheckingBackend ? AppColors.textMuted : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kiểm tra lại',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isCheckingBackend ? AppColors.textMuted : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeTextColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 16, color: badgeTextColor),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Base URL: ${ApiEndpoints.baseUrl}',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.textMuted,
            ),
          ),
          if (_backendError != null && !isChecking) ...[
            const SizedBox(height: 4),
            Text(
              'Chi tiết lỗi: $_backendError',
              style: const TextStyle(fontSize: 10, color: AppColors.error),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthSessionCard(AuthState authState) {
    final user = authState.user;
    final isAuth = authState.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PHIÊN ĐĂNG NHẬP HIỆN TẠI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAuth ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAuth ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isAuth ? 'ĐÃ ĐĂNG NHẬP' : 'KHÁCH (GUEST)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAuth ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isAuth && user != null) ...[
            Text(
              user.fullName.isNotEmpty ? user.fullName : 'Người dùng',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vai trò: ${user.role} · SĐT: ${user.phone}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (user.email.isNotEmpty)
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            if (user.companyName != null && user.companyName!.isNotEmpty)
              Text(
                'Doanh nghiệp: ${user.companyName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 8),
            Text(
              'Token: ${authState.token != null ? '${authState.token!.substring(0, min(18, authState.token!.length))}...' : 'Trống'}',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng xuất tài khoản thành công'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 14, color: AppColors.error),
                label: const Text('Đăng xuất', style: TextStyle(fontSize: 12, color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Chưa có người dùng đăng nhập. Ứng dụng đang hoạt động ở chế độ khách vãng lai.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickLoginCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text(
                'Đăng nhập nhanh Khách hàng (Dev DB)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Gọi AuthRepository đăng nhập tài khoản Khách hàng được cấp từ ACCOUNTS.md:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Primary Button: Customer 1 (FPT B2B)
          ElevatedButton(
            onPressed: _isLoggingIn
                ? null
                : () => _quickLoginCustomer(
                      phone: '0900000005',
                      password: 'Cust1DevSeed@2026!',
                      customerLabel: 'Khách hàng 1 - FPT',
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoggingIn
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Đăng nhập nhanh Khách hàng 1 (Doanh nghiệp)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Nguyễn Văn An · 0900000005 · Tập Đoàn FPT',
                              style: TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),

          // Secondary Button: Customer 2 (Saigontourist)
          OutlinedButton(
            onPressed: _isLoggingIn
                ? null
                : () => _quickLoginCustomer(
                      phone: '0900000006',
                      password: 'Cust2DevSeed@2026!',
                      customerLabel: 'Khách hàng 2 - Saigontourist',
                    ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_pin, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đăng nhập Khách hàng 2 (Thân thiết)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text(
                        'Trần Thị Bình · 0900000006 · Saigontourist',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesSection(List<DevRouteCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.alt_route, color: AppColors.primary, size: 18),
            SizedBox(width: 6),
            Text(
              'Danh sách liên kết mở nhanh toàn bộ Route',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Chạm vào bất kỳ route nào để điều hướng trực tiếp:',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...categories.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  Widget _buildCategoryCard(DevRouteCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          dense: true,
          leading: const Icon(Icons.folder_open, size: 18, color: AppColors.accent),
          title: Text(
            category.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          children: category.routes.map((routeItem) {
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(routeItem.icon, size: 18, color: AppColors.textSecondary),
              title: Text(
                routeItem.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                routeItem.path,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.borderDark),
              onTap: () => _navigateToRoute(routeItem),
            );
          }).toList(),
        ),
      ),
    );
  }
}
