import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import 'app_product_card.dart';

/// Adapter giữ nguyên API cũ của ProductGridCard để các màn khác không vỡ,
/// ủy quyền hiển thị sang AppProductCard dùng chung.
class ProductGridCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product>? onPress;
  final double imageRatio;

  const ProductGridCard({
    super.key,
    required this.product,
    this.onPress,
    this.imageRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppProductCard(
      product: product,
      onPress: onPress,
      imageRatio: imageRatio,
    );
  }
}
