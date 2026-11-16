import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'shared_widgets/common/bottom_tab_bar.dart';
import 'shared_widgets/common/app_header.dart';
import 'core/theme/app_colors.dart';
import 'providers/cart_provider.dart';

import 'features/home/home_screen.dart';
import 'features/catalog/search_screen.dart';
import 'features/catalog/product_detail_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/cart/checkout_screen.dart';
import 'features/cart/payment_result_screen.dart';
import 'features/profile/order_history_screen.dart';
import 'features/profile/order_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';

import 'features/b2b/create_rfq_screen.dart';
import 'features/b2b/rfq_list_screen.dart';
import 'features/b2b/rfq_detail_bidding_screen.dart';
import 'features/b2b/contracts_screen.dart';
import 'features/b2b/contract_sign_screen.dart';
import 'features/b2b/delivery_pod_screen.dart';

import 'features/ai/ai_assistant_screen.dart';
import 'features/notification/notification_screen.dart';
import 'features/notification/notification_settings_screen.dart';
import 'features/dev/ui_catalog_screen.dart';
import 'features/dev/dev_mode_sheet.dart';

import 'features/reviews/review_form_screen.dart';
import 'features/wishlist/wishlist_screen.dart';
import 'features/shop/public_shop_screen.dart';
import 'features/chat/chat_screen.dart';

import 'features/driver/storage/driver_storage.dart';
import 'features/driver/screens/driver_code_entry_screen.dart';
import 'features/driver/screens/driver_trips_list_screen.dart';
import 'features/driver/screens/driver_claim_screen.dart';
import 'features/driver/screens/driver_trip_detail_screen.dart';
import 'features/driver/screens/driver_proof_capture_screen.dart';
import 'features/driver/screens/driver_qr_scanner_screen.dart';

