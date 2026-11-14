import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BottomTabBarItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const BottomTabBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class BottomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartBadgeCount;

  const BottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartBadgeCount = 0,
  });

  static const List<BottomTabBarItem> tabs = [
    BottomTabBarItem(
      label: 'Trang chủ',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    BottomTabBarItem(
      label: 'Khám phá',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    BottomTabBarItem(
      label: 'Giỏ hàng',
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
    ),
    BottomTabBarItem(
      label: 'Đơn hàng',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
    ),
    BottomTabBarItem(
      label: 'Tài khoản',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isFocused = currentIndex == index;
              final isCart = index == 2;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isFocused ? tab.activeIcon : tab.icon,
                            color: isFocused ? AppColors.primary : AppColors.textSecondary,
                            size: 24,
                          ),
                          if (isCart && cartBadgeCount > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surface, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  cartBadgeCount > 99 ? '99+' : '$cartBadgeCount',
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                          color: isFocused ? AppColors.primary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
