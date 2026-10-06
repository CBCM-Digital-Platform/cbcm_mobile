import 'package:dio/dio.dart';
import '../../env/env_config.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

class DioClient {
  DioClient() : dio = Dio(
          BaseOptions(
            baseUrl: EnvConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage().read(StorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // On 401, a real refresh call goes here once the backend exists:
          //   POST ApiEndpoints.refreshToken with the stored refresh token,
          //   save the new access token, retry the original request once.
          // For now, just pass the error through.
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
}