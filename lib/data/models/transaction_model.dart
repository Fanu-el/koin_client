class TransactionModel {
  final String id;
  final String userId;
  final String type; // INCOME | EXPENSE
  final String category;
  final double amount;
  final String? description;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        category: json['category'] as String,
        amount: double.parse(json['amount'].toString()),
        description: json['description'] as String?,
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toCreateJson() => {
        'type': type,
        'category': category,
        'amount': amount,
        if (description != null) 'description': description,
        if (note != null) 'note': note,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      };
}

// Enums as string constants
class TransactionType {
  static const String income = 'INCOME';
  static const String expense = 'EXPENSE';
}

class TransactionCategory {
  // Expense
  static const String food = 'FOOD';
  static const String transport = 'TRANSPORT';
  static const String housing = 'HOUSING';
  static const String healthcare = 'HEALTHCARE';
  static const String entertainment = 'ENTERTAINMENT';
  static const String shopping = 'SHOPPING';
  static const String utilities = 'UTILITIES';
  static const String education = 'EDUCATION';
  static const String personal = 'PERSONAL';
  // Income
  static const String salary = 'SALARY';
  static const String freelance = 'FREELANCE';
  static const String investment = 'INVESTMENT';
  static const String gift = 'GIFT';
  // General
  static const String other = 'OTHER';

  static const List<String> expenseCategories = [
    food, transport, housing, healthcare, entertainment,
    shopping, utilities, education, personal, other,
  ];

  static const List<String> incomeCategories = [
    salary, freelance, investment, gift, other,
  ];

  static String label(String category) {
    return category[0] + category.substring(1).toLowerCase();
  }
}
