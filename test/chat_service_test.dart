import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:koin_client/data/services/api_client.dart';
import 'package:koin_client/data/services/chat_service.dart';

class FakeApiClient implements ApiClient {
  @override
  void setRefreshHandler(Future<bool> Function()? handler) {}
  @override
  Future<dynamic> delete(String path, {bool auth = true}) async {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, bool auth = true}) async {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true, String? customHeader, String? customHeaderValue}) async {
    // Return a simulated response payload similar to backend ApiClient._parse output
    return {
      'user_message': {
        'id': 'u1',
        'session_id': 's1',
        'role': 'USER',
        'content': body?['content'] ?? '',
        'status': 'COMPLETED',
        'model': null,
        'latency_ms': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      'assistant_message': {
        'id': 'a1',
        'session_id': 's1',
        'role': 'ASSISTANT',
        'content': 'This is a reply',
        'status': 'COMPLETED',
        'model': 'gemini/gemini-2.5-flash',
        'latency_ms': 123,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }
    };
  }

  @override
  Future<http.StreamedResponse> stream(String path, {Map<String, dynamic>? body, String? llmModel}) async {
    throw UnimplementedError();
  }
}

void main() {
  test('ChatService.sendMessage returns parsed messages', () async {
    final api = FakeApiClient();
    final svc = ChatService(api as dynamic);

    final result = await svc.sendMessage('s1', 'hello');

    expect(result.userMessage.content, 'hello');
    expect(result.assistantMessage.content, 'This is a reply');
    expect(result.assistantMessage.model, 'gemini/gemini-2.5-flash');
  });
}
