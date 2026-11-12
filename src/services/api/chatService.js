// Ported from mooncake-fe/src/services/chatService.js — keep both in sync.
/**
 * Chat Service
 * Handles REST communication for Customer <-> Supplier real-time messaging.
 */

import { API_ENDPOINTS } from '../../api/apiEndpoints';
import { apiClient } from '../../api/apiClient';

const DEFAULT_PAGE_SIZE = 20;
const ENABLE_MOCK_FALLBACK = process.env.EXPO_PUBLIC_ENABLE_MOCK_FALLBACK === 'true';

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

const unwrapData = (response) => response?.data ?? response ?? {};

export const chatService = {
  /**
   * Opens or returns the 1-1 conversation between the current user and a shop.
   */
  async openThread({ shopId, supplierId, signal } = {}) {
    try {
      const response = await apiClient.post(API_ENDPOINTS.CHAT.THREADS, { shopId, supplierId }, { signal });
      return unwrapData(response);
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return {
          id: 'mock-thread-1',
          viewerRole: 'Customer',
          partner: {
            userId: supplierId || 'mock-sup-1',
            displayName: 'Xưởng Bánh Trung Thu Hưng Thịnh',
            avatarUrl: null,
            role: 'Supplier',
            shopId: shopId || 'mock-shop-1',
            shopSlug: 'hung-thinh',
            presence: { isOnline: true, lastSeenAt: null },
          },
          lastMessagePreview: 'Xin chào, chúng tôi có thể hỗ trợ gì cho quý khách?',
          lastMessageSenderId: supplierId || 'mock-sup-1',
          lastActivityAt: new Date().toISOString(),
          unreadCount: 0,
          partnerLastReadMessageId: null,
          isBlocked: false,
          isBlockedByMe: false,
        };
      }
      throw error;
    }
  },

  /**
   * Loads a cursor-paginated list of the current user's conversations.
   */
  async getThreads({ cursor = null, pageSize = DEFAULT_PAGE_SIZE, signal } = {}) {
    const params = { pageSize };
    if (cursor) {
      params.cursor = cursor;
    }

    try {
      const response = await apiClient.get(API_ENDPOINTS.CHAT.THREADS, { params, signal });
      const payload = unwrapData(response);
      return {
        items: Array.isArray(payload.items) ? payload.items : [],
        hasMore: Boolean(payload.hasMore),
        nextCursor: payload.nextCursor ?? null,
      };
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return {
          items: [],
          hasMore: false,
          nextCursor: null,
        };
      }
      throw error;
    }
  },

  /**
   * Loads a single thread detail.
   */
  async getThread(threadId, { signal } = {}) {
    try {
      const response = await apiClient.get(API_ENDPOINTS.CHAT.THREAD(threadId), { signal });
      return unwrapData(response);
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return null;
      }
      throw error;
    }
  },

  /**
   * Loads historical messages within a thread (ordered oldest to newest).
   */
  async getMessages(threadId, { cursor = null, pageSize = DEFAULT_PAGE_SIZE, signal } = {}) {
    const params = { pageSize };
    if (cursor) {
      params.cursor = cursor;
    }

    try {
      const response = await apiClient.get(API_ENDPOINTS.CHAT.MESSAGES(threadId), { params, signal });
      const payload = unwrapData(response);
      return {
        items: Array.isArray(payload.items) ? payload.items : [],
        hasMore: Boolean(payload.hasMore),
        nextCursor: payload.nextCursor ?? null,
      };
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return { items: [], hasMore: false, nextCursor: null };
      }
      throw error;
    }
  },

  /**
   * Sends a message with text, product card, and/or attachments.
   */
  async sendMessage(threadId, { clientMessageId, body, productId, attachmentIds, signal } = {}) {
    try {
      const response = await apiClient.post(
        API_ENDPOINTS.CHAT.MESSAGES(threadId),
        { clientMessageId, body, productId, attachmentIds },
        { signal },
      );
      return unwrapData(response);
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return {
          id: `mock-msg-${Date.now()}`,
          threadId,
          senderId: 'current-user',
          senderRole: 'Customer',
          type: productId ? 'ProductCard' : (attachmentIds?.length ? 'Attachment' : 'Text'),
          body,
          clientMessageId,
          isRecalled: false,
          createdAt: new Date().toISOString(),
          product: null,
          attachments: [],
          isEdited: false,
          editedAt: null,
        };
      }
      throw error;
    }
  },

  /**
   * Edits the body of a previously sent message.
   */
  async editMessage(messageId, { body, signal } = {}) {
    const response = await apiClient.patch(API_ENDPOINTS.CHAT.MESSAGE(messageId), { body }, { signal });
    return unwrapData(response);
  },

  /**
   * Recalls a message (soft delete).
   */
  async recallMessage(messageId, { signal } = {}) {
    const response = await apiClient.delete(API_ENDPOINTS.CHAT.MESSAGE(messageId), { signal });
    return unwrapData(response);
  },

  /**
   * Marks a conversation as read up to a message ID.
   */
  async markRead(threadId, { messageId, signal } = {}) {
    try {
      const response = await apiClient.post(API_ENDPOINTS.CHAT.READ(threadId), { messageId }, { signal });
      return unwrapData(response);
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return { threadId, lastReadMessageId: messageId, unreadCount: 0, totalUnread: 0 };
      }
      throw error;
    }
  },

  /**
   * Blocks a thread.
   */
  async blockThread(threadId, { signal } = {}) {
    const response = await apiClient.post(API_ENDPOINTS.CHAT.BLOCK(threadId), {}, { signal });
    return unwrapData(response);
  },

  /**
   * Unblocks a previously blocked thread.
   */
  async unblockThread(threadId, { signal } = {}) {
    const response = await apiClient.post(API_ENDPOINTS.CHAT.UNBLOCK(threadId), {}, { signal });
    return unwrapData(response);
  },

  /**
   * Uploads up to 10 files (multipart/form-data) returning attachment metadata.
   */
  async uploadAttachments(files, { onProgress, signal } = {}) {
    const formData = new FormData();
    for (const file of files) {
      formData.append('files', file);
    }

    const response = await apiClient.post(API_ENDPOINTS.CHAT.ATTACHMENTS, formData, {
      signal,
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          onProgress(percent);
        }
      },
    });

    const payload = unwrapData(response);
    return Array.isArray(payload) ? payload : [];
  },

  /**
   * Fetches a signed download URL for private documents.
   */
  async getDownloadUrl(attachmentId, { signal } = {}) {
    const response = await apiClient.get(API_ENDPOINTS.CHAT.ATTACHMENT_DOWNLOAD(attachmentId), { signal });
    return unwrapData(response);
  },

  /**
   * Retrieves overall unread messages count.
   */
  async getUnreadCount({ signal } = {}) {
    try {
      const response = await apiClient.get(API_ENDPOINTS.CHAT.UNREAD_COUNT, { signal });
      const payload = unwrapData(response);
      return Number(payload?.total ?? 0);
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return 0;
      }
      throw error;
    }
  },

  /**
   * Queries live presence and last-seen for batch partner user IDs.
   */
  async getPresence(userIds, { signal } = {}) {
    if (!userIds || userIds.length === 0) {
      return [];
    }

    try {
      const response = await apiClient.get(API_ENDPOINTS.CHAT.PRESENCE, {
        params: { userIds: userIds.join(',') },
        signal,
      });
      const payload = unwrapData(response);
      return Array.isArray(payload) ? payload : [];
    } catch (error) {
      if (shouldUseMockFallback(error)) {
        return [];
      }
      throw error;
    }
  },

  /**
   * Updates privacy settings for displaying active status.
   */
  async updatePresenceSettings(showActiveStatus, { signal } = {}) {
    const response = await apiClient.put(
      API_ENDPOINTS.CHAT.PRESENCE_SETTINGS,
      { showActiveStatus },
      { signal },
    );
    return unwrapData(response);
  },
};

export default chatService;

