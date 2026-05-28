import '../models/budget_model.dart';
import 'api_client.dart';

class BudgetService {
  final ApiClient _api;

  BudgetService(this._api);

  Future<List<BudgetModel>> listBudgets() async {
    final data = await _api.get('/budgets');
    return (data as List)
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetModel> createBudget({
    required String category,
    required String period,
    required double amountLimit,
  }) async {
    final data = await _api.post('/budgets', body: {
      'category': category,
      'period': period,
      'amount_limit': amountLimit,
    });
    return BudgetModel.fromJson(data as Map<String, dynamic>);
  }

  Future<BudgetModel> updateBudget(String id, double amountLimit) async {
    final data = await _api.patch(
      '/budgets/$id',
      body: {'amount_limit': amountLimit},
    );
    return BudgetModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBudget(String id) async {
    await _api.delete('/budgets/$id');
  }

  Future<List<BudgetStatusItem>> getBudgetStatus() async {
    final data = await _api.get('/finance/budget-status');
    return (data as List)
        .map((e) => BudgetStatusItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
