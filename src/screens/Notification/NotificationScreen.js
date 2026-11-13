import React from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import { useNotification } from '../../context/NotificationContext';

export default function NotificationScreen({ navigation }) {
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotification();

  const handleNotificationPress = (item) => {
    markAsRead(item.id);
    if (item.type === 'NEW_BID' || item.rfqId) {
      navigation.navigate('RfqList');
    } else if (item.type === 'CONTRACT_STATUS' || item.type === 'MILESTONE_REMINDER') {
      navigation.navigate('Contracts');
    }
  };

  const getIconForType = (type) => {
    switch (type) {
      case 'NEW_BID':
        return { name: 'document-text', color: COLORS.accent };
      case 'CONTRACT_STATUS':
        return { name: 'shield-checkmark', color: COLORS.primary };
      case 'MILESTONE_REMINDER':
        return { name: 'alarm', color: COLORS.warning };
      default:
        return { name: 'notifications', color: COLORS.primary };
    }
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Thông báo"
        subtitle={unreadCount > 0 ? `${unreadCount} thông báo chưa đọc` : 'Cập nhật thời gian thực'}
        showBack={true}
        onBack={() => navigation.goBack()}
        rightIcon="settings-outline"
        rightLabel="Cài đặt thông báo"
        onRightPress={() => navigation.navigate('NotificationSettings')}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        {unreadCount > 0 && (
          <View style={styles.topBar}>
            <Text style={styles.unreadCountText}>{unreadCount} thông báo mới</Text>
            <TouchableOpacity onPress={markAllAsRead}>
              <Text style={styles.markAllText}>Đánh dấu tất cả đã đọc</Text>
            </TouchableOpacity>
          </View>
        )}
        {notifications.length > 0 ? (
          notifications.map((item) => {
            const icon = getIconForType(item.type);
            return (
              <TouchableOpacity
                key={item.id}
                style={[styles.itemCard, !item.isRead && styles.unreadCard]}
                onPress={() => handleNotificationPress(item)}
                activeOpacity={0.8}
              >
                <View style={[styles.iconBox, { backgroundColor: `${icon.color}15` }]}>
                  <Ionicons name={icon.name} size={20} color={icon.color} />
                </View>

                <View style={styles.contentBox}>
                  <View style={styles.row}>
                    <Text style={[styles.title, !item.isRead && styles.unreadTitle]}>
                      {item.title}
                    </Text>
                    {!item.isRead && <View style={styles.unreadDot} />}
                  </View>
                  <Text style={styles.message}>{item.message}</Text>
                  <Text style={styles.time}>{item.createdAt}</Text>
                </View>
              </TouchableOpacity>
            );
          })
        ) : (
          <View style={styles.emptyBox}>
            <Ionicons name="notifications-off-outline" size={48} color={COLORS.textMuted} />
            <Text style={styles.emptyTitle}>Chưa có thông báo nào</Text>
            <Text style={styles.emptySub}>
              Mọi cập nhật về báo giá thầu, tiến độ hợp đồng và xe lạnh sẽ được gửi tới bạn tại đây.
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  itemCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  unreadCard: {
    backgroundColor: '#FFFDF9',
    borderColor: 'rgba(212, 136, 6, 0.4)',
    borderLeftWidth: 4,
    borderLeftColor: COLORS.primary,
  },
  iconBox: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  contentBox: {
    flex: 1,
    marginLeft: 12,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  unreadTitle: {
    fontWeight: '800',
    color: COLORS.primary,
  },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: COLORS.primary,
  },
  message: {
    fontSize: 12,
    color: COLORS.textSecondary,
    lineHeight: 18,
    marginTop: 4,
  },
  time: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 6,
  },
  emptyBox: {
    alignItems: 'center',
    marginTop: 80,
    paddingHorizontal: 20,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 12,
  },
  emptySub: {
    fontSize: 13,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginTop: 6,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FFF1F0',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#FFA39E',
  },
  unreadCountText: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.primary,
  },
  markAllText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.primary,
  },
});

