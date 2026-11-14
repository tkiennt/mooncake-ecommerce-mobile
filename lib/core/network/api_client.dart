import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/storage_service.dart';

class ApiClient {
  late final Dio dio;
  final StorageService _storage = StorageService();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseURL: ApiEndpoints.baseUrl,
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
                final refreshDio = Dio(BaseOptions(baseURL: ApiEndpoints.baseUrl));
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
}
