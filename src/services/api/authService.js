/**
 * Authentication Service for Mobile App
 * Matches ASP.NET Core backend /api/v1/auth
 */

import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const authService = {
  /**
   * Đăng ký tài khoản khách hàng / doanh nghiệp
   */
  async register({ email, password, fullName, phone }) {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.REGISTER, {
      email: email.trim(),
      password,
      fullName: fullName?.trim(),
      phone: phone.trim().replace(/\s+/g, ''),
      role: 'Customer',
    });
    return response?.data || response;
  },

  /**
   * Xác minh email qua mã OTP 6 số
   */
  async verifyEmail(email, code) {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.VERIFY_EMAIL, {
      email: email.trim(),
      code: String(code).trim(),
    });
    return response?.data || response;
  },

  /**
   * Gửi lại mã OTP xác minh email
   */
  async resendVerification(email) {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.RESEND_VERIFICATION, {
      email: email.trim(),
    });
    return response?.data || response;
  },

  /**
   * Quên mật khẩu: gửi email yêu cầu đặt lại mật khẩu
   */
  async forgotPassword(email) {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.FORGOT_PASSWORD, {
      email: email.trim(),
    });
    return response?.data || response;
  },

  /**
   * Đặt lại mật khẩu với mã OTP và mật khẩu mới
   */
  async resetPassword({ email, code, newPassword }) {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.RESET_PASSWORD, {
      email: email.trim(),
      code: String(code).trim(),
      newPassword,
    });
    return response?.data || response;
  },

  /**
   * Lấy URL ủy quyền Google OAuth 2.0
   */
  async getGoogleAuthorizationUrl() {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.GOOGLE_AUTHORIZATION_URL, {});
    return response?.data || response;
  },

  /**
   * Đăng nhập Google với code & state
   */
  async loginWithGoogle(code, state) {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.GOOGLE_LOGIN, { code, state });
    return response?.data || response;
  },
};

export default authService;
