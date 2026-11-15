import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum MilestoneStepStatus {
  completed,
  current,
  upcoming,
  failed,
}

class MilestoneItem {
  final String title;
  final String? subtitle;
  final String? timestamp;
  final IconData? icon;
  final MilestoneStepStatus status;

  const MilestoneItem({
    required this.title,
    this.subtitle,
    this.timestamp,
    this.icon,
    this.status = MilestoneStepStatus.upcoming,
  });
}

class MilestoneTimeline extends StatelessWidget {
  final List<MilestoneItem> items;
  final Axis orientation;
  final EdgeInsets padding;

  const MilestoneTimeline({
    super.key,
    required this.items,
    this.orientation = Axis.horizontal,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTokens.spaceLG,
      vertical: AppTokens.spaceMD,
    ),
  });

  @override
  Widget build(BuildContext context) {
    if (orientation == Axis.horizontal) {
      return _buildHorizontalTimeline();
    }
    return _buildVerticalTimeline();
  }

  Widget _buildHorizontalTimeline() {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNode(item),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11.5,
                          fontWeight: item.status == MilestoneStepStatus.current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _getTextColor(item.status),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.timestamp != null && item.timestamp!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.timestamp!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: SizedBox(
                      width: 16,
                      child: Divider(
                        thickness: 2,
                        color: items[index + 1].status == MilestoneStepStatus.completed ||
                                item.status == MilestoneStepStatus.completed
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVerticalTimeline() {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildNode(item),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: items[index + 1].status == MilestoneStepStatus.completed ||
                              item.status == MilestoneStepStatus.completed
                          ? AppColors.success
                          : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: item.status == MilestoneStepStatus.current
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: _getTextColor(item.status),
                              ),
                            ),
                          ),
                          if (item.timestamp != null)
                            Text(
                              item.timestamp!,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNode(MilestoneItem item) {
    Color bg;
    Color fg;
    Widget iconWidget;

    switch (item.status) {
      case MilestoneStepStatus.completed:
        bg = AppColors.successBg;
        fg = AppColors.success;
        iconWidget = Icon(Icons.check, size: 14, color: fg);
        break;
      case MilestoneStepStatus.current:
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
        iconWidget = Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
        );
        break;
      case MilestoneStepStatus.failed:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        iconWidget = Icon(Icons.close, size: 14, color: fg);
        break;
      case MilestoneStepStatus.upcoming:
        bg = AppColors.surfaceHover;
        fg = AppColors.borderDark;
        iconWidget = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
        );
        break;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg, width: 1.5),
      ),
      child: Center(
        child: item.icon != null
            ? Icon(item.icon, size: 14, color: fg)
            : iconWidget,
      ),
    );
  }

  Color _getTextColor(MilestoneStepStatus status) {
    switch (status) {
      case MilestoneStepStatus.completed:
        return AppColors.textPrimary;
      case MilestoneStepStatus.current:
        return AppColors.primary;
      case MilestoneStepStatus.failed:
        return AppColors.error;
      case MilestoneStepStatus.upcoming:
        return AppColors.textMuted;
    }
  }
}
