import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

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

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'processing':
      case 'in_production':
      case 'inproduction':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        label = 'Đang sản xuất';
        break;
      case 'confirmed':
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
        label = 'Đã xác nhận';
        break;
      case 'delivered':
      case 'completed':
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'Đã giao thành công';
        break;
      case 'shipping':
      case 'shipped':
      case 'delivering':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'Đang giao hàng';
        break;
      case 'cancelled':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        label = 'Đã hủy';
        break;
      case 'pending':
      default:
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
        label = 'Chờ xác nhận';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
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

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Khám phá sản phẩm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Đang tải danh sách đơn hàng...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải danh sách đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra trong quá trình kết nối máy chủ.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                ),
              ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTokens.shadowSubtle,
            ),
            child: InkWell(
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
                      Text(
                        order.orderCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
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
