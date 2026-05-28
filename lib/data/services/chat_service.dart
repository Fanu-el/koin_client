import 'dart:async';
import 'dart:convert';
import '../models/chat_model.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _api;

  ChatService(this._api);

  Future<ChatSessionModel> createSession({String? title}) async {
    final data = await _api.post(
      '/chats',
      body: {if (title != null) 'title': title},
    );
    return ChatSessionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ChatSessionModel>> listSessions() async {
    final data = await _api.get('/chats');
    return (data as List)
        .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatSessionModel> renameSession(String id, String title) async {
    final data = await _api.patch('/chats/$id', body: {'title': title});
    return ChatSessionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async {
    await _api.delete('/chats/$id');
  }

  Future<List<ChatMessageModel>> listMessages(String sessionId) async {
    final data = await _api.get('/chats/$sessionId/messages');
    return (data as List)
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sends a message and returns the full exchange (non-streaming).
  Future<({ChatMessageModel userMessage, ChatMessageModel assistantMessage})>
      sendMessage(String sessionId, String content) async {
    final data = await _api.post(
      '/chats/$sessionId/messages',
      body: {'content': content},
    );
    return (
      userMessage: ChatMessageModel.fromJson(
          (data as Map<String, dynamic>)['user_message']
              as Map<String, dynamic>),
      assistantMessage: ChatMessageModel.fromJson(
          data['assistant_message'] as Map<String, dynamic>),
    );
  }

  /// Streams the assistant reply via SSE.
  /// Yields text chunks as they arrive, then a final null to signal completion.
  /// The [onDone] callback receives the persisted messages when the stream ends.
  Stream<String> streamMessage(
    String sessionId,
    String content, {
    void Function(ChatMessageModel user, ChatMessageModel assistant)? onDone,
    void Function(String error)? onError,
  }) async* {
    final response = await _api.stream(
      '/chats/$sessionId/messages/stream',
      body: {'content': content},
    );

    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (!line.startsWith('data:')) continue;
      final jsonStr = line.substring(5).trim();
      if (jsonStr.isEmpty) continue;

      try {
        final event = jsonDecode(jsonStr) as Map<String, dynamic>;
        final type = event['type'] as String?;

        if (type == 'chunk') {
          final text = event['content'] as String? ?? '';
          if (text.isNotEmpty) yield text;
        } else if (type == 'done') {
          if (onDone != null) {
            final userMsg = ChatMessageModel.fromJson(
                event['user_message'] as Map<String, dynamic>);
            final assistantMsg = ChatMessageModel.fromJson(
                event['assistant_message'] as Map<String, dynamic>);
            onDone(userMsg, assistantMsg);
          }
        } else if (type == 'error') {
          final detail = event['detail'] as String? ?? 'Stream error';
          onError?.call(detail);
          return;
        }
      } catch (_) {
        // Skip malformed SSE lines
      }
    }
  }
}
