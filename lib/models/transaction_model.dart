import 'category_model.dart';
import 'receipt_data.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String? categoryId;
  final CategoryModel? category;
  final double amount;
  final String currency;
  final String type; // 'expense' or 'income'
  final String? merchant;
  final DateTime transactionDate;
  final String? receiptUrl;
  final ReceiptData? extractedData;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.category,
    required this.amount,
    this.currency = 'IDR',
    this.type = 'expense',
    this.merchant,
    required this.transactionDate,
    this.receiptUrl,
    this.extractedData,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpense => type == 'expense';
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  factory TransactionModel.fromJson(Map<String, dynamic> json, {CategoryModel? category}) {
    DateTime txDate;
    try {
      txDate = json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'].toString())
          : DateTime.now();
    } catch (_) {
      txDate = DateTime.now();
    }

    DateTime crDate;
    try {
      crDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      crDate = DateTime.now();
    }

    ReceiptData? receiptData;
    if (json['extracted_data'] != null && json['extracted_data'] is Map<String, dynamic>) {
      receiptData = ReceiptData.fromJson(
        json['extracted_data'],
        receiptUrl: json['receipt_url']?.toString(),
      );
    }

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      category: category,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'IDR',
      type: json['type']?.toString() ?? 'expense',
      merchant: json['merchant']?.toString(),
      transactionDate: txDate,
      receiptUrl: json['receipt_url']?.toString(),
      extractedData: receiptData,
      createdAt: crDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'amount': amount,
    'currency': currency,
    'type': type,
    'merchant': merchant,
    'transaction_date': transactionDate.toIso8601String(),
    'receipt_url': receiptUrl,
    'extracted_data': extractedData?.toJson(),
    'created_at': createdAt.toIso8601String(),
  };

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    CategoryModel? category,
    double? amount,
    String? currency,
    String? type,
    String? merchant,
    DateTime? transactionDate,
    String? receiptUrl,
    ReceiptData? extractedData,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      merchant: merchant ?? this.merchant,
      transactionDate: transactionDate ?? this.transactionDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      extractedData: extractedData ?? this.extractedData,
      createdAt: createdAt,
    );
  }
}
