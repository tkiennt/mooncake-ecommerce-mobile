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

  static String get hubUrl => '$baseUrl/hubs/notifications';
  static String get chatHubUrl => '$baseUrl/hubs/chat';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String googleLogin = '/auth/google/login';
  static const String googleAuthorizationUrl = '/auth/google/authorization-url';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // User Profile
  static const String usersMe = '/users/me';
  static const String profileAvatar = '/users/me/avatar';

  // Catalog & Products
  static const String products = '/products';
  static String productDetails(String id) => '/products/$id';
  static const String categories = '/categories';
  static const String recommendations = '/products/recommendations';
  static String relatedProducts(String id) => '/products/$id/related';
  static const String autocomplete = '/products/autocomplete';
  static String recordProductView(String id) => '/products/$id/views';

  // Orders & Payment
  static const String createOrder = '/orders';
  static const String myOrders = '/orders/mine';
  static const String myOrdersPaged = '/orders/mine/paged';
  static String orderDetails(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';
  static const String quotePreview = '/orders/quote-preview';
  static const String orderPreview = '/orders/preview';
  static String shopPolicy(String shopId) => '/orders/shops/$shopId/policy';
  static String confirmOrderDeliveryReceipt(String id) => '/orders/$id/delivery/confirm-receipt';
  static String orderDispute(String id) => '/orders/$id/delivery/dispute';
  static String orderPaymentSummary(String id) => '/orders/$id/payment-summary';
  static String orderPartVnPayUrl(String orderId, String partId) =>
      '/orders/$orderId/payment-parts/$partId/vnpay-url';

  // Payments
  static const String createPayment = '/payments';
  static const String myPayments = '/payments/mine';
  static const String orderVnPayUrl = '/payments/orders/vnpay-url';
  static const String contractVnPayUrl = '/payments/contracts/vnpay-url';
  static const String vnpayReturn = '/payments/vnpay/return-callback';

  // B2B & RFQ
  static const String myRfqs = '/rfqs/mine';
  static const String createRfq = '/rfqs';
  static String rfqDetails(String id) => '/rfqs/$id';
  static String rfqPublish(String id) => '/rfqs/$id/publish';
  static String rfqCancel(String id) => '/rfqs/$id/cancel';
  static String rfqBids(String id) => '/rfqs/$id/bids';
  static String rfqAcceptBid(String rfqId, String bidId) => '/rfqs/$rfqId/bids/$bidId/accept';
  static String rfqSuggestedSuppliers(String id) => '/rfqs/$id/suggested-suppliers';

  // Contracts
  static const String myContracts = '/contracts/mine';
  static String contractDetails(String id) => '/contracts/$id';
  static String contractSignatureOtp(String id) => '/contracts/$id/signature-otp';
  static String signContract(String id) => '/contracts/$id/sign';
  static String contractMilestones(String id) => '/contracts/$id/milestones';
  static String verifyContractMilestone(String contractId, String milestoneId) =>
      '/contracts/$contractId/milestones/$milestoneId/verify';
  static String contractFulfillment(String contractId) =>
      '/deliveries/contract/$contractId/fulfillment';

  // Deliveries & PoD
  static const String deliveries = '/deliveries';
  static String deliveryDetails(String id) => '/deliveries/$id';
  static String deliveriesByOrder(String orderId) => '/deliveries/order/$orderId';
  static String deliveriesByContract(String contractId) => '/deliveries/contract/$contractId';
  static String deliveryProofs(String deliveryId) => '/deliveries/$deliveryId/proofs';
  static String deliveryProofVerify(String proofId) => '/deliveries/proofs/$proofId/verify';
  static String deliveryDriver(String id) => '/deliveries/$id/driver';
  static String deliveryShareCode(String code) => '/deliveries/public/code/$code';
  static String deliveryClaim(String token) => '/deliveries/public/$token/claim';
  static String deliveryPublic(String token) => '/deliveries/public/$token';

  // Custom Packaging
  static String customPackaging(String orderId) =>
      '/orders/$orderId/custom-packaging';
  static String customPackagingReview(String orderId, String revisionId) =>
      '/orders/$orderId/custom-packaging/revisions/$revisionId/review';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String notificationPreferences = '/notifications/preferences';

  // Wishlist
  static const String wishlist = '/wishlist';
  static String wishlistToggle(String productId) => '/wishlist/$productId';
  static const String wishlistCheck = '/wishlist/check';

  // Public Shops
  static String shop(String slug) => '/shops/$slug';
  static String shopProducts(String slug) => '/shops/$slug/products';
  static String shopCategories(String slug) => '/shops/$slug/categories';
  static String shopReviews(String slug) => '/shops/$slug/reviews';

  // Reviews
  static const String reviewsTransaction = '/reviews/transaction';
  static const String reviewsEligibleOrders = '/reviews/transaction/eligible-orders';
  static String reviewsTransactionReply(String id) => '/reviews/transaction/$id/reply';
  static String shopReviewsFeed(String slug) => '/reviews/shops/$slug';
  static String productReviews(String productId) => '/products/$productId/reviews';
  static String productEligibleOrderItems(String productId) =>
      '/products/$productId/eligible-order-items';
  static String productReviewLike(String reviewId) => '/products/reviews/$reviewId/like';

  // Chat
  static const String chatThreads = '/chat/threads';
  static String chatThread(String id) => '/chat/threads/$id';
  static String chatMessages(String threadId) => '/chat/threads/$threadId/messages';
  static String chatMessage(String messageId) => '/chat/messages/$messageId';
  static String chatRead(String threadId) => '/chat/threads/$threadId/read';
  static const String chatUnreadCount = '/chat/unread-count';

  // AI Chat
  static const String aiChatSessions = '/ai/chat/sessions';
  static const String aiChatMessages = '/ai/chat/messages';
  static String aiChatHistory(String sessionToken) => '/ai/chat/sessions/$sessionToken/history';
  static String aiChatEnd(String sessionToken) => '/ai/chat/sessions/$sessionToken';
}
