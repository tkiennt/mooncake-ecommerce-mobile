// Ported from mooncake-fe/src/services/notificationService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (res) => (res && res.data !== undefined ? (res.data?.data !== undefined ? res.data.data : res.data) : res);

export const notificationService = {
  async getNotifications(params = {}) {
    const response = await apiClient.get(API_ENDPOINTS.NOTIFICATIONS.LIST, { params });
    return unwrap(response);
  },

  async getUnreadCount(params = {}) {
    const response = await apiClient.get(API_ENDPOINTS.NOTIFICATIONS.UNREAD_COUNT, { params });
    return unwrap(response);
  },

  async markAsRead(id) {
    const response = await apiClient.patch(API_ENDPOINTS.NOTIFICATIONS.MARK_READ(id));
    return unwrap(response);
  },

  async markAllAsRead(category = 'all') {
    const response = await apiClient.post(API_ENDPOINTS.NOTIFICATIONS.MARK_ALL_READ, {
      category,
      readThroughTimestamp: new Date().toISOString(),
    });
    return unwrap(response);
  },

  async getPreferences() {
    const response = await apiClient.get(API_ENDPOINTS.NOTIFICATIONS.PREFERENCES);
    return unwrap(response);
  },

  async updatePreferences(preferences) {
    const response = await apiClient.put(API_ENDPOINTS.NOTIFICATIONS.PREFERENCES, preferences);
    return unwrap(response);
  },
};

export default notificationService;
