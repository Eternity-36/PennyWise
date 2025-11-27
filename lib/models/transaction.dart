import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool isExpense;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String accountId;

  @HiveField(7)
  final String? userId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
    this.accountId = 'default',
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
      'category': category,
      'accountId': accountId,
      'userId': userId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      isExpense: json['isExpense'],
      category: json['category'],
      accountId: json['accountId'] ?? 'default',
      userId: json['userId'],
    );
  }
}
