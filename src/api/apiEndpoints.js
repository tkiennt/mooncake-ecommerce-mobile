/**
 * Ported from mooncake-fe/src/constants/apiEndpoints.js so mobile and web call the same routes.
 * Mobile's apiClient baseURL already ends in /api/v1, so the /v1 prefix is dropped here.
 */
export const API_ENDPOINTS = {
  SHOPS: {
    MINE: `/shops/me`,
    MEDIA: `/shops/me/media`,
    APPEARANCE: `/shops/me/appearance`,
    VISIBILITY: `/shops/me/visibility`,
    PREVIEW: `/shops/me/preview`,
    TEMPLATES: `/shop-templates`,
    PUBLIC: (slug) => `/shops/${encodeURIComponent(slug)}`,
    PRODUCTS: (slug) => `/shops/${encodeURIComponent(slug)}/products`,
    CATEGORIES: (slug) => `/shops/${encodeURIComponent(slug)}/categories`,
    REVIEWS: (slug) => `/shops/${encodeURIComponent(slug)}/reviews`,
    ADMIN: `/admin/shops`,
    ADMIN_DETAIL: (id) => `/admin/shops/${id}`,
    MODERATE: (id) => `/admin/shops/${id}/status`,
    ADMIN_TEMPLATES: `/admin/shop-templates`,
    ADMIN_TEMPLATE: (id) => `/admin/shop-templates/${id}`,
    TEMPLATE_AVAILABILITY: (id) => `/admin/shop-templates/${id}/availability`,
    TEMPLATE_PREMIUM: (id) => `/admin/shop-templates/${id}/premium`,
    TEMPLATE_MEDIA: `/admin/shop-templates/media`,
  },

  // Authentication & Users
  AUTH: {
    LOGIN: `/auth/login`,
    REGISTER: `/auth/register`,
    LOGOUT: `/auth/logout`,
    RESEND_VERIFICATION: `/auth/resend-verification`,
    VERIFY_EMAIL: `/auth/verify-email`,
    FORGOT_PASSWORD: `/auth/forgot-password`,
    RESET_PASSWORD: `/auth/reset-password`,
    GOOGLE_AUTHORIZATION_URL: `/auth/google/authorization-url`,
    GOOGLE_LOGIN: `/auth/google/login`,
    REFRESH_TOKEN: `/auth/refresh-token`,
    ME: `/auth/me`,
    PROFILE: `/users/me`,
    PROFILE_AVATAR: `/users/me/avatar`,
  },

  // Products & Catalogs
  PRODUCTS: {
    LIST: `/products`,
    DETAILS: (id) => `/products/${id}`,
    AUTOCOMPLETE: `/products/autocomplete`,
    RECOMMENDATIONS: `/products/recommendations`,
    RELATED: (id) => `/products/${id}/related`,
    VIEW: (id) => `/products/${id}/views`,
    CATEGORIES: `/categories`,
    REGIONS: `/regions`,
    MINE: `/suppliers/me/products`,
    MINE_DETAIL: (id) => `/suppliers/me/products/${id}`,
    VARIANTS: (id) => `/suppliers/me/products/${id}/variants`,
    VARIANT: (id, variantId) => `/suppliers/me/products/${id}/variants/${variantId}`,
    INVENTORY: (id, variantId) => `/suppliers/me/products/${id}/variants/${variantId}/inventory-adjustments`,
    GALLERY: (id) => `/suppliers/me/products/${id}/gallery`,
    PUBLICATION: (id) => `/suppliers/me/products/${id}/publication`,
    MEDIA: `/suppliers/me/product-media`,
  },

  // B2B RFQ (Request for Quote) & Bidding
  RFQ: {
    CREATE: `/rfqs`,
    LIST: `/rfqs/mine`,
    SUPPLIER_LIST: `/rfqs/supplier`,
    DETAILS: (id) => `/rfqs/${id}`,
    PUBLISH: (id) => `/rfqs/${id}/publish`,
    CANCEL: (id) => `/rfqs/${id}/cancel`,
    SUGGESTED_SUPPLIERS: (id) => `/rfqs/${id}/suggested-suppliers`,
    INVITATIONS: (id) => `/rfqs/${id}/invitations`,
    DECLINE: (id) => `/rfqs/${id}/decline`,
    BIDS: (id) => `/rfqs/${id}/bids`,
    CANCEL_BID: (rfqId, bidId) => `/rfqs/${rfqId}/bids/${bidId}/cancel`,
    ACCEPT_BID: (rfqId, bidId) => `/rfqs/${rfqId}/bids/${bidId}/accept`,
    RESPOND_TO_BID_SELECTION: (rfqId, bidId) => `/rfqs/${rfqId}/bids/${bidId}/respond`,
  },

  // Enterprise Direct Bulk Orders & PoD Logistics
  ORDERS: {
    CREATE: `/orders`,
    QUOTE_PREVIEW: `/orders/quote-preview`,
    PREVIEW: `/orders/preview`,
    SHOP_POLICY: (shopId) => `/orders/shops/${shopId}/policy`,
    LIST: `/orders`,
    DETAILS: (id) => `/orders/${id}`,
    CANCEL: (id) => `/orders/${id}/cancel`,
    CUSTOMER_LIST: `/orders/mine`,
    CUSTOMER_PAGED: `/orders/mine/paged`,
    SUPPLIER_LIST: `/orders/supplier`,
    CONFIRM: (id) => `/orders/${id}/confirm`,
    REJECT: (id) => `/orders/${id}/reject`,
    PROPOSE_DELIVERY_DATE: (id) => `/orders/${id}/propose-delivery-date`,
    RESPOND_DELIVERY_PROPOSAL: (id) => `/orders/${id}/delivery-proposal/respond`,
    CANCELLATION_REQUESTS: (id) => `/orders/${id}/cancellation-requests`,
    RESPOND_CANCELLATION_REQUEST: (id, requestId) =>
      `/orders/${id}/cancellation-requests/${requestId}/respond`,
    PROCESSING: (id) => `/orders/${id}/processing`,
    SHIP: (id) => `/orders/${id}/ship`,
    PART_VNPAY_URL: (id, partId) => `/orders/${id}/payment-parts/${partId}/vnpay-url`,
    PAYMENT_SUMMARY: (id) => `/orders/${id}/payment-summary`,
    FINANCIAL_SUMMARY: (id) => `/orders/${id}/financial-summary`,
    FINANCIAL_LEDGER: (id) => `/orders/${id}/financial-ledger`,
    CONFIRM_DELIVERY: (id) => `/orders/${id}/delivery/confirm`,
    CONFIRM_DELIVERY_RECEIPT: (id) => `/orders/${id}/delivery/confirm-receipt`,
    DELIVERY_DISPUTE: (id) => `/orders/${id}/delivery/dispute`,
    REFUND_REQUESTS: (id) => `/orders/${id}/refund-requests`,
    PAYOUT_REQUESTS: (id) => `/orders/${id}/payout-requests`,
    CUSTOM_PACKAGING: (id) => `/orders/${id}/custom-packaging`,
    CUSTOM_PACKAGING_UPLOAD_LOGO: `/custom-packaging/upload-logo`,
    PACKAGING_REVISIONS: (id) => `/orders/${id}/custom-packaging/revisions`,
    REVIEW_PACKAGING_REVISION: (id, revisionId) =>
      `/orders/${id}/custom-packaging/revisions/${revisionId}/review`,
  },

  ADMIN_ORDERS: {
    OPERATIONS: `/admin/orders/operations`,
    SUMMARY: `/admin/orders/operations/summary`,
    REFUND_CASES: `/admin/orders/operations/refund-cases`,
    PAYOUT_REQUESTS: `/admin/orders/operations/payout-requests`,
    DELIVERY_DISPUTES: `/admin/orders/operations/delivery-disputes`,
    PROCESS_REFUND_CASE: (refundCaseId) => `/admin/orders/refund-cases/${refundCaseId}/process`,
    PROCESS_PAYOUT_REQUEST: (payoutRequestId) => `/admin/orders/payout-requests/${payoutRequestId}/process`,
    RESOLVE_DELIVERY_DISPUTE: (disputeId) => `/admin/orders/delivery-disputes/${disputeId}/resolve`,
  },

  // Packaging Templates
  PACKAGING_TEMPLATES: {
    BY_SHOP: (shopId) => `/shops/${shopId}/packaging-templates`,
    MINE: `/suppliers/me/packaging-templates`,
    DETAIL: (id) => `/suppliers/me/packaging-templates/${id}`,
  },

  // e-Contract & Escrow Payments
  CONTRACTS: {
    LIST: `/contracts/mine`,
    DETAILS: (id) => `/contracts/${id}`,
    SIGN: (id) => `/contracts/${id}/sign`,
    SIGNATURE_OTP: (id) => `/contracts/${id}/signature-otp`,
    SUBMIT_FOR_SIGNATURE: (id) => `/contracts/${id}/submit-for-signature`,
    MILESTONES: (id) => `/contracts/${id}/milestones`,
    SUBMIT_PROGRESS: (id, milestoneId) => `/contracts/${id}/milestones/${milestoneId}/submit-progress`,
    VERIFY_MILESTONE: (id, milestoneId) => `/contracts/${id}/milestones/${milestoneId}/verify`,
    EXTENSION_REQUEST: (id) => `/contracts/${id}/extension-request`,
    EXTENSION_RESPOND: (id) => `/contracts/${id}/extension-request/respond`,
    DISPUTE: (id) => `/contracts/${id}/dispute`,
    REQUEST_FINAL_ACCEPTANCE: (id) => `/contracts/${id}/request-final-acceptance`,
    CONFIRM_FINAL_ACCEPTANCE: (id) => `/contracts/${id}/confirm-final-acceptance`,
  },
  ADMIN_CONTRACTS: {
    RESOLVE_DISPUTE: (id) => `/admin/contracts/${id}/resolve-dispute`,
  },

  // Logistics & Proof of Delivery (PoD)
  DELIVERIES: {
    LIST: `/deliveries`,
    DETAILS: (id) => `/deliveries/${id}`,
    CREATE: `/deliveries`,
    STATUS: (id) => `/deliveries/${id}/status`,
    CARRIER_INFO: (id) => `/deliveries/${id}/carrier-info`,
    BY_CONTRACT: (contractId) => `/deliveries/contract/${contractId}`,
    BY_ORDER: (orderId) => `/deliveries/order/${orderId}`,
    PROOFS: (deliveryId) => `/deliveries/${deliveryId}/proofs`,
    PROOF_DETAILS: (proofId) => `/deliveries/proofs/${proofId}`,
    VERIFY_PROOF: (proofId) => `/deliveries/proofs/${proofId}/verify`,
  },

  PAYMENTS: {
    CREATE: `/payments`,
    LIST: `/payments/mine`,
    CONFIRM: (id) => `/payments/${id}/confirm`,
    REFUND: (id) => `/payments/${id}/refund`,
    VNPAY_CREATE_URL: `/payments/vnpay/create-url`,
    ORDER_VNPAY_URL: `/payments/orders/vnpay-url`,
    CONTRACT_VNPAY_URL: `/payments/contracts/vnpay-url`,
    BANK_TRANSFER: `/payments/bank-transfer`,
    VNPAY_RETURN: `/payments/vnpay/return-callback`,
    UPLOAD_EVIDENCE: (id) => `/payments/${id}/evidence`,
    ESCROW_SUMMARY: `/payments/escrow/summary`,
  },

  // Suppliers & Workshops
  SUPPLIERS: {
    LIST: `/suppliers`,
    DETAILS: (id) => `/suppliers/${id}`,
    APPLY: `/suppliers/me/apply`,
    START_ONBOARDING: `/suppliers/me/onboarding`,
    MY_PROFILE: `/suppliers/me`,
    ORDER_POLICY: `/suppliers/me/order-policy`,
    PAYOUT_ACCOUNT: `/suppliers/me/payout-account`,
    DOCUMENTS: `/suppliers/me/documents`,
    DOCUMENT: (id) => `/suppliers/me/documents/${id}`,
    DOCUMENT_CONTENT: (id) => `/suppliers/documents/${id}/content`,
    APPLICATIONS: `/suppliers/applications`,
    VERIFICATION: (id) => `/suppliers/${id}/verification`,
    HISTORY: (id) => `/suppliers/${id}/history`,
    MY_HISTORY: `/suppliers/me/history`,
    SUBMISSION: (profileId, submissionId) => (profileId
      ? `/suppliers/${profileId}/submissions/${submissionId}`
      : `/suppliers/me/submissions/${submissionId}`),
    REVOKE: (id) => `/suppliers/${id}/revoke`,
    PENDING: `/suppliers/pending`,
    REVIEW: (profileId) => `/suppliers/${profileId}/review`,
    PROMOTIONS: `/supplier/promotions`,
    PROMOTION: (id) => `/supplier/promotions/${id}`,
  },

  // Admin Portal & Oversight
  ADMIN: {
    DASHBOARD_STATS: `/admin/dashboard`,
    SYSTEM_CONFIG: `/admin/system-config`,
    SYSTEM_CONFIG_ITEM: (key) => `/admin/system-config/${key}`,
    AUDIT_LOGS: `/admin/audit-logs`,
    SHOPS: `/admin/shops`,
    SHOP_STATUS: (shopId) => `/admin/shops/${shopId}/status`,
    CONTRACT_DEPOSIT_RULES: `/admin/contract-deposit-rules`,
    CONTRACT_DEPOSIT_RULE: (ruleId) => `/admin/contract-deposit-rules/${ruleId}`,
    USER: (userId) => `/admin/users/${userId}`,
  },

  // Module 8: Reviews & Reputation Management
  REVIEWS: {
    TRANSACTION: `/reviews/transaction`,
    ELIGIBLE_ORDERS: `/reviews/transaction/eligible-orders`,
    TRANSACTION_REPLY: (reviewId) => `/reviews/transaction/${reviewId}/reply`,
    SHOP_REVIEWS: (slug) => `/reviews/shops/${encodeURIComponent(slug)}`,
    SUPPLIER_REPUTATION: (supplierId) => `/reviews/suppliers/${supplierId}/reputation`,
    ADMIN_ADJUST_REPUTATION: (supplierId) => `/reviews/admin/suppliers/${supplierId}/reputation/adjustment`,
    ADMIN_MODERATE: (reviewId) => `/reviews/admin/${reviewId}/moderate`,
    PRODUCT_REVIEWS: (productId) => `/products/${productId}/reviews`,
    PRODUCT_ELIGIBLE_ITEMS: (productId) => `/products/${productId}/eligible-order-items`,
    PRODUCT_REVIEW_LIKE: (reviewId) => `/products/reviews/${reviewId}/like`,
    PRODUCT_REVIEW_REPLY: (reviewId) => `/products/reviews/${reviewId}/reply`,
  },

  // Module 9: AI Chatbot & Sales Analytics
  AI: {
    CHAT_SESSIONS: `/ai/chat/sessions`,
    CHAT_MESSAGES: `/ai/chat/messages`,
    CHAT_HISTORY: (sessionToken) => `/ai/chat/sessions/${encodeURIComponent(sessionToken)}/history`,
    CHAT_END: (sessionToken) => `/ai/chat/sessions/${encodeURIComponent(sessionToken)}`,
    ANALYTICS_GENERATE: `/ai/analytics/generate`,
    ANALYTICS_REPORTS: `/ai/analytics/reports`,
    ANALYTICS_REPORT_DETAIL: (id) => `/ai/analytics/reports/${id}`,
    ANALYTICS_DASHBOARD_SUMMARY: `/ai/analytics/dashboard-summary`,
  },

  // Module 11: Real-time Notifications, Admin Operations & Reports
  NOTIFICATIONS: {
    LIST: `/notifications`,
    UNREAD_COUNT: `/notifications/unread-count`,
    READ: (id) => `/notifications/${id}/read`,
    MARK_READ: (id) => `/notifications/${id}/read`,
    READ_ALL: `/notifications/read-all`,
    MARK_ALL_READ: `/notifications/read-all`,
    PREFERENCES: `/notifications/preferences`,
    HUB_URL: `/hubs/notifications`,
  },
  DISPUTES: {
    LIST: `/admin/disputes`,
    RESOLVE: (id) => `/admin/disputes/${id}/resolve`,
    CONTRACT_RESOLVE: (contractId) => `/admin/contracts/${contractId}/resolve-dispute`,
  },
  REPORTS: {
    DASHBOARD_METRICS: `/reports/dashboard-metrics`,
    CONVERSION_FUNNEL: `/reports/conversion-funnel`,
    TOP_SUPPLIERS: `/reports/top-suppliers`,
    EXPORT: `/reports/export`,
    AI_SUMMARY: `/reports/ai-summary`,
  },

  // Wishlist (Product Favorites with Cursor Pagination)
  WISHLIST: {
    LIST: `/wishlist`,
    TOGGLE: (productId) => `/wishlist/${encodeURIComponent(productId)}`,
    CHECK: `/wishlist/check`,
  },

  // Real-time B2B Customer <-> Supplier Chat
  CHAT: {
    THREADS: `/chat/threads`,
    THREAD: (threadId) => `/chat/threads/${encodeURIComponent(threadId)}`,
    MESSAGES: (threadId) => `/chat/threads/${encodeURIComponent(threadId)}/messages`,
    MESSAGE: (messageId) => `/chat/messages/${encodeURIComponent(messageId)}`,
    READ: (threadId) => `/chat/threads/${encodeURIComponent(threadId)}/read`,
    BLOCK: (threadId) => `/chat/threads/${encodeURIComponent(threadId)}/block`,
    UNBLOCK: (threadId) => `/chat/threads/${encodeURIComponent(threadId)}/unblock`,
    ATTACHMENTS: `/chat/attachments`,
    ATTACHMENT_DOWNLOAD: (attachmentId) => `/chat/attachments/${encodeURIComponent(attachmentId)}/download`,
    UNREAD_COUNT: `/chat/unread-count`,
    PRESENCE: `/chat/presence`,
    PRESENCE_SETTINGS: `/chat/presence/settings`,
    HUB_URL: `/hubs/chat`,
  },
};

export default API_ENDPOINTS;
