// Ported from mooncake-fe/src/services/packagingTemplateService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response?.data?.data ?? response?.data ?? response;

export const packagingTemplateService = {
  async getByShop(shopId, signal) {
    if (!shopId) return [];
    const res = await apiClient.get(API_ENDPOINTS.PACKAGING_TEMPLATES.BY_SHOP(shopId), {
      signal,
      skipAuthHeader: true,
      skipAuthRefresh: true,
    });
    const data = unwrap(res);
    return Array.isArray(data) ? data : [];
  },

  async getMine(signal) {
    const res = await apiClient.get(API_ENDPOINTS.PACKAGING_TEMPLATES.MINE, { signal });
    const data = unwrap(res);
    return Array.isArray(data) ? data : [];
  },

  async create(payload, signal) {
    const res = await apiClient.post(API_ENDPOINTS.PACKAGING_TEMPLATES.MINE, payload, { signal });
    return unwrap(res);
  },

  async update(id, payload, signal) {
    const res = await apiClient.put(API_ENDPOINTS.PACKAGING_TEMPLATES.DETAIL(id), payload, { signal });
    return unwrap(res);
  },

  async remove(id, signal) {
    const res = await apiClient.delete(API_ENDPOINTS.PACKAGING_TEMPLATES.DETAIL(id), { signal });
    return unwrap(res);
  },
};

export default packagingTemplateService;
