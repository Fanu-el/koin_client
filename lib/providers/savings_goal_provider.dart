import 'package:cached_query/cached_query.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/error_utils.dart';
import '../data/models/savings_goal_model.dart';
import '../data/services/query_keys.dart';
import '../data/services/savings_goal_service.dart';

class SavingsGoalProvider extends ChangeNotifier {
  final SavingsGoalService _service;
  String? _operationError;

  late final Query<List<SavingsGoalModel>> goalsQuery;

  SavingsGoalProvider(this._service) {
    goalsQuery = Query<List<SavingsGoalModel>>(
      key: QueryKeys.goals(),
      queryFn: () => _service.listGoals(),
      config: QueryConfig(
        cacheDuration: const Duration(minutes: 5),
        refetchDuration: const Duration(minutes: 2),
      ),
    );
  }

  List<SavingsGoalModel> get goals => goalsQuery.state.data ?? [];
  List<SavingsGoalModel> get activeGoals =>
      goals.where((g) => g.status == SavingsGoalStatus.active).toList();
  bool get loading => goalsQuery.state.status == QueryStatus.loading;
  String? get error => _operationError ?? goalsQuery.state.error?.toString();

  Future<void> load({bool force = false}) async {
    if (force) {
      await goalsQuery.refetch();
    } else {
      await goalsQuery.result;
    }
    notifyListeners();
  }

  Future<bool> create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? targetDate,
    String? description,
  }) async {
    _operationError = null;
    try {
      await _service.createGoal(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        description: description,
      );
      _invalidate();
      await load(force: true);
      return true;
    } catch (e) {
      _operationError = formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? description,
    String? status,
  }) async {
    _operationError = null;
    try {
      await _service.updateGoal(
        id,
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        description: description,
        status: status,
      );
      _invalidate();
      await load(force: true);
      return true;
    } catch (e) {
      _operationError = formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    _operationError = null;
    try {
      await _service.deleteGoal(id);
      _invalidate();
      await load(force: true);
      return true;
    } catch (e) {
      _operationError = formatError(e);
      notifyListeners();
      return false;
    }
  }

  void _invalidate() {
    CachedQuery.instance.invalidateCache(key: QueryKeys.goals());
    CachedQuery.instance.invalidateCache(key: QueryKeys.dashboard());
  }
}
