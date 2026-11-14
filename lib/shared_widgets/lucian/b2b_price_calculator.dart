import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class B2BCalculationResult {
  final int quantity;
  final double effectiveDiscount;
  final double discountedUnitPrice;
  final double totalCost;
  final double totalSavings;

  const B2BCalculationResult({
    required this.quantity,
    required this.effectiveDiscount,
    required this.discountedUnitPrice,
    required this.totalCost,
    required this.totalSavings,
  });
}

class B2BPriceCalculator extends StatefulWidget {
  final double baseRetailPrice;
  final int initialQuantity;
  final ValueChanged<B2BCalculationResult>? onApplyTier;

  const B2BPriceCalculator({
    super.key,
    this.baseRetailPrice = 450000,
    this.initialQuantity = 80,
    this.onApplyTier,
  });

  @override
  State<B2BPriceCalculator> createState() => _B2BPriceCalculatorState();
}

class _B2BPriceCalculatorState extends State<B2BPriceCalculator> {
  late int _quantity;
  bool _isEarlyBird = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  double get _baseDiscount {
    if (_quantity >= 200) return 35.0;
    if (_quantity >= 50) return 20.0;
    return 10.0;
  }

  double get _effectiveDiscount => _baseDiscount + (_isEarlyBird ? 5.0 : 0.0);

  double get _discountedUnitPrice =>
      (widget.baseRetailPrice * (1 - _effectiveDiscount / 100)).roundToDouble();

  double get _totalCost => _discountedUnitPrice * _quantity;

  double get _totalSavings =>
      (widget.baseRetailPrice - _discountedUnitPrice) * _quantity;

  void _adjustQty(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(20, 500);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bảng Tính Chiết Khấu Doanh Nghiệp',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Giảm tới 35%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quantity controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số lượng đặt mua:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Row(
                children: [
                  _QtyButton(icon: Icons.remove, onPressed: () => _adjustQty(-10)),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$_quantity hộp',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  _QtyButton(icon: Icons.add, onPressed: () => _adjustQty(10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.accent,
              trackHeight: 4,
            ),
            child: Slider(
              value: _quantity.toDouble(),
              min: 20,
              max: 500,
              onChanged: (val) {
                setState(() {
                  _quantity = val.toInt();
                });
              },
            ),
          ),

          // Tier quick buttons
          Row(
            children: [
              _TierChip(label: '20-49 (-10%)', isSelected: _quantity < 50, onTap: () => setState(() => _quantity = 30)),
              const SizedBox(width: 6),
              _TierChip(label: '50-199 (-20%)', isSelected: _quantity >= 50 && _quantity < 200, onTap: () => setState(() => _quantity = 100)),
              const SizedBox(width: 6),
              _TierChip(label: '200+ (-35%)', isSelected: _quantity >= 200, onTap: () => setState(() => _quantity = 250)),
            ],
          ),
          const SizedBox(height: 12),

          // Early bird switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, size: 16, color: AppColors.accent),
                    SizedBox(width: 6),
                    Text(
                      'Đặt cọc sớm trước 15/07 (+5%)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ],
                ),
                Switch(
                  value: _isEarlyBird,
                  activeColor: AppColors.accent,
                  onChanged: (val) => setState(() => _isEarlyBird = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Summary Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Chiết khấu thực tế:', value: '-${_effectiveDiscount.toInt()}%', isHighlight: true),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Đơn giá sau giảm:', value: _formatCurrency(_discountedUnitPrice)),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tiết kiệm được:', value: _formatCurrency(_totalSavings), valueColor: AppColors.success),
                const Divider(height: 16, color: AppColors.border),
                _SummaryRow(
                  label: 'Tổng tiền dự kiến:',
                  value: _formatCurrency(_totalCost),
                  isBold: true,
                  valueColor: AppColors.primary,
                  fontSize: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          ElevatedButton(
            onPressed: () {
              widget.onApplyTier?.call(B2BCalculationResult(
                quantity: _quantity,
                effectiveDiscount: _effectiveDiscount,
                discountedUnitPrice: _discountedUnitPrice,
                totalCost: _totalCost,
                totalSavings: _totalSavings,
              ));
            },
            child: const Text('Áp Dụng Mức Giá Này'),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(icon, size: 14, color: AppColors.primary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTint : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isHighlight;
  final Color? valueColor;
  final double fontSize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isHighlight = false,
    this.valueColor,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: valueColor ?? (isHighlight ? AppColors.primary : AppColors.textPrimary),
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
