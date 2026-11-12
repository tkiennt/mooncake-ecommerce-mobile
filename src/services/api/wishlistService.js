// Ported from mooncake-fe/src/services/wishlistService.js — keep both in sync.
/**
 * Wishlist Service
 * Communicates with ASP.NET Core backend /api/v1/wishlist endpoints.
 */

import { API_ENDPOINTS } from '../../api/apiEndpoints';
import { apiClient } from '../../api/apiClient';

const DEFAULT_PAGE_SIZE = 12;
const MAX_CHECK_BATCH = 100;
const ENABLE_MOCK_FALLBACK = process.env.EXPO_PUBLIC_ENABLE_MOCK_FALLBACK === 'true';

const mockSavedIds = new Set();

const isCancellationError = (error) => (
  error?.name === 'CanceledError' ||
  error?.name === 'AbortError' ||
  error?.code === 'ERR_CANCELED'
);

const shouldUseMockFallback = (error) => (
  ENABLE_MOCK_FALLBACK &&
  !isCancellationError(error) &&
  (!error?.status || error.status >= 500)
);

const normalizePagePayload = (response) => {
  const payload = response?.data ?? response ?? {};
  return {
    items: Array.isArray(payload.items) ? payload.items : [],
    hasMore: Boolean(payload.hasMore),
    nextCursor: payload.nextCursor ?? null,
    totalCount: Number(payload.totalCount ?? 0),
  };
};

export const wishlistService = {
  /**
   * Load one cursor page of saved wishlist items for the current user.
   */
  async getPage({ pageSize = DEFAULT_PAGE_SIZE, cursor = null, signal } = {}) {
    const params = { pageSize };
    if (cursor) {
      params.cursor = cursor;
    }

    try {
      const response = await apiClient.get(API_ENDPOINTS.WISHLIST.LIST, { params, signal });
      return normalizePagePayload(response);
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return {
          items: [],
          hasMore: false,
          nextCursor: null,
          totalCount: mockSavedIds.size,
        };
      }
      throw error;
    }
  },

  /**
   * Toggle a product in or out of the current user's wishlist.
   */
  async toggle(productId) {
    if (!productId) {
      throw new Error('Mã sản phẩm không hợp lệ.');
    }

    try {
      const response = await apiClient.post(API_ENDPOINTS.WISHLIST.TOGGLE(productId));
      const payload = response?.data ?? response ?? {};
      return {
        productId: payload.productId ?? productId,
        isSaved: Boolean(payload.isSaved),
        totalCount: Number(payload.totalCount ?? 0),
        message: response?.message ?? '',
      };
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        const key = String(productId);
        const isSaved = !mockSavedIds.has(key);
        if (isSaved) {
          mockSavedIds.add(key);
        } else {
          mockSavedIds.delete(key);
        }
        return {
          productId: key,
          isSaved,
          totalCount: mockSavedIds.size,
          message: isSaved ? 'Đã thêm vào danh sách yêu thích.' : 'Đã bỏ khỏi danh sách yêu thích.',
        };
      }
      throw error;
    }
  },

  /**
   * Check saved status for a batch of visible product IDs (max 100 per request).
   */
  async check(productIds = [], signal) {
    const uniqueIds = [...new Set(
      (Array.isArray(productIds) ? productIds : [])
        .map((id) => (id ? String(id).trim() : ''))
        .filter(Boolean)
    )];

    if (uniqueIds.length === 0) {
      return [];
    }

    const savedSet = new Set();

    try {
      for (let index = 0; index < uniqueIds.length; index += MAX_CHECK_BATCH) {
        const chunk = uniqueIds.slice(index, index + MAX_CHECK_BATCH);
        const response = await apiClient.get(API_ENDPOINTS.WISHLIST.CHECK, {
          params: { ids: chunk.join(',') },
          signal,
        });
        const payload = response?.data ?? response ?? {};
        const chunkSaved = Array.isArray(payload.savedIds) ? payload.savedIds : [];
        chunkSaved.forEach((id) => savedSet.add(String(id)));
      }
      return [...savedSet];
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return uniqueIds.filter((id) => mockSavedIds.has(id));
      }
      throw error;
    }
  },
};

export default wishlistService;

