// Ported from mooncake-fe/src/services/profileService.js — keep both in sync.
import { API_ENDPOINTS } from '../../api/apiEndpoints';
import { apiClient } from '../../api/apiClient';

export const profileService = {
  async getMine() {
    const response = await apiClient.get(API_ENDPOINTS.AUTH.PROFILE);
    return response.data;
  },

  async updateMine(values) {
    const response = await apiClient.put(API_ENDPOINTS.AUTH.PROFILE, values);
    return response.data;
  },

  async uploadAvatar(file) {
    const formData = new FormData();
    formData.append('file', file);
    const response = await apiClient.post(API_ENDPOINTS.AUTH.PROFILE_AVATAR, formData, {
      timeout: 60000,
    });
    return response.data;
  },

  async removeAvatar() {
    const response = await apiClient.delete(API_ENDPOINTS.AUTH.PROFILE_AVATAR);
    return response.data;
  },
};

export default profileService;
