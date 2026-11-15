import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/repositories/order_repository.dart';
import '../../providers/cart_provider.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_status_chip.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await ref.read(orderRepositoryProvider).getMyOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  List<Order> _getFilteredOrders(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _orders
            .where((o) => o.status.toLowerCase() == 'pending')
            .toList();
      case 2:
        return _orders
            .where((o) => [
                  'confirmed',
                  'processing',
                  'in_production',
                  'inproduction'
                ].contains(o.status.toLowerCase()))
            .toList();
      case 3:
        return _orders
            .where((o) => [
                  'shipping',
                  'shipped',
                  'delivering'
                ].contains(o.status.toLowerCase()))
            .toList();
      case 4:
        return _orders
            .where((o) => [
                  'delivered',
                  'completed'
                ].contains(o.status.toLowerCase()))
            .toList();
      default:
        return _orders;
    }
  }

  void _handleReorder(Order order) {
    if (order.items.isEmpty) return;
    for (final item in order.items) {
      final prod = Product(
        id: item.productId.isNotEmpty ? item.productId : item.id,
        name: item.productName,
        basePrice: item.unitPrice,
        coverImage: item.imageUrl,
        shopId: order.shopId,
        shopName: order.shopName ?? 'Nguyệt Phố B2B',
      );
      final variant = item.variantId != null && item.variantId!.isNotEmpty
          ? ProductVariant(id: item.variantId!, name: item.variantName ?? '')
          : null;
      ref.read(cartProvider.notifier).addToCart(prod, variant, item.quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${order.items.length} món từ đơn ${order.orderCode} vào giỏ hàng.'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'Xem giỏ hàng',
          textColor: Colors.white,
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String title;
    String desc;
    IconData icon;

    switch (tabIndex) {
      case 1:
        title = 'Không có đơn hàng chờ duyệt';
        desc = 'Các đơn hàng mới đặt sẽ xuất hiện tại đây khi chờ xác nhận.';
        icon = Icons.pending_actions_outlined;
        break;
      case 2:
        title = 'Không có đơn hàng đang sản xuất';
        desc = 'Xưởng bánh sẽ cập nhật tiến độ khi bắt đầu làm bánh.';
        icon = Icons.precision_manufacturing_outlined;
        break;
      case 3:
        title = 'Không có đơn hàng đang giao';
        desc = 'Đơn hàng đang trên xe lạnh vận chuyển sẽ hiển thị tại đây.';
        icon = Icons.local_shipping_outlined;
        break;
      case 4:
        title = 'Chưa có đơn hàng hoàn thành';
        desc = 'Đơn hàng đã giao thành công và nghiệm thu PoD sẽ lưu tại đây.';
        icon = Icons.task_alt_outlined;
        break;
      default:
        title = 'Bạn chưa có đơn hàng nào';
        desc = 'Khám phá các bộ sưu tập bánh trung thu doanh nghiệp cao cấp ngay!';
        icon = Icons.receipt_long_outlined;
    }

    return AppEmptyState(
      icon: icon,
      title: title,
      message: desc,
      actionLabel: 'Khám phá sản phẩm',
      onAction: () => context.go('/search'),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      itemCount: 4,
      itemBuilder: (_, __) => AppSkeleton.orderCard(),
    );
  }

  Widget _buildErrorState() {
    return AppErrorState(
      title: 'Không thể tải danh sách đơn hàng',
      message: _errorMessage ?? 'Đã có lỗi xảy ra trong quá trình kết nối máy chủ.',
      retryLabel: 'Thử lại',
      onRetry: _loadOrders,
    );
  }

  Widget _buildOrderList(List<Order> orders, int tabIndex) {
    if (orders.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
            padding: const EdgeInsets.all(AppTokens.spaceLG),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTokens.shadowSubtle,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              onTap: () async {
                await context.push('/order-detail', extra: order);
                _loadOrders();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.orderCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      AppStatusChip(
                        status: order.status,
                        type: AppStatusType.order,
                        size: AppStatusChipSize.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.spaceSM),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                              child: item.imageUrl != null && item.imageUrl!.startsWith('http')
                                  ? Image.network(
                                      item.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/products/banh-nuong.jpg',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      item.imageUrl ?? 'assets/products/banh-nuong.jpg',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: AppColors.background,
                                        child: const Icon(Icons.cake, color: AppColors.primary),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: AppTokens.spaceMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SL: ${item.quantity} hộp',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 16, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          const Text('Thực trả: ',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            _formatCurrency(order.finalAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  // Nút đặt lại đơn cũ (thêm vào giỏ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _handleReorder(order),
                        icon: const Icon(Icons.replay_outlined, size: 16),
                        label: const Text('Đặt lại đơn'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          minimumSize: const Size(110, AppTokens.minTapTarget),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Đơn Hàng Doanh Nghiệp',
        showBack: false,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: const [
                Tab(text: 'Tất cả'),
                Tab(text: 'Chờ duyệt'),
                Tab(text: 'Đang sản xuất'),
                Tab(text: 'Đang giao'),
                Tab(text: 'Hoàn thành'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null && _orders.isEmpty
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          5,
                          (tabIndex) => _buildOrderList(
                            _getFilteredOrders(tabIndex),
                            tabIndex,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
