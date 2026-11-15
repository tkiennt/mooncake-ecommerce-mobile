import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/order.dart';
import '../models/order_quote.dart';

class OrderRepository {
  final ApiClient _client;

  OrderRepository(this._client);

  /// Computes authoritative quote preview (discounts, tax, deposit, shipping)
  Future<OrderQuotePreview> previewQuote({
    required String shopId,
    required List<Map<String, dynamic>> items,
    String? shippingZoneCode,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.quotePreview,
        data: {
          'shopId': shopId,
          'items': items,
          if (shippingZoneCode != null) 'shippingZoneCode': shippingZoneCode,
        },
      );
      final data = ApiClient.unwrap(response);
      return OrderQuotePreview.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets shop's bulk ordering policy (minimum order, deposit rate, shipping fees)
  Future<Map<String, dynamic>> getShopPolicy(String shopId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.shopPolicy(shopId));
      final data = ApiClient.unwrap(response);
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Creates a new bulk direct order
  Future<Order> createOrder(
    Map<String, dynamic> request, {
    String? idempotencyKey,
  }) async {
    try {
      final options = idempotencyKey != null
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null;

      final response = await _client.dio.post(
        ApiEndpoints.createOrder,
        data: request,
        options: options,
      );
      final data = ApiClient.unwrap(response);
      return Order.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets customer's orders list
  Future<List<Order>> getMyOrders({
    int? page,
    int? pageSize,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (page != null) 'page': page,
        if (pageSize != null) 'pageSize': pageSize,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _client.dio.get(
        ApiEndpoints.myOrders,
        queryParameters: queryParams,
      );

      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((o) => Order.fromJson(
              o is Map<String, dynamic> ? o : Map<String, dynamic>.from(o as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets full order details with timeline, items and payment breakdown
  Future<Order> getOrderDetails(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.orderDetails(id));
      final data = ApiClient.unwrap(response);
      return Order.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Cancels an order
  Future<void> cancelOrder(String id, {String? reason}) async {
    try {
      await _client.dio.post(
        ApiEndpoints.cancelOrder(id),
        data: {if (reason != null) 'reason': reason},
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Confirms delivery receipt on client side
  Future<void> confirmDeliveryReceipt(String id, {Map<String, dynamic>? payload}) async {
    try {
      await _client.dio.post(
        ApiEndpoints.confirmOrderDeliveryReceipt(id),
        data: payload ?? {},
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Reports a dispute for an order delivery
  Future<void> reportDispute(String id, {required String reason, String? notes}) async {
    try {
      await _client.dio.post(
        ApiEndpoints.orderDispute(id),
        data: {
          'reason': reason,
          if (notes != null) 'notes': notes,
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Generates VNPay payment URL for full/deposit order payment
  Future<String> createOrderVnPayUrl({
    required String orderId,
    String? returnUrl,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.orderVnPayUrl,
        data: {
          'orderId': orderId,
          if (returnUrl != null) 'returnUrl': returnUrl,
        },
      );
      final data = ApiClient.unwrap(response);
      return data['paymentUrl']?.toString() ?? data['url']?.toString() ?? data.toString();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Generates VNPay payment URL for a split payment part
  Future<String> createPartVnPayUrl(
    String orderId,
    String partId, {
    String? returnUrl,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.orderPartVnPayUrl(orderId, partId),
        data: {if (returnUrl != null) 'returnUrl': returnUrl},
      );
      final data = ApiClient.unwrap(response);
      return data['paymentUrl']?.toString() ?? data['url']?.toString() ?? data.toString();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets payment summary schedule & obligations
  Future<Map<String, dynamic>> getPaymentSummary(String orderId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.orderPaymentSummary(orderId));
      final data = ApiClient.unwrap(response);
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OrderRepository(client);
});
