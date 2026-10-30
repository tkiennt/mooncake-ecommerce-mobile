/**
 * API Endpoints Constants for Mobile App
 * Synchronized with ASP.NET Core 8 Web API (v1)
 */

export const API_BASE_URL = 'http://10.0.2.2:8089/api/v1'; // 10.0.2.2 cho Android Emulator, localhost cho iOS

export const ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  SEND_OTP: '/auth/send-otp',
  VERIFY_OTP: '/auth/verify-otp',
  REFRESH_TOKEN: '/auth/refresh-token',
  ME: '/auth/me',
  LOGOUT: '/auth/logout',

  // Catalog & Products
  PRODUCTS: '/products',
  PRODUCT_DETAILS: (id) => `/products/${id}`,
  CATEGORIES: '/categories',
  FEATURED_PRODUCTS: '/products/featured',

  // Orders
  CREATE_ORDER: '/orders',
  MY_ORDERS: '/orders/mine',
  ORDER_DETAILS: (id) => `/orders/${id}`,
  CANCEL_ORDER: (id) => `/orders/${id}/cancel`,

  // Payments
  CREATE_PAYMENT: '/payments',
  CONFIRM_PAYMENT: (id) => `/payments/${id}/confirm`,

  // RFQ (B2B Request for Quote)
  MY_RFQS: '/rfqs/mine',
  CREATE_RFQ: '/rfqs',
  RFQ_DETAILS: (id) => `/rfqs/${id}`,

  // Contracts
  MY_CONTRACTS: '/contracts/mine',
  CONTRACT_DETAILS: (id) => `/contracts/${id}`,

  // AI Chat
  AI_CHAT: '/ai/chat',
};
