// Ported from mooncake-fe/src/services/aiService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response?.data?.data ?? response?.data ?? response;

export const aiService = {
  // 1. Start or resume AI chat session
  async startSession(payload = {}) {
    const response = await apiClient.post(API_ENDPOINTS.AI.CHAT_SESSIONS, payload);
    return unwrap(response);
  },

  // 2. Send message and receive RAG consultant reply
  async sendMessage(payload) {
    const response = await apiClient.post(API_ENDPOINTS.AI.CHAT_MESSAGES, payload);
    return unwrap(response);
  },

  // 3. Get chat history
  async getChatHistory(sessionToken) {
    const response = await apiClient.get(API_ENDPOINTS.AI.CHAT_HISTORY(sessionToken));
    return unwrap(response);
  },

  // 4. End chat session
  async endSession(sessionToken) {
    const response = await apiClient.delete(API_ENDPOINTS.AI.CHAT_END(sessionToken));
    return unwrap(response);
  },

  // 5. Generate AI sales analysis report
  async generateAnalyticsReport(payload = {}) {
    const response = await apiClient.post(API_ENDPOINTS.AI.ANALYTICS_GENERATE, payload);
    return unwrap(response);
  },

  // 6. List past reports
  async listAnalyticsReports() {
    const response = await apiClient.get(API_ENDPOINTS.AI.ANALYTICS_REPORTS);
    return unwrap(response);
  },

  // 7. Get report details
  async getAnalyticsReport(id) {
    const response = await apiClient.get(API_ENDPOINTS.AI.ANALYTICS_REPORT_DETAIL(id));
    return unwrap(response);
  },

  // 8. Get quick realtime dashboard KPIs
  async getDashboardSummary(shopId = null) {
    const response = await apiClient.get(API_ENDPOINTS.AI.ANALYTICS_DASHBOARD_SUMMARY, {
      params: shopId ? { shopId } : undefined,
    });
    return unwrap(response);
  },
};

export default aiService;
