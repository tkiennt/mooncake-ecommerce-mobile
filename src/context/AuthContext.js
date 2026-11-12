/**
 * AuthContext for Mobile App
 * Manages user profile, tokens, login & logout
 */

import React, { createContext, useState, useEffect, useContext } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient } from '../api/apiClient';
import { ENDPOINTS } from '../api/endpoints';

const AuthContext = createContext();

const DEMO_TOKEN = 'demo_offline_session';

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
    let body;
    try {
      body = await apiClient.post(ENDPOINTS.LOGIN, { phoneNumber, password });
    } catch (error) {
      if (error?.response) {
        // Wrong credentials, locked account, etc. — never fall back to a demo session here.
        throw new Error(error.response.data?.message || 'Số điện thoại hoặc mật khẩu không chính xác.');
      }
      // Backend unreachable (local dev without API): open a clearly-labelled demo session.
      const demoUser = {
        id: 'usr-demo',
        fullName: 'Khách hàng demo',
        phoneNumber: phoneNumber || '0901234567',
        companyName: 'Công ty demo',
        role: 'Customer',
      };
      await AsyncStorage.multiSet([['@auth_token', DEMO_TOKEN], ['@user_profile', JSON.stringify(demoUser)]]);
      await AsyncStorage.removeItem('@refresh_token');
      setToken(DEMO_TOKEN);
      setUser(demoUser);
      return { success: true, isDemo: true };
    }

    // Backend returns { accessToken, refreshToken, user } (same contract as the web portal).
    const { accessToken, refreshToken, user: profile } = body?.data || {};
    if (!accessToken || !refreshToken || !profile) {
      throw new Error('Máy chủ trả về phiên đăng nhập không hợp lệ.');
    }
    if (profile.role !== 'Customer') {
      // The app only implements the customer journey.
      apiClient.post(ENDPOINTS.LOGOUT, { refreshToken }).catch(() => {});
      throw new Error('Ứng dụng di động dành cho khách hàng. Tài khoản nhà cung cấp và quản trị vui lòng dùng trang web.');
    }
    await AsyncStorage.multiSet([
      ['@auth_token', accessToken],
      ['@refresh_token', refreshToken],
      ['@user_profile', JSON.stringify(profile)],
    ]);
    setToken(accessToken);
    setUser(profile);
    return { success: true };
  };

  const logout = async () => {
    try {
      const refreshToken = await AsyncStorage.getItem('@refresh_token');
      if (refreshToken) await apiClient.post(ENDPOINTS.LOGOUT, { refreshToken }).catch(() => {});
      await AsyncStorage.multiRemove(['@auth_token', '@refresh_token', '@user_profile']);
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

