import '../models/savings_goal_model.dart';
import 'api_client.dart';

class SavingsGoalService {
  final ApiClient _api;

  SavingsGoalService(this._api);

  Future<List<SavingsGoalModel>> listGoals({String? status}) async {
    final data = await _api.get(
      '/savings-goals',
      queryParams: {if (status != null) 'status': status},
    );
    return (data as List)
        .map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SavingsGoalModel> createGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? targetDate,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (targetDate != null)
        'target_date':
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
      if (description != null) 'description': description,
    };
    final data = await _api.post('/savings-goals', body: body);
    return SavingsGoalModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SavingsGoalModel> updateGoal(
    String id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? description,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (targetDate != null)
        'target_date':
            '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
      if (description != null) 'description': description,
      if (status != null) 'status': status,
    };
    final data = await _api.patch('/savings-goals/$id', body: body);
    return SavingsGoalModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteGoal(String id) async {
    await _api.delete('/savings-goals/$id');
  }
}
