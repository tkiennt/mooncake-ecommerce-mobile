/**
 * SignalR Client Service for Mobile App
 * Kết nối tới /api/v1/hubs/notifications của ASP.NET Core 8 Backend
 */

import * as signalR from '@microsoft/signalr';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_BASE_URL } from '../api/endpoints';

// Same host as the REST API, so one setting (EXPO_PUBLIC_API_BASE_URL) covers both.
const HUB_URL = `${API_BASE_URL}/hubs/notifications`;

class SignalRService {
  constructor() {
    this.connection = null;
    this.listeners = [];
  }

  async startConnection() {
    if (this.connection && this.connection.state === signalR.HubConnectionState.Connected) {
      return;
    }

    try {
      this.connection = new signalR.HubConnectionBuilder()
        .withUrl(HUB_URL, {
          accessTokenFactory: async () => {
            const token = await AsyncStorage.getItem('@auth_token');
            return token || '';
          },
        })
        .withAutomaticReconnect([0, 2000, 5000, 10000])
        .configureLogging(signalR.LogLevel.Warning)
        .build();

      // Đăng ký nhận sự kiện từ Backend
      this.connection.on('ReceiveNotification', (notification) => {
        this.notifyListeners(notification);
      });

      this.connection.on('BidReceived', (bidData) => {
        this.notifyListeners({
          type: 'NEW_BID',
          title: 'Báo giá mới!',
          message: `Xưởng ${bidData.supplierName || 'bánh'} vừa nộp báo giá cho yêu cầu ${bidData.rfqNumber || ''}`,
          data: bidData,
          createdAt: new Date().toISOString(),
        });
      });

      this.connection.on('ContractUpdated', (contractData) => {
        this.notifyListeners({
          type: 'CONTRACT_STATUS',
          title: 'Cập nhật hợp đồng điện tử',
          message: `Hợp đồng ${contractData.contractNumber} đã chuyển sang trạng thái: ${contractData.status}`,
          data: contractData,
          createdAt: new Date().toISOString(),
        });
      });

      await this.connection.start();
      console.log('SignalR NotificationHub connected successfully');
    } catch (err) {
      console.log('SignalR connection deferred (Backend hub offline / demo mode):', err?.message);
    }
  }

  stopConnection() {
    if (this.connection) {
      this.connection.stop();
    }
  }

  addListener(callback) {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter((cb) => cb !== callback);
    };
  }

  notifyListeners(data) {
    this.listeners.forEach((cb) => {
      try {
        cb(data);
      } catch (e) {
        console.error('Error invoking notification listener:', e);
      }
    });
  }
}

export const signalRService = new SignalRService();

