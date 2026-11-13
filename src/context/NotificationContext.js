/**
 * NotificationContext for Mobile App
 * Quản lý danh sách thông báo B2B và đếm số lượng chưa đọc
 */

import React, { createContext, useState, useEffect, useContext } from 'react';
import { signalRService } from '../services/signalrService';
import { notificationService } from '../services/api/notificationService';

const relativeTime = (iso) => {
  if (!iso) return 'Gần đây';
  const minutes = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutes < 1) return 'Vừa xong';
  if (minutes < 60) return `${minutes} phút trước`;
  if (minutes < 1440) return `${Math.round(minutes / 60)} giờ trước`;
  return `${Math.round(minutes / 1440)} ngày trước`;
};

// Backend activity notification → the shape NotificationScreen renders.
const toMobileNotification = (n) => ({
  id: n.id,
  type: n.category || n.type,
  title: n.title,
  message: n.content || n.message || '',
  createdAt: relativeTime(n.createdAtUtc || n.createdAt),
  isRead: Boolean(n.isRead),
  entityId: n.entityId,
});

const NotificationContext = createContext();

export const INITIAL_NOTIFICATIONS = [
  {
    id: 'notif-1',
    type: 'NEW_BID',
    title: 'Báo Giá Mới Nhận Được',
    message: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ vừa nộp báo giá cho yêu cầu RFQ-2026-0042.',
    createdAt: '10 phút trước',
    isRead: false,
    rfqId: 'rfq-001',
  },
  {
    id: 'notif-2',
    type: 'CONTRACT_STATUS',
    title: 'Hợp Đồng Cần Ký Duyệt',
    message: 'Dự thảo Hợp đồng điện tử HĐ-2026-0812 đã được khởi tạo. Vui lòng ký số bằng OTP.',
    createdAt: '2 giờ trước',
    isRead: false,
    contractId: 'contract-001',
  },
  {
    id: 'notif-3',
    type: 'MILESTONE_REMINDER',
    title: 'Nhắc thanh toán đặt cọc',
    message: 'Vui lòng thanh toán đặt cọc (30%) trước ngày 05/08 để xưởng tiến hành sản xuất bánh.',
    createdAt: '1 ngày trước',
    isRead: true,
    contractId: 'contract-001',
  },
];

export const NotificationProvider = ({ children }) => {
  const [notifications, setNotifications] = useState(INITIAL_NOTIFICATIONS);

  // Load the activity feed from GET /api/v1/notifications; keep the demo list only when offline.
  const loadNotifications = async () => {
    try {
      const page = await notificationService.getNotifications({ page: 1, pageSize: 50 });
      const items = Array.isArray(page) ? page : page?.items || [];
      setNotifications(items.map(toMobileNotification));
    } catch (error) {
      if (error?.response && error.response.status !== 401) setNotifications([]);
    }
  };

  useEffect(() => {
    loadNotifications();
    signalRService.startConnection();

    const unsubscribe = signalRService.addListener((newNotif) => {
      setNotifications((prev) => [
        {
          id: `notif-${Date.now()}`,
          isRead: false,
          createdAt: 'Vừa xong',
          ...newNotif,
        },
        ...prev,
      ]);
    });

    return () => {
      unsubscribe();
      signalRService.stopConnection();
    };
  }, []);

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  const markAsRead = (id) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
    );
    if (!String(id).startsWith('notif-')) notificationService.markAsRead(id).catch(() => {});
  };

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
    notificationService.markAllAsRead().catch(() => {});
  };

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        unreadCount,
        markAsRead,
        markAllAsRead,
        reload: loadNotifications,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotification = () => useContext(NotificationContext);

