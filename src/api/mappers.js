/**
 * Convert backend DTOs (Mooncake.EcommercePlatform.Application/DTOs) into the shapes the mobile
 * screens were built around, so screens can switch from demo data to the API without rewrites.
 */
import { API_BASE_URL } from './endpoints';

const API_ORIGIN = API_BASE_URL.replace(/\/api\/v1\/?$/, '');
const absoluteUrl = (url) => (!url ? null : /^https?:\/\//i.test(url) ? url : `${API_ORIGIN}${url.startsWith('/') ? '' : '/'}${url}`);

/** ProductSearchCardResponse | ProductPublicDetailResponse → mobile product. */
export function toMobileProduct(dto) {
  if (!dto) return null;
  const basePrice = Number(dto.basePrice ?? dto.minPrice ?? 0);
  const primaryImage = dto.primaryImageUrl
    || dto.images?.find((img) => img.isPrimary)?.imageUrl
    || dto.images?.[0]?.imageUrl;
  return {
    id: dto.productId || dto.id,
    name: dto.name,
    shopName: dto.shop?.name || dto.shopName || '',
    shopId: dto.shop?.shopId || dto.shopId,
    shopSlug: dto.shop?.slug,
    shopCity: dto.shop?.regionCode || null,
    shopVerified: Boolean(dto.shop?.isVerified),
    category: dto.category?.name || '',
    coverImage: absoluteUrl(primaryImage),
    basePrice,
    maxPrice: Number(dto.maxPrice ?? basePrice),
    unit: dto.unit || 'hộp',
    minOrderQty: dto.minOrderQty || 1,
    maxOrderQty: dto.maxOrderQty || null,
    rating: dto.averageRating != null ? Number(dto.averageRating) : 0,
    reviewCount: dto.reviewCount || 0,
    soldCount: dto.soldCount || 0,
    isCustomPackagingSupported: Boolean(dto.supportsCustomPackaging),
    description: dto.description || '',
    // Public variants carry an absolute price; screens expect an adjustment from the base price.
    variants: (dto.variants || []).filter((v) => v.isAvailable !== false).map((v) => ({
      id: v.id,
      name: v.name,
      crustType: v.crustType || '',
      filling: v.filling || '',
      priceAdjustment: Number(v.price ?? basePrice) - basePrice,
      stock: v.isAvailable === false ? 0 : null,
    })),
    // Quantity tiers come from shop promotions / quote preview, not from the public product DTO.
    tierPricing: dto.tierPricing || [],
    isFromApi: true,
  };
}

const ORDER_TAB = {
  Pending: 'Pending',
  AwaitingCustomerDeliveryApproval: 'Pending',
  Confirmed: 'Processing',
  Processing: 'Processing',
  Shipped: 'Shipping',
  Delivered: 'Delivered',
  CancellationRequested: 'Cancelled',
  Cancelled: 'Cancelled',
  Expired: 'Cancelled',
};

const ORDER_NOTE = (o) => {
  switch (o.status) {
    case 'Pending': return o.responseDeadlineAtUtc ? `Xưởng sẽ xác nhận trước ${new Date(o.responseDeadlineAtUtc).toLocaleString('vi-VN')}` : 'Chờ xưởng xác nhận';
    case 'AwaitingCustomerDeliveryApproval': return `Xưởng đề xuất giao ngày ${o.proposedDeliveryDate} · cần bạn duyệt`;
    case 'Confirmed':
    case 'Processing': return o.confirmedDeliveryDate ? `Đang sản xuất · dự kiến giao ${o.confirmedDeliveryDate}` : 'Đang sản xuất';
    case 'Shipped': return 'Đang trên đường giao';
    case 'Delivered': return 'Đã giao thành công';
    case 'CancellationRequested': return 'Đang chờ xử lý yêu cầu hủy';
    case 'Cancelled': return o.cancellationReason ? `Đã hủy · ${o.cancellationReason}` : 'Đã hủy';
    case 'Expired': return 'Đơn đã hết hạn giữ hàng';
    default: return null;
  }
};

/** OrderResponse → order card used by OrderHistoryScreen. */
export function toMobileOrder(dto) {
  const first = dto.items?.[0] || {};
  const quantity = (dto.items || []).reduce((sum, item) => sum + (item.quantity || 0), 0) || first.quantity || 0;
  return {
    id: dto.id,
    orderNumber: dto.orderNumber,
    shopName: dto.shopName || 'Xưởng bánh',
    trusted: false,
    status: ORDER_TAB[dto.status] || dto.status,
    rawStatus: dto.status,
    productId: first.productId,
    productName: first.productName,
    productImage: null,
    variantName: first.variantName,
    itemCount: dto.items?.length || 0,
    quantity,
    listPrice: Number(first.unitPrice || 0),
    unitPrice: quantity ? Number(first.subtotal || 0) / (first.quantity || 1) : Number(first.unitPrice || 0),
    totalAmount: Number(dto.totalAmount || 0),
    note: ORDER_NOTE(dto),
    allowedActions: dto.allowedActions || [],
    isFromApi: true,
  };
}

const CONTRACT_STATUS = {
  Draft: ['Bản nháp', '#6B6861'],
  PendingSignature: ['Chờ ký hợp đồng', '#9A5B0B'],
  Signed: ['Đã ký', '#3E5872'],
  PendingDeposit: ['Chờ thanh toán cọc', '#9A5B0B'],
  Active: ['Đang thực hiện', '#3E5872'],
  CompletedOnTime: ['Hoàn tất đúng hạn', '#2F7A4A'],
  CompletedLate: ['Hoàn tất trễ hạn', '#2F7A4A'],
  Breached: ['Vi phạm hợp đồng', '#8C1524'],
  Disputed: ['Đang tranh chấp', '#8C1524'],
  Cancelled: ['Đã hủy', '#6B6861'],
};

// Backend MilestoneStatus → the four states ContractsScreen renders.
const MILESTONE_STATE = {
  Pending: 'Upcoming', AwaitingPayment: 'Pending', Paid: 'Completed', InProgress: 'InProgress',
  PendingReview: 'InProgress', CompletedOnTime: 'Completed', CompletedLate: 'Completed', Overdue: 'Pending', Failed: 'Upcoming',
};
const viDate = (value) => {
  if (!value) return '—';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? String(value) : d.toLocaleDateString('vi-VN');
};

/** ContractResponse (+ milestones) → contract card used by ContractsScreen. */
export function toMobileContract(dto, milestones = dto.milestones || []) {
  const [statusLabel, statusColor] = CONTRACT_STATUS[dto.status] || [dto.status, '#6B6861'];
  return {
    id: dto.id,
    contractNumber: dto.contractNumber,
    supplierName: dto.title || 'Hợp đồng cung ứng',
    totalValue: Number(dto.totalValue || 0),
    status: dto.status,
    statusLabel,
    statusColor,
    signedDate: viDate(dto.signedByCustomerAt || dto.signedBySupplierAt),
    needsCustomerSignature: dto.status === 'PendingSignature' && !dto.signedByCustomerAt,
    milestones: [...milestones].sort((a, b) => a.sequenceNumber - b.sequenceNumber).map((m) => ({
      id: m.id,
      name: m.name,
      amount: Number(m.amount || 0),
      status: MILESTONE_STATE[m.status] || 'Upcoming',
      rawStatus: m.status,
      dueDate: viDate(m.dueDate),
      isMandatory: Boolean(m.isDeposit),
      desc: m.description || '',
    })),
    isFromApi: true,
  };
}
