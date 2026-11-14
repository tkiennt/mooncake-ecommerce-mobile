import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:8089/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8089/api/v1';
    return 'http://localhost:8089/api/v1';
  }

  static String get hubUrl => '${baseUrl.replaceAll('/api/v1', '')}/hubs/notifications';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String googleLogin = '/auth/google/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Catalog
  static const String products = '/products';
  static String productDetails(String id) => '/products/$id';
  static const String categories = '/categories';
  static const String recommendations = '/products/recommendations';

  // Orders & Payment
  static const String createOrder = '/orders';
  static const String myOrders = '/orders/mine';
  static String orderDetails(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';
  static const String createPayment = '/payments';
  static const String myPayments = '/payments/mine';

  // B2B & RFQ
  static const String myRfqs = '/rfqs/mine';
  static const String createRfq = '/rfqs';
  static String rfqDetails(String id) => '/rfqs/$id';
  static String rfqBids(String id) => '/rfqs/$id/bids';
  static String rfqAcceptBid(String rfqId, String bidId) => '/rfqs/$rfqId/bids/$bidId/accept';

  // Contracts
  static const String myContracts = '/contracts/mine';
  static String contractDetails(String id) => '/contracts/$id';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // AI Chat
  static const String aiChatSessions = '/ai/chat/sessions';
  static const String aiChatMessages = '/ai/chat/messages';
}
