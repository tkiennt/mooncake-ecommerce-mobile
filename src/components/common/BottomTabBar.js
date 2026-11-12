import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';

const TAB_META = {
  HomeTab: { label: 'Trang chủ', icon: 'home-outline', activeIcon: 'home' },
  SearchTab: { label: 'Khám phá', icon: 'compass-outline', activeIcon: 'compass' },
  CartTab: { label: 'Giỏ hàng', icon: 'cart-outline', activeIcon: 'cart' },
  OrdersTab: { label: 'Đơn hàng', icon: 'receipt-outline', activeIcon: 'receipt' },
  ProfileTab: { label: 'Tài khoản', icon: 'person-outline', activeIcon: 'person' },
};

/**
 * Flat bottom tab bar. Tabs are driven by the navigator's own routes, so the highlighted tab
 * is always the one that was pressed (the previous notched bar kept its own tab list and a
 * window width captured at load, which drifted after resizing).
 */
export default function BottomTabBar({ state, descriptors, navigation, cartBadgeCount = 0 }) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.bar, { paddingBottom: Math.max(insets.bottom, 6) }]}>
      {state.routes.map((route, index) => {
        const meta = TAB_META[route.name] || { label: route.name, icon: 'ellipse-outline', activeIcon: 'ellipse' };
        const { options } = descriptors[route.key];
        const label = options.tabBarLabel || meta.label;
        const focused = state.index === index;
        const badge = route.name === 'CartTab' ? cartBadgeCount : 0;

        const onPress = () => {
          const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
          if (!focused && !event.defaultPrevented) navigation.navigate(route.name);
        };

        return (
          <TouchableOpacity
            key={route.key}
            style={styles.tab}
            onPress={onPress}
            activeOpacity={0.7}
            accessibilityRole="tab"
            accessibilityState={{ selected: focused }}
            accessibilityLabel={label}
          >
            <View>
              <Ionicons
                name={focused ? meta.activeIcon : meta.icon}
                size={24}
                color={focused ? COLORS.primary : COLORS.textSecondary}
              />
              {badge > 0 && (
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>{badge > 99 ? '99+' : badge}</Text>
                </View>
              )}
            </View>
            <Text style={[styles.label, focused && styles.labelActive]} numberOfLines={1}>
              {label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    backgroundColor: COLORS.surface,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: COLORS.borderDark,
    paddingTop: 6,
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  label: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  labelActive: {
    color: COLORS.primary,
    fontWeight: '600',
  },
  badge: {
    position: 'absolute',
    top: -4,
    right: -10,
    minWidth: 18,
    height: 18,
    paddingHorizontal: 4,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: COLORS.primary,
    borderWidth: 1.5,
    borderColor: COLORS.surface,
  },
  badgeText: {
    color: COLORS.textWhite,
    fontSize: 10,
    fontWeight: '700',
  },
});
