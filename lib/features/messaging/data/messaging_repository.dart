import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../domain/message_models.dart';

/// Used when the server answers with something we can't read.
class MessagingException implements Exception {
  const MessagingException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Text to show the user for any error thrown by this repository.
String messagingErrorText(Object error) {
  if (error is ApiException) return error.error.message;
  if (error is MessagingException) return error.message;
  return 'Something went wrong. Please try again.';
}

class MessagingRepository {
  MessagingRepository(this._dio);

  final Dio _dio;

  // The base URL already ends in /api/v1, so paths start at /messages.
  static const _prefix = '/messages';

  /// GET /messages/contacts: the people the signed-in user may message.
  Future<List<MessageUser>> listContacts() async {
    final body = await _call(() => _getWithFallback('$_prefix/contacts'));
    final data = body['data'] ?? body;
    final list = data is List
        ? data
        : (data is Map ? (data['contacts'] ?? data['items'] ?? data['users']) : null);
    return (list is List ? list : const [])
        .whereType<Map>()
        .map((m) => MessageUser.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// GET /messages/conversations
  Future<List<Conversation>> listConversations() async {
    final body = await _call(() => _getWithFallback('$_prefix/conversations'));
    final data = body['data'] ?? body;
    final list = data is List
        ? data
        : (data is Map ? (data['conversations'] ?? data['items'] ?? data['list']) : null);
    return (list is List ? list : const [])
        .whereType<Map>()
        .map((m) => Conversation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// GET /messages/conversations/{id}  (messages oldest first)
  Future<Conversation> getConversation(int id) async {
    final body = await _call(() => _getWithFallback('$_prefix/conversations/$id'));
    return Conversation.fromJson(_dataMap(body, ['conversation']));
  }

  /// POST /messages/conversations  (returns the existing one if it exists)
  Future<Conversation> createDirectConversation(int otherUserId) async {
    final body = await _call(
      () => _postWithFallback(
        '$_prefix/conversations',
        data: {
          'participantIds': [otherUserId],
          'type': 'direct',
        },
      ),
    );
    return Conversation.fromJson(_dataMap(body, ['conversation']));
  }

  /// POST /messages/conversations/{id}/messages
  Future<ChatMessage> sendMessage(
    int conversationId,
    String content, {
    int? attachmentFileId,
  }) async {
    final body = await _call(
      () => _postWithFallback(
        '$_prefix/conversations/$conversationId/messages',
        data: {
          'content': content,
          if (attachmentFileId != null) 'attachmentFileIds': [attachmentFileId],
        },
      ),
    );
    return ChatMessage.fromJson(_dataMap(body, ['message']));
  }

  /// PATCH /messages/conversations/{id}/read
  Future<void> markRead(int conversationId) async {
    await _call(() => _patchWithFallback('$_prefix/conversations/$conversationId/read'));
  }

  /// PATCH /messages/conversations/{id}/messages/{messageId}
  Future<ChatMessage> editMessage(
    int conversationId,
    int messageId,
    String content,
  ) async {
    final body = await _call(
      () => _patchWithFallback(
        '$_prefix/conversations/$conversationId/messages/$messageId',
        data: {'content': content},
      ),
    );
    return ChatMessage.fromJson(_dataMap(body, ['message']));
  }

  /// DELETE /messages/conversations/{id}/messages/{messageId}
  Future<void> deleteMessage(int conversationId, int messageId) async {
    await _call(
      () => _dio
          .delete('$_prefix/conversations/$conversationId/messages/$messageId'),
    );
  }

  // ---- helpers ----

  Future<Response<dynamic>> _patchWithFallback(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 && path.startsWith(_prefix)) {
        final rawBase = _dio.options.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
        return await _dio.patch('$rawBase$path', data: data);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _getWithFallback(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 && path.startsWith(_prefix)) {
        final rawBase = _dio.options.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
        return await _dio.get('$rawBase$path');
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> _postWithFallback(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 && path.startsWith(_prefix)) {
        final rawBase = _dio.options.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
        return await _dio.post('$rawBase$path', data: data);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _dataMap(
    Map<String, dynamic> body,
    List<String> wrapperKeys,
  ) {
    final data = body['data'] ?? body;
    if (data is! Map) {
      throw const MessagingException('Unexpected response from the server.');
    }
    final map = Map<String, dynamic>.from(data);
    for (final key in wrapperKeys) {
      final inner = map[key];
      if (inner is Map) return Map<String, dynamic>.from(inner);
    }
    return map;
  }

  Future<Map<String, dynamic>> _call(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final res = await request();
      final body = res.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      throw const MessagingException('Unexpected response from the server.');
    } on DioException catch (e) {
      throw apiExceptionFromDio(e);
    }
  }
}