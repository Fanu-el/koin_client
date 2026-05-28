import 'package:cached_query/cached_query.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/error_utils.dart';
import '../data/models/transaction_model.dart';
import '../data/services/query_keys.dart';
import '../data/services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionService _service;
  String? _operationError;

  // One InfiniteQuery per type filter (null = all, INCOME, EXPENSE)
  final Map<String, InfiniteQuery<List<TransactionModel>, int>> _queries = {};

  static const _pageSize = 50;

  TransactionProvider(this._service);

  InfiniteQuery<List<TransactionModel>, int> _queryFor(String? type) {
    final k = type ?? 'all';
    return _queries.putIfAbsent(
      k,
      () => InfiniteQuery<List<TransactionModel>, int>(
        key: QueryKeys.transactions(type: type),
        getNextArg: (state) {
          final pages = state.data ?? [];
          if (pages.isEmpty) return 0;
          final last = pages.last;
          if (last.length < _pageSize) return null; // no more pages
          return pages.fold<int>(0, (sum, p) => sum + p.length);
        },
        queryFn: (offset) => _service.listTransactions(
          type: type,
          limit: _pageSize,
          offset: offset,
        ),
        config: QueryConfig(
          cacheDuration: const Duration(minutes: 3),
          refetchDuration: const Duration(minutes: 1),
        ),
      ),
    );
  }

  InfiniteQueryState<List<TransactionModel>> stateFor(String? type) =>
      _queryFor(type).state;

  List<TransactionModel> transactionsFor(String? type) {
    final pages = _queryFor(type).state.data ?? [];
    return pages.expand((p) => p).toList();
  }

  bool loadingFor(String? type) =>
      _queryFor(type).state.status == QueryStatus.loading;

  String? errorFor(String? type) {
    return _operationError ?? _queryFor(type).state.error?.toString();
  }

  bool hasMoreFor(String? type) =>
      _queryFor(type).hasReachedMax() != true;

  Future<void> load({String? type, bool refresh = false}) async {
    final q = _queryFor(type);
    if (refresh) {
      await q.refetch();
    } else {
      await q.getNextPage();
    }
    notifyListeners();
  }

  Future<bool> create({
    required String type,
    required String category,
    required double amount,
    String? description,
    String? note,
    required DateTime date,
  }) async {
    _operationError = null;
    try {
      await _service.createTransaction(
        type: type,
        category: category,
        amount: amount,
        description: description,
        note: note,
        date: date,
      );
      _invalidateAll();
      await Future.wait([
        load(refresh: true, type: null),
        load(refresh: true, type: 'INCOME'),
        load(refresh: true, type: 'EXPENSE'),
      ]);
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
      await _service.deleteTransaction(id);
      _invalidateAll();
      await Future.wait([
        load(refresh: true, type: null),
        load(refresh: true, type: 'INCOME'),
        load(refresh: true, type: 'EXPENSE'),
      ]);
      return true;
    } catch (e) {
      _operationError = formatError(e);
      notifyListeners();
      return false;
    }
  }

  void _invalidateAll() {
    for (final type in [null, 'INCOME', 'EXPENSE']) {
      CachedQuery.instance.invalidateCache(
        key: QueryKeys.transactions(type: type),
      );
    }
    CachedQuery.instance.invalidateCache(key: QueryKeys.dashboard());
    CachedQuery.instance.invalidateCache(key: QueryKeys.budgetStatus());
    _queries.clear();
  }
}
