// Lucian UX/UI Prompt #041 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#041
import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Animated,
  useWindowDimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { LUCIAN_TOKENS } from '../../theme/tokens';

export default function NotchedTabBar({
  state,
  descriptors,
  navigation,
  // Fallback for standalone demo in UiCatalogScreen
  activeIdx = 0,
  onSelectTab,
  cartBadgeCount = 0,
}) {
  const isNavControlled = Boolean(state && navigation);
  const currentIdx = isNavControlled ? state.index : activeIdx;

  const tabs = [
    { key: 'HomeTab', name: 'HomeTab', label: 'Trang chủ', icon: 'home-outline', activeIcon: 'home' },
    { key: 'SearchTab', name: 'SearchTab', label: 'Khám phá', icon: 'search-outline', activeIcon: 'search' },
    { key: 'CartTab', name: 'CartTab', label: 'Giỏ hàng', icon: 'cart-outline', activeIcon: 'cart', badge: cartBadgeCount },
    { key: 'OrdersTab', name: 'OrdersTab', label: 'Đơn hàng', icon: 'receipt-outline', activeIcon: 'receipt' },
    { key: 'ProfileTab', name: 'ProfileTab', label: 'Doanh nghiệp', icon: 'business-outline', activeIcon: 'business' },
  ];

  // Position the bubble from the bar's measured width, not a width captured once at module load:
  // after a rotation or window resize the old width put the bubble under the wrong tab (or off-screen).
  const { width: windowWidth } = useWindowDimensions();
  const [barWidth, setBarWidth] = useState(0);
  const tabWidth = (barWidth || windowWidth) / tabs.length;
  const bubbleOffset = (idx) => idx * tabWidth + tabWidth / 2 - BUBBLE_SIZE / 2;
  const bubbleX = useRef(new Animated.Value(bubbleOffset(currentIdx))).current;
  const hasPositioned = useRef(false);
  const iconTranslateYs = useRef(tabs.map(() => new Animated.Value(0))).current;

  useEffect(() => {
    // Jump straight to place on first measure / resize; spring only when the user switches tabs.
    if (!hasPositioned.current || !barWidth) {
      bubbleX.setValue(bubbleOffset(currentIdx));
      hasPositioned.current = Boolean(barWidth);
    } else {
      Animated.spring(bubbleX, {
        toValue: bubbleOffset(currentIdx),
        useNativeDriver: true,
        friction: 6,
        tension: 60,
      }).start();
    }

    // Lift icon animation for active tab, return others
    tabs.forEach((_, idx) => {
      Animated.spring(iconTranslateYs[idx], {
        toValue: idx === currentIdx ? -14 : 0,
        useNativeDriver: true,
        friction: 6,
      }).start();
    });
  }, [currentIdx, tabWidth]); // eslint-disable-line react-hooks/exhaustive-deps

  const handlePress = (idx, tab) => {
    if (isNavControlled) {
      const event = navigation.emit({
        type: 'tabPress',
        target: state.routes[idx].key,
        canPreventDefault: true,
      });

      if (currentIdx !== idx && !event.defaultPrevented) {
        navigation.navigate(state.routes[idx].name);
      }
    } else if (onSelectTab) {
      onSelectTab(idx);
    }
  };

  return (
    <View style={styles.container}>
      {/* Background Tab Bar with Top Notch Illusion */}
      <View style={styles.barBackground} onLayout={(event) => setBarWidth(event.nativeEvent.layout.width)}>
        {/* Sliding Round Bubble (#041) */}
        <Animated.View
          style={[
            styles.floatingBubble,
            {
              transform: [{ translateX: bubbleX }],
            },
          ]}
        />

        {/* Tab Items */}
        <View style={styles.tabsRow}>
          {tabs.map((tab, idx) => {
            const isSelected = idx === currentIdx;
            const badgeValue = tab.badge || (tab.key === 'CartTab' && cartBadgeCount > 0 ? cartBadgeCount : 0);

            return (
              <TouchableOpacity
                key={tab.key}
                activeOpacity={0.85}
                onPress={() => handlePress(idx, tab)}
                style={styles.tabButton}
                accessibilityRole="tab"
                accessibilityState={{ selected: isSelected }}
              >
                {/* Lifting Icon */}
                <Animated.View
                  style={[
                    styles.iconWrap,
                    { transform: [{ translateY: iconTranslateYs[idx] }] },
                  ]}
                >
                  <Ionicons
                    name={isSelected ? tab.activeIcon : tab.icon}
                    size={22}
                    color={isSelected ? '#FFFFFF' : COLORS.textMuted}
                  />

                  {/* Badge */}
                  {badgeValue > 0 && !isSelected && (
                    <View style={styles.badge}>
                      <Text style={styles.badgeText}>
                        {badgeValue > 99 ? '99+' : badgeValue}
                      </Text>
                    </View>
                  )}
                </Animated.View>

                {/* Text Label */}
                <Text
                  style={[
                    styles.label,
                    isSelected ? styles.labelActive : styles.labelInactive,
                  ]}
                  numberOfLines={1}
                >
                  {tab.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </View>
  );
}

const BUBBLE_SIZE = 54;

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: 76,
    justifyContent: 'flex-end',
  },
  barBackground: {
    height: 64,
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: 22,
    borderTopRightRadius: 22,
    borderTopWidth: 1.2,
    borderLeftWidth: 1.2,
    borderRightWidth: 1.2,
    borderColor: '#E8D2A3', // Gold rim
    shadowColor: COLORS.primaryDark,
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 12,
  },
  floatingBubble: {
    position: 'absolute',
    top: -18,
    left: 0,
    width: BUBBLE_SIZE,
    height: BUBBLE_SIZE,
    borderRadius: BUBBLE_SIZE / 2,
    backgroundColor: COLORS.primary,
    borderWidth: 3.5,
    borderColor: COLORS.background, // Match screen background for notch effect
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 8,
    zIndex: 1,
  },
  tabsRow: {
    flexDirection: 'row',
    height: 64,
    alignItems: 'center',
    zIndex: 2,
  },
  tabButton: {
    flex: 1,
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    paddingBottom: 4,
  },
  iconWrap: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  badge: {
    position: 'absolute',
    top: -2,
    right: -6,
    backgroundColor: COLORS.primary,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 3,
    borderWidth: 1.5,
    borderColor: COLORS.surface,
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 9,
    fontWeight: '800',
  },
  label: {
    fontSize: 10,
    marginTop: 2,
  },
  labelActive: {
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  labelInactive: {
    fontWeight: '500',
    color: COLORS.textMuted,
  },
});

