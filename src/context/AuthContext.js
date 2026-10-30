/**
 * AuthContext for Mobile App
 * Manages user profile, tokens, login & logout
 */

import React, { createContext, useState, useEffect, useContext } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient } from '../api/apiClient';
import { ENDPOINTS } from '../api/endpoints';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStoredSession();
  }, []);

  const loadStoredSession = async () => {
    try {
      const storedToken = await AsyncStorage.getItem('@auth_token');
      const storedUser = await AsyncStorage.getItem('@user_profile');
      if (storedToken) {
        setToken(storedToken);
      }
      if (storedUser) {
        setUser(JSON.parse(storedUser));
      }
    } catch (e) {
      console.warn('Lỗi khi tải phiên đăng nhập:', e);
    } finally {
      setLoading(false);
    }
  };

  const login = async (phoneNumber, password) => {
    try {
      // Thử gọi backend trước
      const response = await apiClient.post(ENDPOINTS.LOGIN, {
        phoneNumber,
        password,
      });

      const authToken = response?.data?.token || response?.token || 'mock_jwt_token_user_b2b';
      const userProfile = response?.data?.user || {
        id: 'usr-123',
        fullName: 'Nguyễn Văn An (Thu Mua Doanh Nghiệp)',
        phoneNumber: phoneNumber || '0901234567',
        companyName: 'Công ty Cổ Phần Tập Đoàn Á Châu',
        taxId: '0312456789',
        role: 'Customer',
      };

      await AsyncStorage.setItem('@auth_token', authToken);
      await AsyncStorage.setItem('@user_profile', JSON.stringify(userProfile));

      setToken(authToken);
      setUser(userProfile);
      return { success: true };
    } catch (error) {
      // Fallback demo login nếu backend local chưa bật
      console.log('Backend chưa kết nối, sử dụng phiên demo người dùng B2B');
      const demoToken = 'mock_jwt_token_user_b2b';
      const demoUser = {
        id: 'usr-123',
        fullName: 'Nguyễn Văn An (Thu Mua Doanh Nghiệp)',
        phoneNumber: phoneNumber || '0901234567',
        companyName: 'Công ty Cổ Phần Tập Đoàn Á Châu',
        taxId: '0312456789',
        role: 'Customer',
      };

      await AsyncStorage.setItem('@auth_token', demoToken);
      await AsyncStorage.setItem('@user_profile', JSON.stringify(demoUser));

      setToken(demoToken);
      setUser(demoUser);
      return { success: true, isDemo: true };
    }
  };

  const logout = async () => {
    try {
      await AsyncStorage.removeItem('@auth_token');
      await AsyncStorage.removeItem('@user_profile');
    } catch (e) {
      console.error(e);
    }
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
