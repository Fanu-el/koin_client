class SavingsGoalModel {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String status; // ACTIVE | COMPLETED | CANCELLED
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      SavingsGoalModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        targetAmount: double.parse(json['target_amount'].toString()),
        currentAmount: double.parse(json['current_amount'].toString()),
        targetDate: json['target_date'] != null
            ? DateTime.parse(json['target_date'] as String)
            : null,
        status: json['status'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class SavingsGoalStatus {
  static const String active = 'ACTIVE';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}
