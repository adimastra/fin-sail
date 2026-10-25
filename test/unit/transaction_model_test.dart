import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/models/category_model.dart';
import 'package:fin_logs/models/receipt_data.dart';
import 'package:fin_logs/models/transaction_model.dart';

void main() {
  group('TransactionModel & ReceiptData Unit Tests', () {
    test('TransactionModel flags isExpense and hasReceipt correctly', () {
      final txWithReceipt = TransactionModel(
        id: 'tx-1',
        userId: 'u1',
        amount: 50000,
        transactionDate: DateTime(2026, 10, 25),
        receiptUrl: 'https://example.com/receipt.jpg',
        type: 'expense',
      );
      expect(txWithReceipt.isExpense, isTrue);
      expect(txWithReceipt.hasReceipt, isTrue);

      final txWithoutReceipt = TransactionModel(
        id: 'tx-2',
        userId: 'u1',
        amount: 25000,
        transactionDate: DateTime(2026, 10, 25),
        receiptUrl: null,
        type: 'expense',
      );
      expect(txWithoutReceipt.isExpense, isTrue);
      expect(txWithoutReceipt.hasReceipt, isFalse);
    });

    test('Serialization to and from JSON preserves all transaction attributes', () {
      final cat = CategoryModel(
        id: 'cat-coffee',
        name: 'Coffee',
        emoji: '☕',
      );

      final original = TransactionModel(
        id: 'tx-123',
        userId: 'user-456',
        categoryId: 'cat-coffee',
        category: cat,
        amount: 38000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Kopi Kenangan',
        transactionDate: DateTime(2026, 10, 25, 10, 30),
        receiptUrl: 'https://storage.supabase.co/receipts/test.jpg',
      );

      final json = original.toJson();
      expect(json['id'], 'tx-123');
      expect(json['amount'], 38000.0);
      expect(json['merchant'], 'Kopi Kenangan');
      expect(json['type'], 'expense');

      final reconstructed = TransactionModel.fromJson(json, category: cat);
      expect(reconstructed.id, original.id);
      expect(reconstructed.amount, original.amount);
      expect(reconstructed.merchant, original.merchant);
      expect(reconstructed.category?.name, 'Coffee');
      expect(reconstructed.hasReceipt, isTrue);
    });

    test('ReceiptData and ReceiptItem parsing works cleanly', () {
      final receiptJson = {
        'merchant': 'Super Indo Supermarket',
        'amount': 148000.0,
        'date': '2026-10-24T18:00:00Z',
        'suggested_category': 'Groceries',
        'confidence_score': 0.95,
        'items': [
          {'name': 'Fresh Milk 1L', 'price': 28000.0},
          {'name': 'Whole Wheat Bread', 'price': 22000.0},
          {'name': 'Organic Eggs 10pk', 'price': 35000.0},
        ],
      };

      final receipt = ReceiptData.fromJson(
        receiptJson,
        receiptUrl: 'https://supabase.co/storage/Receipts/superindo.jpg',
      );

      expect(receipt.merchant, 'Super Indo Supermarket');
      expect(receipt.amount, 148000.0);
      expect(receipt.suggestedCategory, 'Groceries');
      expect(receipt.confidenceScore, 0.95);
      expect(receipt.items.length, 3);
      expect(receipt.items.first.name, 'Fresh Milk 1L');
      expect(receipt.items.first.price, 28000.0);
    });
  });
}
