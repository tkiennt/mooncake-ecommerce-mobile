import 'product.dart';

class CartItem {
  final Product product;
  final ProductVariant? variant;
  int quantity;
  final String? note;

  CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
    this.note,
  });

  double get unitPrice => product.basePrice + (variant?.priceAdjustment ?? 0);
  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}
