class ChatSessionModel {
  final String id;
  final String userId;
  final String title;
  final String status; // ACTIVE | ARCHIVED
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSessionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      ChatSessionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class ChatMessageModel {
  final String id;
  final String sessionId;
  final String role; // USER | ASSISTANT | SYSTEM
  final String content;
  final String status; // COMPLETED | FAILED
  final String? model;
  final int? latencyMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.status,
    this.model,
    this.latencyMs,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUser => role == 'USER';
  bool get isAssistant => role == 'ASSISTANT';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        status: json['status'] as String,
        model: json['model'] as String?,
        latencyMs: json['latency_ms'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  /// Creates a temporary local message (before server confirms)
  factory ChatMessageModel.local({
    required String sessionId,
    required String role,
    required String content,
  }) =>
      ChatMessageModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        role: role,
        content: content,
        status: 'COMPLETED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
