// Ported from mooncake-fe/src/services/orderService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';
import { uuid } from '../../utils/uuid';
import { PAYMENT_RETURN_URL } from '../../api/paymentReturn';

const unwrap = (response) => response?.data ?? response;

export const orderService = {
  async previewQuote(request, signal) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.QUOTE_PREVIEW, request, {
      signal,
      skipAuthHeader: true,
      skipAuthRefresh: true,
    }));
  },
  async getShopPolicy(shopId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.SHOP_POLICY(shopId), {
      skipAuthHeader: true,
      skipAuthRefresh: true,
    }));
  },
  async create(request, idempotencyKey = uuid()) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CREATE, request, {
      headers: { 'Idempotency-Key': idempotencyKey },
    }));
  },
  async listMine() {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.CUSTOMER_LIST));
  },
  async listMinePaged(params = {}, signal) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.CUSTOMER_PAGED, {
      params, signal, paramsSerializer: { indexes: null },
    }));
  },
  async listSupplierOrders() {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.SUPPLIER_LIST));
  },
  async listSupplierOrdersPaged(params = {}, signal) {
    const result = unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.SUPPLIER_LIST, { signal }));
    if (!Array.isArray(result)) return result;
    const query = String(params.q || '').trim().toLocaleLowerCase();
    const filtered = result.filter((order) => {
      const searchable = `${order.orderNumber || ''} ${order.recipientName || ''} ${order.status || ''}`.toLocaleLowerCase();
      return (!query || searchable.includes(query)) && (!params.status || order.status === params.status);
    });
    const page = Math.max(1, Number(params.page) || 1);
    const pageSize = Math.max(1, Number(params.pageSize) || filtered.length || 1);
    const offset = (page - 1) * pageSize;
    return { items: filtered.slice(offset, offset + pageSize), totalCount: filtered.length };
  },
  async getSupplierDashboardSummary() {
    const result = unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.SUPPLIER_LIST));
    const orders = Array.isArray(result) ? result : result?.items || [];
    return {
      totalOrders: orders.length,
      pendingOrders: orders.filter((order) => order.status === 'Pending').length,
      processingOrders: orders.filter((order) => ['Confirmed', 'Processing'].includes(order.status)).length,
      packagingOrders: orders.filter((order) => Boolean(order.customPackaging)).length,
      totalRevenue: orders.reduce((total, order) => total + Number(order.totalAmount || 0), 0),
    };
  },
  async getFinancialLedgerPage(orderId, params = {}, signal) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.FINANCIAL_LEDGER(orderId), { params, signal }));
  },
  async get(orderId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.DETAILS(orderId)));
  },
  async cancel(orderId, reason) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CANCEL(orderId), { reason }));
  },
  async confirm(orderId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CONFIRM(orderId), {}));
  },
  async reject(orderId, reason) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.REJECT(orderId), { reason }));
  },
  async proposeDeliveryDate(orderId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.PROPOSE_DELIVERY_DATE(orderId), payload));
  },
  async respondDeliveryProposal(orderId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.RESPOND_DELIVERY_PROPOSAL(orderId), payload));
  },
  async requestCancellation(orderId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CANCELLATION_REQUESTS(orderId), payload));
  },
  async respondCancellationRequest(orderId, requestId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.RESPOND_CANCELLATION_REQUEST(orderId, requestId), payload));
  },
  async startProcessing(orderId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.PROCESSING(orderId), {}));
  },
  async ship(orderId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.SHIP(orderId), {}));
  },
  async createPartVnPayUrl(orderId, partId, returnUrl) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.PART_VNPAY_URL(orderId, partId), {
      returnUrl: returnUrl || PAYMENT_RETURN_URL,
    }));
  },
  async getPaymentSummary(orderId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.PAYMENT_SUMMARY(orderId)));
  },
  async getFinancialSummary(orderId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ORDERS.FINANCIAL_SUMMARY(orderId)));
  },
  async confirmDelivery(orderId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CONFIRM_DELIVERY(orderId), {}));
  },
  async confirmDeliveryReceipt(orderId, payload = {}) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.CONFIRM_DELIVERY_RECEIPT(orderId), payload));
  },
  async reportDeliveryDispute(orderId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.DELIVERY_DISPUTE(orderId), payload));
  },
  async requestRefund(orderId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.REFUND_REQUESTS(orderId), payload));
  },
  async requestSimulatedPayout(orderId, payload = {}) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ORDERS.PAYOUT_REQUESTS(orderId), payload));
  },
  async getMySupplierOrderPolicy(shopId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.SUPPLIERS.ORDER_POLICY, {
      params: shopId ? { shopId } : undefined,
    }));
  },
  async upsertMySupplierOrderPolicy(payload) {
    return unwrap(await apiClient.put(API_ENDPOINTS.SUPPLIERS.ORDER_POLICY, payload));
  },
  async getMySupplierPayoutAccount() {
    return unwrap(await apiClient.get(API_ENDPOINTS.SUPPLIERS.PAYOUT_ACCOUNT));
  },
  async upsertMySupplierPayoutAccount(payload) {
    return unwrap(await apiClient.put(API_ENDPOINTS.SUPPLIERS.PAYOUT_ACCOUNT, payload));
  },
  async getAdminOperations() {
    return unwrap(await apiClient.get(API_ENDPOINTS.ADMIN_ORDERS.OPERATIONS));
  },
  async getAdminOperationsSummary() {
    return unwrap(await apiClient.get(API_ENDPOINTS.ADMIN_ORDERS.SUMMARY));
  },
  async listAdminRefundCases(params, signal) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ADMIN_ORDERS.REFUND_CASES, { params, signal }));
  },
  async listAdminPayoutRequests(params, signal) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ADMIN_ORDERS.PAYOUT_REQUESTS, { params, signal }));
  },
  async listAdminDeliveryDisputes(params, signal) {
    return unwrap(await apiClient.get(API_ENDPOINTS.ADMIN_ORDERS.DELIVERY_DISPUTES, { params, signal }));
  },
  async processAdminRefundCase(refundCaseId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ADMIN_ORDERS.PROCESS_REFUND_CASE(refundCaseId), payload));
  },
  async processAdminPayoutRequest(payoutRequestId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ADMIN_ORDERS.PROCESS_PAYOUT_REQUEST(payoutRequestId), payload));
  },
  async resolveAdminDeliveryDispute(disputeId, payload) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ADMIN_ORDERS.RESOLVE_DELIVERY_DISPUTE(disputeId), payload));
  },
  async getMyPayoutAccount() {
    return this.getMySupplierPayoutAccount();
  },
  async upsertMyPayoutAccount(payload) {
    return this.upsertMySupplierPayoutAccount(payload);
  },
  async createPayoutRequest(orderId, payload = {}) {
    return this.requestSimulatedPayout(orderId, payload);
  },
};

export default orderService;
