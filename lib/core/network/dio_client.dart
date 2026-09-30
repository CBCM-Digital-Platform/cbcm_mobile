import 'package:dio/dio.dart';
import '../../env/env_config.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO(Week 2): attach the auth token here once secure_storage
          // holds a real one, e.g.:
          // final token = await secureStorage.read('access_token');
          // if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          // TODO(Week 2): on a 401, try refresh, then retry the request once.
          handler.next(error);
        },
      ),
    );
  }
}