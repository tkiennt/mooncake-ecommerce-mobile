import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../data/models/cart_item.dart';
import '../data/models/order_quote.dart';
import '../data/models/product.dart';

class CartTotals {
  final int totalItems;
  final double subtotal;
  final double discountAmount;
  final double finalAmount;
  final double taxAmount;
  final double shippingFee;
  final double depositAmount;
  final bool depositRequired;

  const CartTotals({
    required this.totalItems,
    required this.subtotal,
    required this.discountAmount,
    required this.finalAmount,
    this.taxAmount = 0.0,
    this.shippingFee = 0.0,
    this.depositAmount = 0.0,
    this.depositRequired = false,
  });
}

class CartState {
  final List<CartItem> items;
  final String? appliedCoupon;
  final double couponDiscountPercent;
  final OrderQuotePreview? serverQuote;
  final bool isCalculatingQuote;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.couponDiscountPercent = 0.0,
    this.serverQuote,
    this.isCalculatingQuote = false,
  });

  CartTotals get totals {
    if (serverQuote != null) {
      int totalItems = items.fold(0, (sum, i) => sum + i.quantity);
      return CartTotals(
        totalItems: totalItems,
        subtotal: serverQuote!.subtotal,
        discountAmount: serverQuote!.totalDiscount,
        finalAmount: serverQuote!.payableTotal,
        taxAmount: serverQuote!.taxAmount,
        shippingFee: serverQuote!.shippingFee,
        depositAmount: serverQuote!.depositAmount,
        depositRequired: serverQuote!.depositRequired,
      );
    }

    int totalItems = 0;
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    for (var item in items) {
      totalItems += item.quantity;
      final itemSubtotal = item.subtotal;
      subtotal += itemSubtotal;

      // Tier discount calculation from product tier pricing
      double tierDiscountPercent = 0.0;
      for (var tier in item.product.tierPricing) {
        if (item.quantity >= tier.minQty) {
          if (tier.maxQty == null || item.quantity <= tier.maxQty!) {
            tierDiscountPercent = tier.discountPercent;
            break;
          }
        }
      }

      totalDiscount += itemSubtotal * (tierDiscountPercent / 100);
    }

    // Apply Coupon if any
    if (couponDiscountPercent > 0) {
      totalDiscount += (subtotal - totalDiscount) * (couponDiscountPercent / 100);
    }

    final finalAmount = (subtotal - totalDiscount).clamp(0.0, double.infinity);

    return CartTotals(
      totalItems: totalItems,
      subtotal: subtotal,
      discountAmount: totalDiscount,
      finalAmount: finalAmount,
    );
  }

  CartState copyWith({
    List<CartItem>? items,
    String? appliedCoupon,
    double? couponDiscountPercent,
    OrderQuotePreview? serverQuote,
    bool? isCalculatingQuote,
    bool clearServerQuote = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      couponDiscountPercent: couponDiscountPercent ?? this.couponDiscountPercent,
      serverQuote: clearServerQuote ? null : (serverQuote ?? this.serverQuote),
      isCalculatingQuote: isCalculatingQuote ?? this.isCalculatingQuote,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addToCart(Product product, ProductVariant? variant, int quantity) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id && item.variant?.id == variant?.id,
    );

    if (existingIndex > -1) {
      final updated = [...state.items];
      updated[existingIndex].quantity += quantity;
      state = state.copyWith(items: updated, clearServerQuote: true);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, variant: variant, quantity: quantity)],
        clearServerQuote: true,
      );
    }
  }

  void updateQuantity(String productId, String? variantId, int newQty) {
    if (newQty <= 0) {
      removeFromCart(productId, variantId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.product.id == productId && item.variant?.id == variantId) {
          return item.copyWith(quantity: newQty);
        }
        return item;
      }).toList(),
      clearServerQuote: true,
    );
  }

  void removeFromCart(String productId, String? variantId) {
    state = state.copyWith(
      items: state.items
          .where((item) => !(item.product.id == productId && item.variant?.id == variantId))
          .toList(),
      clearServerQuote: true,
    );
  }

  void applyCoupon(String code) {
    if (code == 'B2BMOON2026') {
      state = state.copyWith(appliedCoupon: code, couponDiscountPercent: 10.0);
    }
  }

  void removeCoupon() {
    state = state.copyWith(appliedCoupon: null, couponDiscountPercent: 0.0);
  }

  void clearCart() {
    state = const CartState();
  }

  /// Synchronizes with backend quote-preview API for server-authoritative calculations
  Future<OrderQuotePreview?> syncServerQuote(
    ApiClient apiClient, {
    String? shippingZoneCode,
  }) async {
    if (state.items.isEmpty) return null;

    final firstShopId = state.items.first.product.shopId;
    if (firstShopId == null || firstShopId.isEmpty) return null;

    state = state.copyWith(isCalculatingQuote: true);
    try {
      final payload = {
        'shopId': firstShopId,
        'items': state.items
            .map((item) => {
                  'productId': item.product.id,
                  'variantId': item.variant?.id ?? '',
                  'quantity': item.quantity,
                })
            .toList(),
        if (shippingZoneCode != null) 'shippingZoneCode': shippingZoneCode,
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.quotePreview,
        data: payload,
      );

      final data = ApiClient.unwrap(response);
      final quote = OrderQuotePreview.fromJson(data as Map<String, dynamic>);
      state = state.copyWith(
        serverQuote: quote,
        isCalculatingQuote: false,
      );
      return quote;
    } catch (_) {
      state = state.copyWith(isCalculatingQuote: false);
      return null;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
