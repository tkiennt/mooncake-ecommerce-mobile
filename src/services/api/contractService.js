// Ported from mooncake-fe/src/services/contractService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response?.data ?? response;

export const contractService = {
  async listMine() {
    return unwrap(await apiClient.get(API_ENDPOINTS.CONTRACTS.LIST));
  },
  async listMinePaged(params = {}, signal) {
    return unwrap(await apiClient.get(API_ENDPOINTS.CONTRACTS.LIST, { params, signal }));
  },

  async get(contractId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.CONTRACTS.DETAILS(contractId)));
  },

  async requestSignatureOtp(contractId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.SIGNATURE_OTP(contractId), {}));
  },

  async submitForSignature(contractId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.SUBMIT_FOR_SIGNATURE(contractId), {}));
  },

  async sign(contractId, otpCode, confirmTerms) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.SIGN(contractId), {
      otpCode,
      confirmTerms,
    }));
  },

  async getMilestones(contractId) {
    return unwrap(await apiClient.get(API_ENDPOINTS.CONTRACTS.MILESTONES(contractId)));
  },

  async submitProgress(contractId, milestoneId, progressNotes, evidenceUrls = []) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.SUBMIT_PROGRESS(contractId, milestoneId), {
      progressNotes,
      evidenceUrls,
    }));
  },

  async verifyMilestone(contractId, milestoneId, isApproved, rejectionReason = '') {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.VERIFY_MILESTONE(contractId, milestoneId), {
      isApproved,
      rejectionReason,
    }));
  },

  async requestExtension(contractId, proposedDueDate, reason) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.EXTENSION_REQUEST(contractId), {
      proposedDueDate,
      reason,
    }));
  },

  async respondExtension(contractId, isApproved, responseNote = '') {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.EXTENSION_RESPOND(contractId), {
      isApproved,
      responseNote,
    }));
  },

  async raiseDispute(contractId, disputeReason, evidenceUrls = []) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.DISPUTE(contractId), {
      disputeReason,
      evidenceUrls,
    }));
  },

  async requestFinalAcceptance(contractId) {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.REQUEST_FINAL_ACCEPTANCE(contractId), {}));
  },

  async confirmFinalAcceptance(contractId, confirmedQualityAndQuantity = true, acceptanceNotes = '') {
    return unwrap(await apiClient.post(API_ENDPOINTS.CONTRACTS.CONFIRM_FINAL_ACCEPTANCE(contractId), {
      confirmedQualityAndQuantity,
      acceptanceNotes,
    }));
  },

  async resolveDispute(contractId, resolutionType, refundAmount, adminVerdict) {
    return unwrap(await apiClient.post(API_ENDPOINTS.ADMIN_CONTRACTS.RESOLVE_DISPUTE(contractId), {
      resolutionType,
      refundAmount,
      adminVerdict,
    }));
  },
};

export default contractService;
