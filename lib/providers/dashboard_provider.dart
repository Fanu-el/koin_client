import 'package:cached_query/cached_query.dart';
import 'package:flutter/foundation.dart';
import '../data/models/finance_model.dart';
import '../data/services/finance_service.dart';
import '../data/services/query_keys.dart';

class DashboardProvider extends ChangeNotifier {
  final FinanceService _financeService;

  late final Query<DashboardModel> query;

  DashboardProvider(this._financeService) {
    query = Query<DashboardModel>(
      key: QueryKeys.dashboard(),
      queryFn: () => _financeService.getDashboard(),
      config: QueryConfig(
        cacheDuration: const Duration(minutes: 5),
        refetchDuration: const Duration(minutes: 2),
      ),
    );
  }

  QueryState<DashboardModel> get state => query.state;
  DashboardModel? get dashboard => query.state.data;
  bool get loading => query.state.status == QueryStatus.loading;
  String? get error => query.state.error?.toString();

  Future<void> load({bool force = false}) async {
    if (force) {
      await query.refetch();
    } else {
      await query.result;
    }
    notifyListeners();
  }

  /// Invalidate so next access re-fetches.
  void invalidate() {
    CachedQuery.instance.invalidateCache(key: QueryKeys.dashboard());
    notifyListeners();
  }
}
