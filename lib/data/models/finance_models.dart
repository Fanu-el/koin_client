class DashboardModel {
  final double currentMonthIncome;
  final double currentMonthExpenses;
  final double currentMonthNet;

  DashboardModel({
    required this.currentMonthIncome,
    required this.currentMonthExpenses,
    required this.currentMonthNet,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) =>
      DashboardModel(
        currentMonthIncome: (json['current_month_income'] as num).toDouble(),
        currentMonthExpenses: (json['current_month_expenses'] as num).toDouble(),
        currentMonthNet: (json['current_month_net'] as num).toDouble(),
      );
}
