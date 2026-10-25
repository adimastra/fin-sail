class ReceiptItem {
  final String name;
  final double price;

  ReceiptItem({required this.name, required this.price});

  ReceiptItem copyWith({String? name, double? price}) {
    return ReceiptItem(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name']?.toString() ?? 'Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };
}

class ReceiptData {
  final String merchant;
  final double amount;
  final String currency;
  final DateTime date;
  final String suggestedCategory;
  final String paymentMethod;
  final double? taxAmount;
  final List<ReceiptItem> items;
  final double confidenceScore;
  final String? rawSummary;
  final String? localImagePath;
  final String? receiptUrl;

  ReceiptData({
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.date,
    required this.suggestedCategory,
    this.paymentMethod = 'card',
    this.taxAmount,
    this.items = const [],
    this.confidenceScore = 0.95,
    this.rawSummary,
    this.localImagePath,
    this.receiptUrl,
  });

  ReceiptData copyWith({
    String? merchant,
    double? amount,
    String? currency,
    DateTime? date,
    String? suggestedCategory,
    String? paymentMethod,
    double? taxAmount,
    List<ReceiptItem>? items,
    double? confidenceScore,
    String? rawSummary,
    String? localImagePath,
    String? receiptUrl,
  }) {
    return ReceiptData(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxAmount: taxAmount ?? this.taxAmount,
      items: items ?? this.items,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      rawSummary: rawSummary ?? this.rawSummary,
      localImagePath: localImagePath ?? this.localImagePath,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }

  factory ReceiptData.fromJson(Map<String, dynamic> json, {String? localImagePath, String? receiptUrl}) {
    DateTime parsedDate;
    try {
      parsedDate = json['date'] != null ? DateTime.parse(json['date'].toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawItems = json['items'];
    List<ReceiptItem> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => ReceiptItem.fromJson(i is Map<String, dynamic> ? i : {}))
          .toList();
    }

    return ReceiptData(
      merchant: json['merchant']?.toString() ?? 'Unknown Merchant',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      date: parsedDate,
      suggestedCategory: json['suggested_category']?.toString() ?? 'Groceries',
      paymentMethod: json['payment_method']?.toString() ?? 'card',
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      items: parsedItems,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.9,
      rawSummary: json['raw_summary']?.toString(),
      localImagePath: localImagePath,
      receiptUrl: receiptUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'merchant': merchant,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'suggested_category': suggestedCategory,
    'payment_method': paymentMethod,
    'tax_amount': taxAmount,
    'items': items.map((i) => i.toJson()).toList(),
    'confidence_score': confidenceScore,
    'raw_summary': rawSummary,
    'receipt_url': receiptUrl,
  };
}
