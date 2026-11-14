import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StepItemData {
  final String title;
  final String? desc;

  const StepItemData({required this.title, this.desc});
}

class AntdSteps extends StatelessWidget {
  final int current;
  final List<StepItemData> items;
  final Axis direction;

  const AntdSteps({
    super.key,
    required this.current,
    required this.items,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.vertical) {
      return Column(
        children: List.generate(items.length, (index) => _buildVerticalStep(index)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) => _buildHorizontalStep(index)),
    );
  }

  Widget _buildHorizontalStep(int index) {
    final item = items[index];
    final isFinish = index < current;
    final isProcess = index == current;
    final isLast = index == items.length - 1;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: index == 0 ? Colors.transparent : (isFinish || isProcess ? AppColors.primary : AppColors.border),
                ),
              ),
              _buildCircle(index, isFinish, isProcess),
              Expanded(
                child: Container(
                  height: 2,
                  color: isLast ? Colors.transparent : (isFinish ? AppColors.primary : AppColors.border),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isProcess ? FontWeight.bold : FontWeight.w500,
              color: isProcess ? AppColors.primary : (isFinish ? AppColors.textPrimary : AppColors.textMuted),
            ),
            textAlign: TextAlign.center,
          ),
          if (item.desc != null)
            Text(
              item.desc!,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalStep(int index) {
    final item = items[index];
    final isFinish = index < current;
    final isProcess = index == current;
    final isLast = index == items.length - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildCircle(index, isFinish, isProcess),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isFinish ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isProcess ? FontWeight.bold : FontWeight.w600,
                    color: isProcess ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (item.desc != null)
                  Text(
                    item.desc!,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircle(int index, bool isFinish, bool isProcess) {
    if (isFinish) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: AppColors.textWhite),
      );
    }

    if (isProcess) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