import 'data/models/driver_trip.dart';
import 'data/models/product.dart';
import 'data/models/order.dart';
import 'data/models/rfq.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/rfq_repository.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final cartTotals = ref.watch(cartProvider).totals;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      if (state.matchedLocation == '/') {
        final isDriver = await DriverStorage.isDriverModeActive();
        if (isDriver) {
          final saved = await DriverStorage.getSavedTrips();
          if (saved.isNotEmpty) {
            return '/driver/trips';
          }
        }
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: Stack(
              children: [
                navigationShell,
                if (kDebugMode)
                  const Positioned(
                    right: 16,
                    bottom: 16,
                    child: DevModeFloatingTrigger(),
                  ),
              ],
            ),
            bottomNavigationBar: BottomTabBar(
              currentIndex: navigationShell.currentIndex,
              cartBadgeCount: cartTotals.totalItems,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          );
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Branch 2: Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          // Branch 3: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrderHistoryScreen(),
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Auth Stack Routes
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.extra as String? ??
              state.uri.queryParameters['email'] ??
              state.uri.queryParameters['identifier'];
          return VerifyEmailScreen(identifier: id);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final phone = state.extra as String? ??
              state.uri.queryParameters['phone'] ??
              state.uri.queryParameters['phoneNumber'];
          return ResetPasswordScreen(phoneNumber: phone);
        },
      ),

      // Driver Flow Routes (No auth token required)
      GoRoute(
        path: '/driver/entry',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ??
              state.uri.queryParameters['shareCode'];
          final token = state.uri.queryParameters['token'];
          return DriverCodeEntryScreen(
            initialCode: code,
            initialToken: token,
          );
        },
      ),
      GoRoute(
        path: '/driver/trips',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DriverTripsListScreen(),
      ),
      GoRoute(
        path: '/driver/claim',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final trip =
              state.extra is DriverTrip ? state.extra as DriverTrip : null;
          return DriverClaimScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/driver/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final trip =
              state.extra is DriverTrip ? state.extra as DriverTrip : null;
          return DriverTripDetailScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/driver/proof',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final trip =
              state.extra is DriverTrip ? state.extra as DriverTrip : null;
          return DriverProofCaptureScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/driver/qr-scanner',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DriverQrScannerScreen(),
      ),
      GoRoute(
        path: '/giao-hang-tai-xe',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final code = state.uri.queryParameters['code'] ??
              state.uri.queryParameters['shareCode'];
          return DriverCodeEntryScreen(
            initialCode: code,
            initialToken: token,
          );
        },
      ),

      // Product & Checkout
      GoRoute(
        path: '/product-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ??
              state.uri.queryParameters['productId'] ??
              state.pathParameters['id'] ??
              (state.extra is String ? state.extra as String : null);
          Product? initialProduct;
          if (state.extra is Product) {
            initialProduct = state.extra as Product;
          } else if (state.extra is Map<String, dynamic>) {
            try {
              initialProduct = Product.fromJson(state.extra as Map<String, dynamic>);
            } catch (_) {}
          }
          return _ProductDetailRouteLoader(
            initialProduct: initialProduct,
            productId: id,
          );
        },
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ??
                  state.uri.queryParameters['id'] ??
                  state.uri.queryParameters['productId'] ??
                  (state.extra is String ? state.extra as String : null);
              Product? initialProduct;
              if (state.extra is Product) {
                initialProduct = state.extra as Product;
              } else if (state.extra is Map<String, dynamic>) {
                try {
                  initialProduct = Product.fromJson(state.extra as Map<String, dynamic>);
                } catch (_) {}
              }
              return _ProductDetailRouteLoader(
                initialProduct: initialProduct,
                productId: id,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/payment-result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final isSuccess = state.uri.queryParameters['success'] != 'false';
          final orderCode = state.uri.queryParameters['orderCode'] ?? 'DH-2026-9921';
          return PaymentResultScreen(isSuccess: isSuccess, orderCode: orderCode);
        },
      ),
      GoRoute(
        path: '/order-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['orderId'] ??
              state.uri.queryParameters['id'] ??
              state.pathParameters['id'] ??
              (state.extra is String ? state.extra as String : null);
          Order? initialOrder;
          if (state.extra is Order) {
            initialOrder = state.extra as Order;
          } else if (state.extra is Map<String, dynamic>) {
            try {
              initialOrder = Order.fromJson(state.extra as Map<String, dynamic>);
            } catch (_) {}
          }
          return _OrderDetailRouteLoader(
            initialOrder: initialOrder,
            orderId: id,
          );
        },
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ??
                  state.uri.queryParameters['orderId'] ??
                  state.uri.queryParameters['id'] ??
                  (state.extra is String ? state.extra as String : null);
              Order? initialOrder;
              if (state.extra is Order) {
                initialOrder = state.extra as Order;
              } else if (state.extra is Map<String, dynamic>) {
                try {
                  initialOrder = Order.fromJson(state.extra as Map<String, dynamic>);
                } catch (_) {}
              }
              return _OrderDetailRouteLoader(
                initialOrder: initialOrder,
                orderId: id,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),

      // B2B RFQ, Bidding, Contracts, PoD
      GoRoute(
        path: '/create-rfq',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateRfqScreen(),
      ),
      GoRoute(
        path: '/rfq-list',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RfqListScreen(),
      ),
      GoRoute(
        path: '/rfq-detail-bidding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['rfqId'] ??
              state.uri.queryParameters['id'] ??
              state.pathParameters['id'] ??
              (state.extra is String ? state.extra as String : null);
          Rfq? initialRfq;
          if (state.extra is Rfq) {
            initialRfq = state.extra as Rfq;
          } else if (state.extra is Map<String, dynamic>) {
            try {
              initialRfq = Rfq.fromJson(state.extra as Map<String, dynamic>);
            } catch (_) {}
          }
          return _RfqDetailBiddingRouteLoader(
            initialRfq: initialRfq,
            rfqId: id,
          );
        },
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id'] ??
                  state.uri.queryParameters['rfqId'] ??
                  state.uri.queryParameters['id'] ??
                  (state.extra is String ? state.extra as String : null);
              Rfq? initialRfq;
              if (state.extra is Rfq) {
                initialRfq = state.extra as Rfq;
              } else if (state.extra is Map<String, dynamic>) {
                try {
                  initialRfq = Rfq.fromJson(state.extra as Map<String, dynamic>);
                } catch (_) {}
              }
              return _RfqDetailBiddingRouteLoader(
                initialRfq: initialRfq,
                rfqId: id,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/contracts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContractsScreen(),
      ),
      GoRoute(
        path: '/contract-sign',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ContractSignScreen(contractData: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/delivery-pod',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeliveryPoDScreen(),
      ),

      // AI & Notifications
      GoRoute(
        path: '/ai-assistant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Reviews, Wishlist, Public Shop, B2B Chat
      GoRoute(
        path: '/review-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ReviewFormScreen(
            orderId: extra?['orderId']?.toString() ?? state.uri.queryParameters['orderId'],
            orderNumber: extra?['orderNumber']?.toString() ?? state.uri.queryParameters['orderNumber'] ?? 'Đơn mẫu',
            shopName: extra?['shopName']?.toString() ?? state.uri.queryParameters['shopName'] ?? 'Xưởng bánh',
          );
        },
      ),
      GoRoute(
        path: '/reviews/transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ReviewFormScreen(
            orderId: extra?['orderId']?.toString() ?? state.uri.queryParameters['orderId'],
            orderNumber: extra?['orderNumber']?.toString() ?? state.uri.queryParameters['orderNumber'] ?? 'Đơn mẫu',
            shopName: extra?['shopName']?.toString() ?? state.uri.queryParameters['shopName'] ?? 'Xưởng bánh',
          );
        },
      ),
      GoRoute(
        path: '/wishlist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/shop/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return PublicShopScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final threadId = state.uri.queryParameters['threadId'] ?? extra?['threadId']?.toString();
          final shopId = state.uri.queryParameters['shopId'] ?? extra?['shopId']?.toString();
          final shopName = state.uri.queryParameters['shopName'] ?? extra?['shopName']?.toString();
          return ChatScreen(
            threadId: threadId,
            shopId: shopId,
            shopName: shopName,
          );
        },
      ),

      // UI Showcase
      GoRoute(
        path: '/ui-catalog',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UiCatalogScreen(),
      ),

      // Dev Mode Toolbar Sheet
      if (kDebugMode)
        GoRoute(
          path: '/dev-sheet',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const Scaffold(
            body: SafeArea(child: DevModeSheet()),
          ),
        ),
    ],
  );
});

