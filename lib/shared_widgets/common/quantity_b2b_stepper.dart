import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class QuantityB2BStepper extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final List<int> quickTiers;
  final bool showQuickChips;
  final String unit;
  final bool enabled;

  const QuantityB2BStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100000,
    this.step = 1,
    this.quickTiers = const [50, 100, 200, 500],
    this.showQuickChips = true,
    this.unit = 'hộp',
    this.enabled = true,
  });

  @override
  State<QuantityB2BStepper> createState() => _QuantityB2BStepperState();
}

class _QuantityB2BStepperState extends State<QuantityB2BStepper> {
  void _update(int val) {
    if (!widget.enabled) return;
    final clamped = val.clamp(widget.min, widget.max);
    if (clamped != widget.value) {
      widget.onChanged(clamped);
    }
  }

  void _showDirectInputDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.value.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        title: Text(
          'Nhập số lượng (${widget.unit})',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tối thiểu ${widget.min}',
            suffixText: widget.unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) {
                _update(parsed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stepper Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minus Button (tap target >= 44px)
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              child: InkWell(
                onTap: widget.enabled && widget.value > widget.min
                    ? () => _update(widget.value - widget.step)
                    : null,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                child: Container(
                  width: AppTokens.minTapTarget,
                  height: AppTokens.minTapTarget,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                    border: Border.all(
                      color: widget.enabled && widget.value > widget.min
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 20,
                    color: widget.enabled && widget.value > widget.min
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spaceXS),

            // Number Input Display (tap to edit)
            InkWell(
              onTap: widget.enabled ? () => _showDirectInputDialog(context) : null,
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              child: Container(
                constraints: const BoxConstraints(minWidth: 64),
                height: AppTokens.minTapTarget,
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Center(
                  child: Text(
                    '${widget.value}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spaceXS),

            // Plus Button (tap target >= 44px)
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusInput),
              child: InkWell(
                onTap: widget.enabled && widget.value < widget.max
                    ? () => _update(widget.value + widget.step)
                    : null,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                child: Container(
                  width: AppTokens.minTapTarget,
                  height: AppTokens.minTapTarget,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                    border: Border.all(
                      color: widget.enabled && widget.value < widget.max
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 20,
                    color: widget.enabled && widget.value < widget.max
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Quick wholesale chips (D14: 50 / 100 / 200 / 500)
        if (widget.showQuickChips && widget.quickTiers.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spaceSM),
          Wrap(
            spacing: AppTokens.spaceXS,
            runSpacing: AppTokens.spaceXS,
            children: widget.quickTiers.map((tier) {
              final isSelected = widget.value == tier;
              return Material(
                color: isSelected ? AppColors.accentGoldBg : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                child: InkWell(
                  onTap: widget.enabled ? () => _update(tier) : null,
                  borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    constraints: const BoxConstraints(minHeight: 32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                        width: isSelected ? 1.4 : 0.8,
                      ),
                    ),
                    child: Text(
                      '$tier ${widget.unit}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
