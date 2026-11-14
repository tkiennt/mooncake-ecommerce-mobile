import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../data/models/order.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final List<Order> mockOrders = [
    Order(
      id: 'ord-1',
      orderCode: 'DH-2026-9921',
      status: 'Processing',
      totalAmount: 18500000,
      finalAmount: 14800000,
      discountAmount: 3700000,
      shippingAddress: 'Tòa nhà FPT, Cầu Giấy, Hà Nội',
      recipientName: 'Nguyễn Văn Kiên',
      recipientPhone: '0901234567',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      deliveryNote: 'Giao xe lạnh 20-25°C trước 17h',
      items: [
        OrderItem(
          id: 'item-1',
          productName: 'Hộp Sơn Mài Hoàng Triều 4 Bánh',
          variantName: 'Yến Sào & Hạt Sen',
          quantity: 20,
          unitPrice: 850000,
          totalPrice: 17000000,
          imageUrl: 'assets/products/hop-son-mai.jpg',
        ),
      ],
    ),
    Order(
      id: 'ord-2',
      orderCode: 'DH-2026-8802',
      status: 'Delivered',
      totalAmount: 8250000,
      finalAmount: 7012500,
      discountAmount: 1237500,
      shippingAddress: 'Khu công nghệ cao Láng Hòa Lạc, Thạch Thất, Hà Nội',
      recipientName: 'Nguyễn Văn Kiên',
      recipientPhone: '0901234567',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      deliveryNote: 'Đã hoàn tất ký biên bản PoD',
      items: [
        OrderItem(
          id: 'item-2',
          productName: 'Bánh Trung Thu Nướng Thập Cẩm Bát Bửu',
          variantName: '2 Trứng 210g',
          quantity: 50,
          unitPrice: 165000,
          totalPrice: 8250000,
          imageUrl: 'assets/products/banh-nuong.jpg',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'Processing':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        label = 'Đang sản xuất';
        break;
      case 'Delivered':
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'Đã giao thành công';
        break;
      case 'Shipping':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'Đang giao hàng';
        break;
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockOrders.length,
              itemBuilder: (context, index) {
                final order = mockOrders[index];
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
                    onTap: () => context.push('/order-detail', extra: order),
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
                                child: Image.asset(
                                  item.imageUrl ?? 'assets/products/banh-nuong.jpg',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text('SL: ${item.quantity} hộp', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(_formatCurrency(item.totalPrice), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
                                const Text('Thực trả: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(
                                  _formatCurrency(order.finalAmount),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
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
          ),
        ],
      ),
    );
  }
}
