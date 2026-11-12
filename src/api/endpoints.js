/**
 * API Endpoints Constants for Mobile App
 * Synchronized with ASP.NET Core 8 Web API (v1). Full customer route map: ./apiEndpoints.js (ported from web).
 */

import { Platform } from 'react-native';

// Override with EXPO_PUBLIC_API_BASE_URL (e.g. http://192.168.1.15:8089/api/v1 for a physical device).
// Defaults: 10.0.2.2 reaches the host from the Android emulator; web and iOS use localhost.
export const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL
  || (Platform.OS === 'android' ? 'http://10.0.2.2:8089/api/v1' : 'http://localhost:8089/api/v1');

export const ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  VERIFY_EMAIL: '/auth/verify-email',
  RESEND_VERIFICATION: '/auth/resend-verification',
  FORGOT_PASSWORD: '/auth/forgot-password',
  RESET_PASSWORD: '/auth/reset-password',
  GOOGLE_LOGIN: '/auth/google/login',
  REFRESH_TOKEN: '/auth/refresh-token',
  ME: '/auth/me',
  LOGOUT: '/auth/logout',

  // Catalog & Products
  PRODUCTS: '/products',
  PRODUCT_DETAILS: (id) => `/products/${id}`,
  CATEGORIES: '/categories',
  RECOMMENDATIONS: '/products/recommendations',

  // Orders
  CREATE_ORDER: '/orders',
  MY_ORDERS: '/orders/mine',
  ORDER_DETAILS: (id) => `/orders/${id}`,
  CANCEL_ORDER: (id) => `/orders/${id}/cancel`,

  // Payments
  CREATE_PAYMENT: '/payments',
  MY_PAYMENTS: '/payments/mine',

  // RFQ (B2B Request for Quote)
  MY_RFQS: '/rfqs/mine',
  CREATE_RFQ: '/rfqs',
  RFQ_DETAILS: (id) => `/rfqs/${id}`,
  RFQ_PUBLISH: (id) => `/rfqs/${id}/publish`,
  RFQ_CANCEL: (id) => `/rfqs/${id}/cancel`,
  RFQ_SUGGESTED_SUPPLIERS: (id) => `/rfqs/${id}/suggested-suppliers`,
  RFQ_INVITATIONS: (id) => `/rfqs/${id}/invitations`,
  RFQ_BIDS: (id) => `/rfqs/${id}/bids`,
  RFQ_ACCEPT_BID: (rfqId, bidId) => `/rfqs/${rfqId}/bids/${bidId}/accept`,

  // Contracts
  MY_CONTRACTS: '/contracts/mine',
  CONTRACT_DETAILS: (id) => `/contracts/${id}`,

  // AI Chat (session based)
  AI_CHAT_SESSIONS: '/ai/chat/sessions',
  AI_CHAT_MESSAGES: '/ai/chat/messages',
};

