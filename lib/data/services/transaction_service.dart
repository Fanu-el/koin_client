import '../models/transaction_model.dart';
import 'api_client.dart';

class TransactionService {
  final ApiClient _api;

  TransactionService(this._api);

  Future<List<TransactionModel>> listTransactions({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _api.get(
      '/transactions',
      queryParams: {
        if (type != null) 'type': type,
        'limit': limit,
        'offset': offset,
      },
    );
    return (data as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> createTransaction({
    required String type,
    required String category,
    required double amount,
    String? description,
    String? note,
    required DateTime date,
  }) async {
    final tx = TransactionModel(
      id: '',
      userId: '',
      type: type,
      category: category,
      amount: amount,
      description: description,
      note: note,
      date: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final data = await _api.post('/transactions', body: tx.toCreateJson());
    return TransactionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransaction(String id) async {
    final data = await _api.get('/transactions/$id');
    return TransactionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TransactionModel> updateTransaction(
    String id, {
    String? type,
    String? category,
    double? amount,
    String? description,
    String? note,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
      if (date != null)
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
    final data = await _api.patch('/transactions/$id', body: body);
    return TransactionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) async {
    await _api.delete('/transactions/$id');
  }
}
