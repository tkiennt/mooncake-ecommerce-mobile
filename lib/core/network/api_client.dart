import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio dio;
  final StorageService _storage = StorageService();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Attempt token refresh
            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
                final response = await refreshDio.post(
                  ApiEndpoints.refreshToken,
                  data: {'refreshToken': refreshToken},
                );

                final data = response.data['data'] ?? response.data;
                final newAccessToken = data['accessToken']?.toString();
                final newRefreshToken = data['refreshToken']?.toString();

                if (newAccessToken != null && newRefreshToken != null) {
                  await _storage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry original request
                  final reqOptions = error.requestOptions;
                  reqOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(reqOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                await _storage.clearAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Unwraps backend Response envelope: { status, message, data, ... }
  static dynamic unwrap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return body.containsKey('data') ? body['data'] : body;
    }
    return body;
  }

  /// Converts any exception into a user-friendly ApiException with Vietnamese message
  static ApiException handleError(dynamic error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final res = error.response;
      if (res?.data is Map) {
        final msg = res!.data['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return ApiException(msg, statusCode: res.statusCode, details: res.data);
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return ApiException(
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại.',
          statusCode: res?.statusCode,
        );
      }
      if (res?.statusCode == 401) {
        return ApiException('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.', statusCode: 401);
      }
      if (res?.statusCode == 403) {
        return ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
      }
      if (res?.statusCode == 404) {
        return ApiException('Không tìm thấy tài nguyên yêu cầu.', statusCode: 404);
      }
      if (res?.statusCode == 409) {
        return ApiException('Dữ liệu bị trùng lặp hoặc xung đột phiên bản.', statusCode: 409);
      }
      if (res?.statusCode != null && res!.statusCode! >= 500) {
        return ApiException('Hệ thống đang bảo trì hoặc gặp sự cố. Vui lòng thử lại sau.', statusCode: res.statusCode);
      }
    }
    return ApiException(error?.toString() ?? 'Đã xảy ra lỗi không xác định.');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
