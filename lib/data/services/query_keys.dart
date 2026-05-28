/// Centralised cache key definitions for cached_query.
/// Using lists ensures structural equality for cache lookups.
class QueryKeys {
  QueryKeys._();

  static List<Object> dashboard() => ['dashboard'];
  static List<Object> transactions({String? type}) =>
      ['transactions', type ?? 'all'];
  static List<Object> budgets() => ['budgets'];
  static List<Object> budgetStatus() => ['budget_status'];
  static List<Object> goals({String? status}) =>
      ['goals', status ?? 'all'];
  static List<Object> chatSessions() => ['chat_sessions'];
  static List<Object> chatMessages(String sessionId) =>
      ['chat_messages', sessionId];
}
