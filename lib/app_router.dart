import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'shared_widgets/common/bottom_tab_bar.dart';
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

import 'data/models/product.dart';
import 'data/models/order.dart';
import 'data/models/rfq.dart';
import 'providers/catalog_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final cartTotals = ref.watch(cartProvider).totals;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
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
        builder: (context, state) => VerifyEmailScreen(identifier: state.extra as String?),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ResetPasswordScreen(phoneNumber: state.extra as String?),
      ),

      // Product & Checkout
      GoRoute(
        path: '/product-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final product = state.extra is Product
              ? state.extra as Product
              : CatalogNotifier.mockCatalog[0];
          return ProductDetailScreen(product: product);
        },
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
          final order = state.extra as Order;
          return OrderDetailScreen(order: order);
        },
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
          final rfq = state.extra as Rfq;
          return RfqDetailBiddingScreen(rfq: rfq);
        },
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

      // UI Showcase
      GoRoute(
        path: '/ui-catalog',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UiCatalogScreen(),
      ),
    ],
  );
});
