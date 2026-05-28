class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final String period; // WEEKLY | MONTHLY
  final double amountLimit;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.period,
    required this.amountLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        category: json['category'] as String,
        period: json['period'] as String,
        amountLimit: double.parse(json['amount_limit'].toString()),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class BudgetStatusItem {
  final BudgetModel budget;
  final double spent;
  final double remaining;
  final double percentUsed;

  const BudgetStatusItem({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
  });

  factory BudgetStatusItem.fromJson(Map<String, dynamic> json) =>
      BudgetStatusItem(
        budget: BudgetModel.fromJson(json['budget'] as Map<String, dynamic>),
        spent: double.parse(json['spent'].toString()),
        remaining: double.parse(json['remaining'].toString()),
        percentUsed: (json['percent_used'] as num).toDouble(),
      );
}

class BudgetPeriod {
  static const String weekly = 'WEEKLY';
  static const String monthly = 'MONTHLY';
}
