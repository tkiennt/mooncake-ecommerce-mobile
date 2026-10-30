/**
 * NotificationContext for Mobile App
 * Quản lý danh sách thông báo B2B và đếm số lượng chưa đọc
 */

import React, { createContext, useState, useEffect, useContext } from 'react';
import { signalRService } from '../services/signalrService';

const NotificationContext = createContext();

export const INITIAL_NOTIFICATIONS = [
  {
    id: 'notif-1',
    type: 'NEW_BID',
    title: 'Báo Giá Mới Nhận Được',
    message: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ vừa nộp báo giá cho gói thầu RFQ-2026-0042.',
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
    title: 'Nhắc Nhở Đặt Cọc M1',
    message: 'Vui lòng thanh toán đặt cọc mốc M1 (30%) trước ngày 05/08 để xưởng tiến hành sản xuất bánh.',
    createdAt: '1 ngày trước',
    isRead: true,
    contractId: 'contract-001',
  },
];

export const NotificationProvider = ({ children }) => {
  const [notifications, setNotifications] = useState(INITIAL_NOTIFICATIONS);

  useEffect(() => {
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
  };

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
  };

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        unreadCount,
        markAsRead,
        markAllAsRead,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotification = () => useContext(NotificationContext);