class _RouteLoadingView extends StatelessWidget {
  final String title;

  const _RouteLoadingView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: title, showBack: true),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _RouteErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _RouteErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: title, showBack: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductDetailRouteLoader extends ConsumerStatefulWidget {
  final Product? initialProduct;
  final String? productId;

  const _ProductDetailRouteLoader({
    this.initialProduct,
    this.productId,
  });

  @override
  ConsumerState<_ProductDetailRouteLoader> createState() => _ProductDetailRouteLoaderState();
}

class _ProductDetailRouteLoaderState extends ConsumerState<_ProductDetailRouteLoader> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _product = widget.initialProduct;
      _isLoading = false;
    } else {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      Product? loaded;
      final pId = widget.productId;
      if (pId != null && pId.isNotEmpty) {
        loaded = await catalogRepo.getProductDetails(pId);
      } else {
        final list = await catalogRepo.getProducts(pageSize: 1);
        if (list.isNotEmpty) {
          loaded = list.first;
        }
      }

      if (mounted) {
        if (loaded != null) {
          setState(() {
            _product = loaded;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy thông tin sản phẩm';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _RouteLoadingView(title: 'Chi tiết sản phẩm');
    }
    if (_errorMessage != null || _product == null) {
      return _RouteErrorView(
        title: 'Chi tiết sản phẩm',
        message: _errorMessage ?? 'Không tìm thấy thông tin sản phẩm',
        onRetry: _loadProduct,
      );
    }
    return ProductDetailScreen(product: _product!);
  }
}

class _OrderDetailRouteLoader extends ConsumerStatefulWidget {
  final Order? initialOrder;
  final String? orderId;

  const _OrderDetailRouteLoader({
    this.initialOrder,
    this.orderId,
  });

  @override
  ConsumerState<_OrderDetailRouteLoader> createState() => _OrderDetailRouteLoaderState();
}

class _OrderDetailRouteLoaderState extends ConsumerState<_OrderDetailRouteLoader> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _order = widget.initialOrder;
      _isLoading = false;
    } else {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      Order? loaded;
      final oId = widget.orderId;
      if (oId != null && oId.isNotEmpty) {
        loaded = await orderRepo.getOrderDetails(oId);
      } else {
        final list = await orderRepo.getMyOrders(pageSize: 1);
        if (list.isNotEmpty) {
          loaded = await orderRepo.getOrderDetails(list.first.id);
        }
      }

      if (mounted) {
        if (loaded != null) {
          setState(() {
            _order = loaded;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy thông tin đơn hàng';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _RouteLoadingView(title: 'Chi tiết đơn hàng');
    }
    if (_errorMessage != null || _order == null) {
      return _RouteErrorView(
        title: 'Chi tiết đơn hàng',
        message: _errorMessage ?? 'Không tìm thấy thông tin đơn hàng',
        onRetry: _loadOrder,
      );
    }
    return OrderDetailScreen(order: _order!);
  }
}

class _RfqDetailBiddingRouteLoader extends ConsumerStatefulWidget {
  final Rfq? initialRfq;
  final String? rfqId;

  const _RfqDetailBiddingRouteLoader({
    this.initialRfq,
    this.rfqId,
  });

  @override
  ConsumerState<_RfqDetailBiddingRouteLoader> createState() => _RfqDetailBiddingRouteLoaderState();
}

class _RfqDetailBiddingRouteLoaderState extends ConsumerState<_RfqDetailBiddingRouteLoader> {
  Rfq? _rfq;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialRfq != null) {
      _rfq = widget.initialRfq;
      _isLoading = false;
    } else {
      _loadRfq();
    }
  }

  Future<void> _loadRfq() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rfqRepo = ref.read(rfqRepositoryProvider);
      Rfq? loaded;
      final rId = widget.rfqId;
      if (rId != null && rId.isNotEmpty) {
        loaded = await rfqRepo.getRfqDetails(rId);
      } else {
        final list = await rfqRepo.getMyRfqs(pageSize: 1);
        if (list.isNotEmpty) {
          loaded = await rfqRepo.getRfqDetails(list.first.id);
        }
      }

      if (mounted) {
        if (loaded != null) {
          setState(() {
            _rfq = loaded;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy thông tin yêu cầu báo giá';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _RouteLoadingView(title: 'Chi tiết báo giá RFQ');
    }
    if (_errorMessage != null || _rfq == null) {
      return _RouteErrorView(
        title: 'Chi tiết báo giá RFQ',
        message: _errorMessage ?? 'Không tìm thấy thông tin yêu cầu báo giá',
        onRetry: _loadRfq,
      );
    }
    return RfqDetailBiddingScreen(rfq: _rfq!);
  }
}
