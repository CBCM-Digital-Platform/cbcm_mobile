import 'package:dio/dio.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/faq_item.dart';
import '../domain/user_guide_item.dart';

class HelpRepository {
  const HelpRepository(this._dio);

  final Dio _dio;

  Future<List<FaqItem>> getFaqs({String? category}) async {
    try {
      final res = await _dio.get(
        '/settings/faqs',
        queryParameters: {
          'limit': 100,
          if (category != null && category.trim().isNotEmpty) 'category': category,
        },
      );
      final raw = res.data;
      final list = raw is Map && raw['data'] is List
          ? raw['data'] as List
          : (raw is List ? raw : const []);
      return list
          .whereType<Map>()
          .map((item) => FaqItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  Future<List<UserGuideItem>> getGuides() async {
    try {
      final res = await _dio.get(
        '/settings/guides',
        queryParameters: {'limit': 100},
      );
      final raw = res.data;
      final list = raw is Map && raw['data'] is List
          ? raw['data'] as List
          : (raw is List ? raw : const []);
      return list
          .whereType<Map>()
          .map((item) => UserGuideItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }

  String fileDownloadUrl(int fileId) {
    final base = _dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/uploads/$fileId/content';
  }
}
