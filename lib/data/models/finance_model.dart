import 'budget_model.dart';
import 'savings_goal_model.dart';

class CategoryBreakdownItem {
  final String category;
  final double total;
  final int count;
  final double percent;

  const CategoryBreakdownItem({
    required this.category,
    required this.total,
    required this.count,
    required this.percent,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdownItem(
        category: json['category'] as String,
        total: double.parse(json['total'].toString()),
        count: json['count'] as int,
        percent: (json['percent'] as num).toDouble(),
      );
}

class MonthlyTrendItem {
  final int year;
  final int month;
  final double income;
  final double expenses;
  final double net;

  const MonthlyTrendItem({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
  });

  factory MonthlyTrendItem.fromJson(Map<String, dynamic> json) =>
      MonthlyTrendItem(
        year: json['year'] as int,
        month: json['month'] as int,
        income: double.parse(json['income'].toString()),
        expenses: double.parse(json['expenses'].toString()),
        net: double.parse(json['net'].toString()),
      );
}

class DashboardModel {
  final double currentMonthIncome;
  final double currentMonthExpenses;
  final double currentMonthNet;
  final List<CategoryBreakdownItem> expenseBreakdown;
  final List<BudgetStatusItem> budgetStatus;
  final List<SavingsGoalModel> activeSavingsGoals;
  final List<MonthlyTrendItem> monthlyTrend;

  const DashboardModel({
    required this.currentMonthIncome,
    required this.currentMonthExpenses,
    required this.currentMonthNet,
    required this.expenseBreakdown,
    required this.budgetStatus,
    required this.activeSavingsGoals,
    required this.monthlyTrend,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        currentMonthIncome:
            double.parse(json['current_month_income'].toString()),
        currentMonthExpenses:
            double.parse(json['current_month_expenses'].toString()),
        currentMonthNet: double.parse(json['current_month_net'].toString()),
        expenseBreakdown: (json['expense_breakdown'] as List)
            .map((e) =>
                CategoryBreakdownItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        budgetStatus: (json['budget_status'] as List)
            .map((e) => BudgetStatusItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeSavingsGoals: (json['active_savings_goals'] as List)
            .map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        monthlyTrend: (json['monthly_trend'] as List)
            .map((e) => MonthlyTrendItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
