import 'package:cached_query/cached_query.dart';
import 'package:flutter/foundation.dart';
import '../data/models/chat_model.dart';
import '../data/services/chat_service.dart';
import '../data/services/query_keys.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service;

  late Query<List<ChatSessionModel>> sessionsQuery;

  // Active session state (not cached — ephemeral per-session)
  ChatSessionModel? _activeSession;
  List<ChatMessageModel> _messages = [];
  bool _loadingMessages = false;
  bool _sending = false;
  String? _streamingContent;
  String? _error;

  ChatProvider(this._service) {
    sessionsQuery = Query<List<ChatSessionModel>>(
      key: QueryKeys.chatSessions(),
      queryFn: () async {
        final sessions = await _service.listSessions();
        sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return sessions;
      },
      config: QueryConfig(
        cacheDuration: const Duration(minutes: 10),
        refetchDuration: const Duration(minutes: 3),
      ),
    );
  }

  List<ChatSessionModel> get sessions => sessionsQuery.state.data ?? [];
  bool get loadingSessions =>
      sessionsQuery.state.status == QueryStatus.loading;

  ChatSessionModel? get activeSession => _activeSession;
  List<ChatMessageModel> get messages => _messages;
  bool get loadingMessages => _loadingMessages;
  bool get sending => _sending;
  String? get streamingContent => _streamingContent;
  String? get error => _error;
  bool get isStreaming => _streamingContent != null;

  Future<void> loadSessions({bool force = false}) async {
    if (force) {
      await sessionsQuery.refetch();
    } else {
      await sessionsQuery.result;
    }
    notifyListeners();
  }

  Future<ChatSessionModel?> createSession({String? title}) async {
    try {
      final session = await _service.createSession(title: title);
      CachedQuery.instance.invalidateCache(key: QueryKeys.chatSessions());
      await sessionsQuery.refetch();
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> openSession(ChatSessionModel session) async {
    _activeSession = session;
    _messages = [];
    _streamingContent = null;
    notifyListeners();
    await _loadMessages(session.id);
  }

  Future<void> _loadMessages(String sessionId) async {
    _loadingMessages = true;
    notifyListeners();
    try {
      // Use a short-lived query for messages
      final q = Query<List<ChatMessageModel>>(
        key: QueryKeys.chatMessages(sessionId),
        queryFn: () => _service.listMessages(sessionId),
        config: QueryConfig(cacheDuration: const Duration(minutes: 30)),
      );
      final result = await q.result;
      _messages = result.data ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_activeSession == null || _sending) return;

    _sending = true;
    _error = null;

    final userMsg = ChatMessageModel.local(
      sessionId: _activeSession!.id,
      role: 'USER',
      content: content,
    );
    _messages = [..._messages, userMsg];
    _streamingContent = '';
    notifyListeners();

    try {
      final res = await _service.sendMessage(_activeSession!.id, content);
      // Replace local user message with persisted user and assistant messages
      _messages = [
        ..._messages.where((m) => m.id != userMsg.id),
        res.userMessage,
        res.assistantMessage,
      ];
      _streamingContent = null;
      CachedQuery.instance.invalidateCache(
        key: QueryKeys.chatMessages(_activeSession!.id),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _streamingContent = null;
      notifyListeners();
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> renameSession(String id, String title) async {
    try {
      await _service.renameSession(id, title);
      CachedQuery.instance.invalidateCache(key: QueryKeys.chatSessions());
      await sessionsQuery.refetch();
      if (_activeSession?.id == id) {
        _activeSession = sessions.firstWhere(
          (s) => s.id == id,
          orElse: () => _activeSession!,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await _service.deleteSession(id);
      CachedQuery.instance.invalidateCache(key: QueryKeys.chatSessions());
      CachedQuery.instance.invalidateCache(key: QueryKeys.chatMessages(id));
      await sessionsQuery.refetch();
      if (_activeSession?.id == id) {
        _activeSession = null;
        _messages = [];
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
