import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item.dart';
import '../data/models/product.dart';

class CartTotals {
  final int totalItems;
  final double subtotal;
  final double discountAmount;
  final double finalAmount;

  const CartTotals({
    required this.totalItems,
    required this.subtotal,
    required this.discountAmount,
    required this.finalAmount,
  });
}

class CartState {
  final List<CartItem> items;
  final String? appliedCoupon;
  final double couponDiscountPercent;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.couponDiscountPercent = 0.0,
  });

  CartTotals get totals {
    int totalItems = 0;
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    for (var item in items) {
      totalItems += item.quantity;
      final itemSubtotal = item.subtotal;
      subtotal += itemSubtotal;

      // Tier discount calculation
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
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      couponDiscountPercent: couponDiscountPercent ?? this.couponDiscountPercent,
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
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, variant: variant, quantity: quantity)],
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
    );
  }

  void removeFromCart(String productId, String? variantId) {
    state = state.copyWith(
      items: state.items.where((item) => !(item.product.id == productId && item.variant?.id == variantId)).toList(),
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
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
