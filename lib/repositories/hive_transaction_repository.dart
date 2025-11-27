import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

class HiveTransactionRepository implements TransactionRepository {
  final Box<Transaction> _box;

  HiveTransactionRepository(this._box);

  @override
  Future<List<Transaction>> getTransactions() async {
    return _box.values.toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    // Use the transaction ID as the key for direct access
    await _box.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (_box.containsKey(id)) {
      await _box.delete(id);
    } else {
      // Fallback for legacy data where key might be an integer
      try {
        final transaction = _box.values.firstWhere((t) => t.id == id);
        await transaction.delete();
      } catch (e) {
        // Transaction not found
      }
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
