// Ported from mooncake-fe/src/services/customPackagingService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response?.data ?? response;

export const customPackagingService = {
  async uploadLogo(file) {
    const formData = new FormData();
    formData.append('file', file);
    const res = await apiClient.post(API_ENDPOINTS.ORDERS.CUSTOM_PACKAGING_UPLOAD_LOGO, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: 60000,
    });
    return unwrap(res)?.data ?? unwrap(res);
  },
  async create(orderId, request) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CUSTOM_PACKAGING(orderId), request));
  },
  async get(orderId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.CUSTOM_PACKAGING(orderId)));
  },
  async submitRevision(orderId, request) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.PACKAGING_REVISIONS(orderId), request));
  },
  async reviewRevision(orderId, revisionId, request) {
    return unwrap(await apiClient.post(
      API_ENDPOINTS.ORDERS.REVIEW_PACKAGING_REVISION(orderId, revisionId),
      request,
    ));
  },
};

export default customPackagingService;
