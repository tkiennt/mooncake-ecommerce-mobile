/**
 * Customer RFQ (request for quotation) API — mirrors the web portal's rfqService.
 * Backend: /api/v1/rfqs (RfqsController, Customer role).
 *
 * When the backend cannot be reached (no HTTP response), calls fall back to an in-memory
 * demo store so the screens stay usable offline. Real server errors (4xx/5xx) are thrown.
 */
import { apiClient } from '../api/apiClient';
import { ENDPOINTS } from '../api/endpoints';

const unwrap = (body) => body?.data ?? body;
const isOffline = (error) => !error?.response;

const daysFromNow = (days, hour = 17) => {
  const date = new Date();
  date.setDate(date.getDate() + days);
  date.setHours(hour, 0, 0, 0);
  return date.toISOString();
};

// ---- Demo store (offline only) -------------------------------------------------------------
const demo = {
  suppliers: [
    { supplierProfileId: 'sup-1', userId: 'usr-sup-1', companyName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ', reputationScore: 98, averageRating: 4.9, address: 'Hoàn Kiếm, Hà Nội' },
    { supplierProfileId: 'sup-2', userId: 'usr-sup-2', companyName: 'Tiệm Bánh Thủ Công An Lạc', reputationScore: 92, averageRating: 4.8, address: 'Quận 3, TP. Hồ Chí Minh' },
    { supplierProfileId: 'sup-3', userId: 'usr-sup-3', companyName: 'Bảo Ngọc Đường', reputationScore: 88, averageRating: 4.7, address: 'TP. Huế' },
  ],
  rfqs: [
    {
      id: 'rfq-0042', rfqNumber: 'RFQ-2026-0042', title: '350 hộp quà Hoàng Triều tri ân đối tác VIP',
      description: 'Hộp sơn mài 4 bánh + trà, in logo ép kim lên nắp hộp.', status: 'Open',
      budgetRangeMin: 600000, budgetRangeMax: 850000, bidDeadline: daysFromNow(3), deliveryDateRequired: daysFromNow(20),
      deliveryAddress: 'Tòa nhà Landmark 81, Bình Thạnh, TP.HCM', bidCount: 3, awardedBidId: null,
      items: [{ id: 'item-1', productName: 'Hộp quà Hoàng Triều (4 bánh + trà)', quantity: 350, unit: 'Hộp', targetPrice: 700000, specifications: 'In logo ép kim' }],
    },
    {
      id: 'rfq-0031', rfqNumber: 'RFQ-2026-0031', title: '120 set bánh dẻo cho nhân viên',
      description: null, status: 'InNegotiation',
      budgetRangeMin: 300000, budgetRangeMax: 450000, bidDeadline: daysFromNow(-1), deliveryDateRequired: daysFromNow(14),
      deliveryAddress: 'KCN Tân Thuận, Quận 7, TP.HCM', bidCount: 2, awardedBidId: 'bid-0031-a',
      items: [{ id: 'item-2', productName: 'Set 4 bánh dẻo truyền thống', quantity: 120, unit: 'Set', targetPrice: null, specifications: null }],
    },
    {
      id: 'rfq-0018', rfqNumber: 'RFQ-2026-0018', title: '500 hộp bánh nướng nhân thập cẩm',
      description: null, status: 'Awarded',
      budgetRangeMin: 450000, budgetRangeMax: 600000, bidDeadline: daysFromNow(-10), deliveryDateRequired: daysFromNow(5),
      deliveryAddress: 'Cầu Giấy, Hà Nội', bidCount: 4, awardedBidId: 'bid-0018-b',
      items: [{ id: 'item-3', productName: 'Hộp 4 bánh nướng thập cẩm', quantity: 500, unit: 'Hộp', targetPrice: 520000, specifications: null }],
    },
  ],
  bids: {
    'rfq-0042': [
      { id: 'bid-0042-a', bidNumber: 'BID-2026-0812', supplierId: 'sup-1', totalPrice: 238000000, estimatedDeliveryDays: 12, validityDays: 15, status: 'Submitted', isExpired: false,
        items: [{ rfqItemId: 'item-1', productName: 'Hộp quà Hoàng Triều (4 bánh + trà)', quantity: 350, unit: 'Hộp', unitPrice: 680000, subtotal: 238000000, notes: 'Miễn phí in logo 2 màu' }] },
      { id: 'bid-0042-b', bidNumber: 'BID-2026-0814', supplierId: 'sup-2', totalPrice: 224000000, estimatedDeliveryDays: 15, validityDays: 10, status: 'Submitted', isExpired: false,
        items: [{ rfqItemId: 'item-1', productName: 'Hộp quà Hoàng Triều (4 bánh + trà)', quantity: 350, unit: 'Hộp', unitPrice: 640000, subtotal: 224000000, notes: null }] },
      { id: 'bid-0042-c', bidNumber: 'BID-2026-0819', supplierId: 'sup-3', totalPrice: 255500000, estimatedDeliveryDays: 9, validityDays: 7, status: 'Submitted', isExpired: false,
        items: [{ rfqItemId: 'item-1', productName: 'Hộp quà Hoàng Triều (4 bánh + trà)', quantity: 350, unit: 'Hộp', unitPrice: 730000, subtotal: 255500000, notes: 'Giao xe lạnh trong 9 ngày' }] },
    ],
    'rfq-0031': [
      { id: 'bid-0031-a', bidNumber: 'BID-2026-0701', supplierId: 'sup-3', totalPrice: 46800000, estimatedDeliveryDays: 10, validityDays: 10, status: 'Selected', isExpired: false,
        items: [{ rfqItemId: 'item-2', productName: 'Set 4 bánh dẻo truyền thống', quantity: 120, unit: 'Set', unitPrice: 390000, subtotal: 46800000, notes: null }] },
      { id: 'bid-0031-b', bidNumber: 'BID-2026-0705', supplierId: 'sup-2', totalPrice: 51600000, estimatedDeliveryDays: 8, validityDays: 10, status: 'Submitted', isExpired: false,
        items: [{ rfqItemId: 'item-2', productName: 'Set 4 bánh dẻo truyền thống', quantity: 120, unit: 'Set', unitPrice: 430000, subtotal: 51600000, notes: null }] },
    ],
    'rfq-0018': [],
  },
};

let demoSeq = 100;

async function withFallback(request, offline) {
  try {
    return unwrap(await request());
  } catch (error) {
    if (isOffline(error)) return offline();
    throw error;
  }
}

export const rfqService = {
  listMine: () => withFallback(
    () => apiClient.get(ENDPOINTS.MY_RFQS),
    () => demo.rfqs.map((rfq) => ({ ...rfq })),
  ),

  get: (rfqId) => withFallback(
    () => apiClient.get(ENDPOINTS.RFQ_DETAILS(rfqId)),
    () => ({ ...demo.rfqs.find((r) => r.id === rfqId) }),
  ),

  /** Creates a draft and publishes it, like the web portal does. */
  createAndPublish: async (request) => {
    try {
      const draft = unwrap(await apiClient.post(ENDPOINTS.CREATE_RFQ, request));
      await apiClient.post(ENDPOINTS.RFQ_PUBLISH(draft.id), {});
      return { ...draft, status: 'Open' };
    } catch (error) {
      if (!isOffline(error)) throw error;
      demoSeq += 1;
      const rfq = {
        ...request, id: `rfq-demo-${demoSeq}`, rfqNumber: `RFQ-2026-0${demoSeq}`, status: 'Open', bidCount: 0, awardedBidId: null,
        items: request.items.map((item, index) => ({ ...item, id: `item-demo-${demoSeq}-${index}` })),
      };
      demo.rfqs.unshift(rfq);
      demo.bids[rfq.id] = [];
      return { ...rfq, isDemo: true };
    }
  },

  cancel: (rfqId, reason) => withFallback(
    () => apiClient.post(ENDPOINTS.RFQ_CANCEL(rfqId), { reason }),
    () => { const rfq = demo.rfqs.find((r) => r.id === rfqId); if (rfq) rfq.status = 'Cancelled'; return rfq; },
  ),

  suggestedSuppliers: (rfqId) => withFallback(
    () => apiClient.get(ENDPOINTS.RFQ_SUGGESTED_SUPPLIERS(rfqId)),
    () => demo.suppliers.map((s) => ({ ...s })),
  ),

  invite: (rfqId, supplierUserIds) => withFallback(
    () => apiClient.post(ENDPOINTS.RFQ_INVITATIONS(rfqId), { supplierUserIds }),
    () => ({ invited: supplierUserIds.length }),
  ),

  listBids: (rfqId) => withFallback(
    () => apiClient.get(ENDPOINTS.RFQ_BIDS(rfqId)),
    () => (demo.bids[rfqId] || []).map((b) => ({ ...b })),
  ),

  acceptBid: (rfqId, bidId, selectionNote = '') => withFallback(
    () => apiClient.post(ENDPOINTS.RFQ_ACCEPT_BID(rfqId, bidId), { selectionNote }),
    () => {
      const rfq = demo.rfqs.find((r) => r.id === rfqId);
      if (rfq) { rfq.status = 'InNegotiation'; rfq.awardedBidId = bidId; }
      (demo.bids[rfqId] || []).forEach((b) => { if (b.id === bidId) b.status = 'Selected'; });
      return { message: 'Đã gửi yêu cầu cho xưởng xác nhận.' };
    },
  ),
};

export const RFQ_STATUS = {
  Draft: { label: 'Bản nháp', tone: 'neutral' },
  Open: { label: 'Đang nhận báo giá', tone: 'info' },
  InNegotiation: { label: 'Chờ xưởng xác nhận', tone: 'warning' },
  Closed: { label: 'Đã đóng', tone: 'neutral' },
  Awarded: { label: 'Đã chọn xưởng', tone: 'success' },
  Cancelled: { label: 'Đã hủy', tone: 'danger' },
};

export const BID_STATUS = {
  Submitted: 'Đã gửi',
  Selected: 'Đã được chọn',
  Withdrawn: 'Đã rút',
  Rejected: 'Không được chọn',
};

export const rfqErrorMessage = (error) =>
  error?.response?.data?.message || error?.message || 'Không thể xử lý yêu cầu.';
