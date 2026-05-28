import '../models/finance_model.dart';
import 'api_client.dart';

class FinanceService {
  final ApiClient _api;

  FinanceService(this._api);

  Future<DashboardModel> getDashboard() async {
    final data = await _api.get('/finance/dashboard');
    return DashboardModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<MonthlyTrendItem>> getSpendingTrend({int months = 6}) async {
    final data = await _api.get(
      '/finance/spending-trend',
      queryParams: {'months': months},
    );
    return ((data as Map<String, dynamic>)['months'] as List)
        .map((e) => MonthlyTrendItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
