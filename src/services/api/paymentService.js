// Ported from mooncake-fe/src/services/paymentService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';
import { uuid } from '../../utils/uuid';
import { PAYMENT_RETURN_URL } from '../../api/paymentReturn';

const unwrap = (response) => response?.data ?? response;

export const paymentService = {
  // Legacy support for contract VNPay url
  async createVnPayUrl(contractId, milestoneId, returnUrl) {
    return this.createContractVnPayUrl(contractId, milestoneId, returnUrl);
  },

  // 1. Tạo liên kết VNPay Sandbox cho Đơn hàng
  async createOrderVnPayUrl(orderId, returnUrl) {
    const res = await apiClient.post(API_ENDPOINTS.PAYMENTS.ORDER_VNPAY_URL, {
      orderId,
      returnUrl: returnUrl || PAYMENT_RETURN_URL,
    });
    return unwrap(res);
  },

  // 2. Tạo liên kết VNPay Sandbox cho Mốc Hợp đồng
  async createContractVnPayUrl(contractId, milestoneId, returnUrl) {
    const res = await apiClient.post(API_ENDPOINTS.PAYMENTS.VNPAY_CREATE_URL, {
      contractId,
      milestoneId,
      returnUrl: returnUrl || PAYMENT_RETURN_URL,
    });
    return unwrap(res);
  },

  // 3. Khởi tạo chuyển khoản VietQR (MB Bank Napas 247)
  async createBankTransfer(payload) {
    const res = await apiClient.post(API_ENDPOINTS.PAYMENTS.BANK_TRANSFER, payload);
    return unwrap(res);
  },

  // 4. Xác thực kết quả VNPay Return Callback
  async verifyReturnCallback(queryString) {
    const res = await apiClient.get(`${API_ENDPOINTS.PAYMENTS.VNPAY_RETURN}?${queryString}`);
    return unwrap(res);
  },

  // 5. Tải lên chứng từ UNC (Ủy nhiệm chi)
  async uploadEvidence(paymentId, evidenceUrl, notes) {
    const res = await apiClient.post(API_ENDPOINTS.PAYMENTS.UPLOAD_EVIDENCE(paymentId), {
      evidenceUrl,
      notes,
    });
    return unwrap(res);
  },

  // 6. Tạo thanh toán trực tiếp (COD, Momo, ZaloPay, Cash)
  async create(request, idempotencyKey = uuid()) {
    return unwrap(await apiClient.post(API_ENDPOINTS.PAYMENTS.CREATE, request, {
      headers: { 'Idempotency-Key': idempotencyKey },
    }));
  },

  // 7. Lấy danh sách giao dịch của tôi
  async listMine() {
    return unwrap(await apiClient.get(API_ENDPOINTS.PAYMENTS.LIST));
  },

  // 8. Lấy báo cáo tổng hợp Escrow (Admin)
  async getEscrowSummary() {
    return unwrap(await apiClient.get(API_ENDPOINTS.PAYMENTS.ESCROW_SUMMARY));
  },

  // 9. Admin xác nhận thanh toán chuyển khoản
  async confirm(paymentId, reason) {
    return unwrap(await apiClient.post(API_ENDPOINTS.PAYMENTS.CONFIRM(paymentId), { reason }));
  },

  // 10. Admin hoàn tiền
  async refund(paymentId, reason) {
    return unwrap(await apiClient.post(API_ENDPOINTS.PAYMENTS.REFUND(paymentId), { reason }));
  },
};

export default paymentService;
