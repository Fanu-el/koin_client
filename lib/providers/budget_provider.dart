import 'package:cached_query/cached_query.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/error_utils.dart';
import '../data/models/budget_model.dart';
import '../data/services/budget_service.dart';
import '../data/services/query_keys.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service;
  String? _operationError;

  late final Query<List<BudgetModel>> budgetsQuery;
  late final Query<List<BudgetStatusItem>> statusQuery;

  BudgetProvider(this._service) {
    budgetsQuery = Query<List<BudgetModel>>(
      key: QueryKeys.budgets(),
      queryFn: () => _service.listBudgets(),
      config: QueryConfig(
        cacheDuration: const Duration(minutes: 5),
        refetchDuration: const Duration(minutes: 2),
      ),
    );
    statusQuery = Query<List<BudgetStatusItem>>(
      key: QueryKeys.budgetStatus(),
      queryFn: () => _service.getBudgetStatus(),
      config: QueryConfig(
        cacheDuration: const Duration(minutes: 5),
        refetchDuration: const Duration(minutes: 2),
      ),
    );
  }

  List<BudgetModel> get budgets => budgetsQuery.state.data ?? [];
  List<BudgetStatusItem> get budgetStatus => statusQuery.state.data ?? [];
  bool get loading =>
      budgetsQuery.state.status == QueryStatus.loading ||
      statusQuery.state.status == QueryStatus.loading;
  String? get error =>
      _operationError ??
      budgetsQuery.state.error?.toString() ??
      statusQuery.state.error?.toString();

  Future<void> load({bool force = false}) async {
    if (force) {
      await Future.wait([budgetsQuery.refetch(), statusQuery.refetch()]);
    } else {
      await Future.wait([budgetsQuery.result, statusQuery.result]);
    }
    notifyListeners();
  }

  Future<bool> create({
    required String category,
    required String period,
    required double amountLimit,
  }) async {
    _operationError = null;
    try {
      await _service.createBudget(
        category: category,
        period: period,
        amountLimit: amountLimit,
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

  Future<bool> update(String id, double amountLimit) async {
    _operationError = null;
    try {
      await _service.updateBudget(id, amountLimit);
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
      await _service.deleteBudget(id);
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
    CachedQuery.instance.invalidateCache(key: QueryKeys.budgets());
    CachedQuery.instance.invalidateCache(key: QueryKeys.budgetStatus());
    CachedQuery.instance.invalidateCache(key: QueryKeys.dashboard());
  }
}
