import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/contract.dart';

class ContractRepository {
  final ApiClient _client;

  ContractRepository(this._client);

  /// Gets customer's contracts list
  Future<List<ContractModel>> getMyContracts({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.myContracts,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((c) => ContractModel.fromJson(
              c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets complete contract details with clauses, escrow deposit and milestones
  Future<ContractModel> getContractDetails(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.contractDetails(id));
      final data = ApiClient.unwrap(response);
      return ContractModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Requests a one-time OTP for digital signature
  Future<void> requestSignatureOtp(String id) async {
    try {
      await _client.dio.post(ApiEndpoints.contractSignatureOtp(id));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Signs the contract digitally with verified OTP
  Future<ContractModel> signContract(
    String id, {
    required String otpCode,
    bool confirmTerms = true,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.signContract(id),
        data: {
          'otpCode': otpCode,
          'confirmTerms': confirmTerms,
        },
      );
      final data = ApiClient.unwrap(response);
      return ContractModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets milestone schedule and progress verification for contract
  Future<List<ContractMilestone>> getMilestones(String id) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.contractMilestones(id));
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((m) => ContractMilestone.fromJson(
              m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Customer approves or disputes a production milestone
  Future<void> verifyMilestone(
    String contractId,
    String milestoneId, {
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      await _client.dio.post(
        ApiEndpoints.verifyContractMilestone(contractId, milestoneId),
        data: {
          'isApproved': isApproved,
          if (rejectionReason != null) 'rejectionReason': rejectionReason,
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Generates VNPay payment URL for contract escrow deposit
  Future<String> createContractVnPayUrl({
    required String contractId,
    String? returnUrl,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.contractVnPayUrl,
        data: {
          'contractId': contractId,
          if (returnUrl != null) 'returnUrl': returnUrl,
        },
      );
      final data = ApiClient.unwrap(response);
      return data['paymentUrl']?.toString() ?? data['url']?.toString() ?? data.toString();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ContractRepository(client);
});
