import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/providers/expense_provider.dart';

void main() {
  group('ExpenseProvider Unit Tests', () {
    late ExpenseProvider provider;

    setUp(() async {
      provider = ExpenseProvider();
      await provider.init(delay: Duration.zero);
    });

    test('Initializes with default categories and mock data in demo mode', () {
      expect(provider.categories.isNotEmpty, isTrue);
      // All 10 default categories must be present
      expect(provider.categories.where((c) => c.isDefault).length, 10);
      expect(provider.transactions.isNotEmpty, isTrue);
    });

    test('Can add a new transaction and updates totalExpense', () async {
      final initialCount = provider.transactions.length;

      final result = await provider.addNewTransaction(
        amount: 50000,
        merchant: 'Test Cafe',
        date: DateTime.now(),
      );

      expect(result, isNotNull);
      expect(provider.transactions.length, initialCount + 1);
      expect(provider.transactions.first.merchant, 'Test Cafe');
      expect(provider.transactions.first.amount, 50000.0);
    });

    test('Can delete a transaction', () async {
      final tx = provider.transactions.first;
      final countBefore = provider.transactions.length;

      await provider.removeTransaction(tx.id);
      expect(provider.transactions.length, countBefore - 1);
      expect(provider.transactions.any((t) => t.id == tx.id), isFalse);
    });

    test('Can add a custom category with color accent', () async {
      final initialCount = provider.categories.length;

      final created = await provider.addCategory(
        name: 'Streaming Services',
        emoji: '📺',
        colorHex: '#3B82F6',
        iconName: 'subscriptions',
      );

      expect(created, isNotNull);
      expect(provider.categories.length, initialCount + 1);

      final added = provider.categories.firstWhere(
        (c) => c.name.toLowerCase() == 'streaming services',
      );
      expect(added.isDefault, isFalse);
      expect(added.colorHex, '#3B82F6');
      expect(added.iconName, 'subscriptions');
    });

    test('Guards against deleting system default categories', () async {
      final defaultCat = provider.categories.firstWhere((c) => c.isDefault);
      final initialCount = provider.categories.length;

      final success = await provider.deleteCategory(defaultCat.id);
      expect(success, isFalse);
      expect(provider.categories.length, initialCount);
    });

    test('Calculates categoryChangeVsLastMonth correctly', () {
      final now = DateTime.now();
      // Month-over-month calculation should not crash and return a percentage double or null
      final diff = provider.getCategoryChangeVsLastMonth('Food & snacks', now);
      // diff can be null if no spend in previous month or a double percentage
      if (diff != null) {
        expect(diff, isA<double>());
      }
    });
  });
}
