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
