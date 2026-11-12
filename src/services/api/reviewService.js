// Ported from mooncake-fe/src/services/reviewService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response?.data?.data ?? response?.data ?? response;

export const reviewService = {
  // Transaction Review APIs (Feature #21)
  async submitTransactionReview(payload) {
    const response = await apiClient.post(API_ENDPOINTS.REVIEWS.TRANSACTION, payload);
    return unwrap(response);
  },

  async getEligibleOrdersForReview() {
    const response = await apiClient.get(API_ENDPOINTS.REVIEWS.ELIGIBLE_ORDERS);
    return unwrap(response);
  },

  async replyTransactionReview(reviewId, payload) {
    const response = await apiClient.post(API_ENDPOINTS.REVIEWS.TRANSACTION_REPLY(reviewId), payload);
    return unwrap(response);
  },

  async getShopReviews(slug, params = {}) {
    const response = await apiClient.get(API_ENDPOINTS.REVIEWS.SHOP_REVIEWS(slug), {
      params,
      skipAuthHeader: true,
      skipAuthRefresh: true,
    });
    return unwrap(response);
  },

  // Product Review APIs (Feature #22)
  async getProductReviewsFeed(productId, params = {}) {
    const response = await apiClient.get(API_ENDPOINTS.REVIEWS.PRODUCT_REVIEWS(productId), {
      params,
      skipAuthHeader: true,
      skipAuthRefresh: true,
    });
    return unwrap(response);
  },

  async getEligibleOrderItemsForProduct(productId) {
    const response = await apiClient.get(API_ENDPOINTS.REVIEWS.PRODUCT_ELIGIBLE_ITEMS(productId));
    return unwrap(response);
  },

  async createProductReview(productId, payload) {
    const response = await apiClient.post(API_ENDPOINTS.REVIEWS.PRODUCT_REVIEWS(productId), payload);
    return unwrap(response);
  },

  async toggleProductReviewLike(reviewId) {
    const response = await apiClient.post(API_ENDPOINTS.REVIEWS.PRODUCT_REVIEW_LIKE(reviewId));
    return unwrap(response);
  },

  async replyProductReview(reviewId, payload) {
    const response = await apiClient.post(API_ENDPOINTS.REVIEWS.PRODUCT_REVIEW_REPLY(reviewId), payload);
    return unwrap(response);
  },

  // Reputation APIs (Feature #22b)
  async getSupplierReputation(supplierId) {
    const response = await apiClient.get(API_ENDPOINTS.REVIEWS.SUPPLIER_REPUTATION(supplierId), {
      skipAuthHeader: true,
      skipAuthRefresh: true,
    });
    return unwrap(response);
  },

  async adminAdjustReputation(supplierId, payload) {
    const response = await apiClient.post(API_ENDPOINTS.REVIEWS.ADMIN_ADJUST_REPUTATION(supplierId), payload);
    return unwrap(response);
  },

  async adminModerateReview(reviewId, payload, isProductReview = false) {
    const response = await apiClient.patch(API_ENDPOINTS.REVIEWS.ADMIN_MODERATE(reviewId), payload, {
      params: { isProductReview },
    });
    return unwrap(response);
  },
};

export default reviewService;
