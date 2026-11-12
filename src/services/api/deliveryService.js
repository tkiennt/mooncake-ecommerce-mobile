// Ported from mooncake-fe/src/services/deliveryService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response?.data?.data ?? response?.data ?? response;
const toListPage = (response, params = {}) => {
  const result = unwrap(response);
  if (!Array.isArray(result)) return result;

  const query = String(params.q || '').trim().toLocaleLowerCase();
  const filtered = result.filter((delivery) => {
    const searchable = `${delivery.deliveryNumber || ''} ${delivery.deliveryCode || ''} ${delivery.contractNumber || ''} ${delivery.trackingCode || ''}`;
    return (!query || searchable.toLocaleLowerCase().includes(query)) &&
      (!params.status || delivery.status === params.status);
  });
  const page = Math.max(1, Number(params.page) || 1);
  const pageSize = Math.max(1, Number(params.pageSize) || 10);
  const start = (page - 1) * pageSize;
  return { items: filtered.slice(start, start + pageSize), totalCount: filtered.length };
};

export const deliveryService = {
  async listMine() {
    return unwrap(await apiClient.get(API_ENDPOINTS.DELIVERIES.LIST));
  },
  async listMinePaged(params = {}, signal) {
    return toListPage(await apiClient.get(API_ENDPOINTS.DELIVERIES.LIST, { params, signal }), params);
  },

  async get(id) {
    return unwrap(await apiClient.get(API_ENDPOINTS.DELIVERIES.DETAILS(id)));
  },

  async getByContract(contractId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.DELIVERIES.BY_CONTRACT(contractId)));
  },

  async getByOrder(orderId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.DELIVERIES.BY_ORDER(orderId)));
  },

  async create(payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.DELIVERIES.CREATE, payload));
  },

  async updateStatus(id, status, notes = '', actualDeliveryDate = null) {
    return unwrap(
      await apiClient.put(API_ENDPOINTS.DELIVERIES.STATUS(id), {
        status,
        notes,
        actualDeliveryDate,
      })
    );
  },

  async updateCarrierInfo(id, payload) {
    return unwrap(await apiClient.put(API_ENDPOINTS.DELIVERIES.CARRIER_INFO(id), payload));
  },

  async submitProof(deliveryId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.DELIVERIES.PROOFS(deliveryId), payload));
  },

  async getProofs(deliveryId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.DELIVERIES.PROOFS(deliveryId)));
  },

  async verifyProof(proofId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.DELIVERIES.VERIFY_PROOF(proofId)));
  },
};

export default deliveryService;
