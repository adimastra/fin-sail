import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/receipt_data.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_format.dart';
import '../utils/thousands_separator_formatter.dart';
import 'skeleton_loader.dart';

class _ExtractedItemController {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _ExtractedItemController({required String name, required num price})
      : nameController = TextEditingController(text: name),
        priceController = TextEditingController(
          text: ThousandsSeparatorInputFormatter.format(price),
        );

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class TransactionDetailSheet extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;
  final bool initialEdit;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.onDelete,
    this.initialEdit = false,
  });

  static Future<void> show(
    BuildContext context,
    TransactionModel tx, {
    VoidCallback? onDelete,
    bool initialEdit = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionDetailSheet(
        transaction: tx,
        onDelete: onDelete,
        initialEdit: initialEdit,
      ),
    );
  }

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  late TransactionModel _currentTx;
  late bool _isEditing;

  // Edit form controllers
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  String? _selectedCategoryId;
  late DateTime _selectedDate;
  final List<_ExtractedItemController> _extractedItemControllers = [];
  bool _isSaving = false;
  bool _isReloading = false;

  Future<void> _handleReload() async {
    setState(() => _isReloading = true);
    final provider = context.read<ExpenseProvider>();
    await provider.refreshData(delay: const Duration(milliseconds: 2000));
    if (mounted) {
      final matched = provider.transactions.where((t) => t.id == _currentTx.id);
      setState(() {
        if (matched.isNotEmpty) {
          _currentTx = matched.first;
        }
        _isReloading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentTx = widget.transaction;
    _isEditing = widget.initialEdit;
    _initEditFields();
  }

  void _initEditFields() {
    final amt = _currentTx.amount;
    _amountController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.format(amt),
    );
    _merchantController = TextEditingController(text: _currentTx.merchant ?? '');
    _selectedCategoryId = _currentTx.categoryId ?? _currentTx.category?.id;
    _selectedDate = _currentTx.transactionDate;

    for (final c in _extractedItemControllers) {
      c.dispose();
    }
    _extractedItemControllers.clear();
    if (_currentTx.extractedData != null) {
      for (final item in _currentTx.extractedData!.items) {
        _extractedItemControllers.add(
          _ExtractedItemController(name: item.name, price: item.price),
        );
      }
      if (_extractedItemControllers.isEmpty) {
        _extractedItemControllers.add(
          _ExtractedItemController(
            name: _currentTx.merchant ?? 'Item',
            price: _currentTx.amount,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    for (final c in _extractedItemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addExtractedItem() {
    setState(() {
      _extractedItemControllers.add(
        _ExtractedItemController(name: '', price: 0),
      );
    });
  }

  void _removeExtractedItem(int index) {
    if (_extractedItemControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('At least 1 item is required.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      final c = _extractedItemControllers.removeAt(index);
      c.dispose();
    });
  }

  Future<void> _saveChanges() async {
    final amount = ThousandsSeparatorInputFormatter.parse(_amountController.text.trim());
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final merchant = _merchantController.text.trim().isEmpty
        ? 'Expense'
        : _merchantController.text.trim();

    setState(() => _isSaving = true);

    final provider = context.read<ExpenseProvider>();
    final categories = provider.categories;

    final selectedCat = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _currentTx.category ?? categories.first,
    );

    ReceiptData? updatedExtracted;
    if (_currentTx.extractedData != null) {
      final itemsToSave = _extractedItemControllers.isNotEmpty
          ? _extractedItemControllers
          : [
              _ExtractedItemController(
                name: merchant.isNotEmpty ? merchant : 'Item',
                price: amount,
              ),
            ];

      final updatedItems = itemsToSave.map((c) {
        final name = c.nameController.text.trim().isEmpty ? 'Item' : c.nameController.text.trim();
        final price = ThousandsSeparatorInputFormatter.parse(c.priceController.text);
        return ReceiptItem(name: name, price: price);
      }).toList();

      updatedExtracted = _currentTx.extractedData!.copyWith(
        items: updatedItems,
        amount: amount,
        merchant: merchant,
        date: _selectedDate,
      );
    }

    final updatedTx = _currentTx.copyWith(
      amount: amount,
      merchant: merchant,
      categoryId: selectedCat.id,
      category: selectedCat,
      transactionDate: _selectedDate,
      extractedData: updatedExtracted,
    );

    final saved = await provider.updateTransaction(updatedTx);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (saved != null) {
          _currentTx = saved;
          _isEditing = false;
        }
      });

      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isDark ? const Color(0xFF27272A) : AppTheme.pureBlack,
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Expense updated successfully',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatter = DateFormat('EEE, d MMM yyyy • HH:mm');
    final extracted = _currentTx.extractedData;
    final items = extracted?.items ?? [];
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;
    final isLoading = _isReloading || provider.isLoading;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C0E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar: Reload on left, drag handle in center, close icon button at right top
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: isDark ? Colors.white70 : AppTheme.pureBlack,
                  ),
                  tooltip: 'Reload & Test Skeleton',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  onPressed: _handleReload,
                ),
              ),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Body: Skeleton Loader or Edit Module or Detail View
          Flexible(
            child: SingleChildScrollView(
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: DetailExpenseSkeleton(),
                    )
                  : (_isEditing
                      ? _buildEditModule(isDark, categories)
                      : _buildDetailView(isDark, dateFormatter, items)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(
    bool isDark,
    DateFormat dateFormatter,
    List<ReceiptItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Merchant & Subtitle on left; Amount on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (_currentTx.category?.color ?? Colors.grey)
                              .withValues(alpha: isDark ? 0.20 : 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            _currentTx.category?.icon ?? Icons.receipt_long_rounded,
                            size: 16,
                            color: _currentTx.category?.color ??
                                (isDark ? Colors.white : AppTheme.pureBlack),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentTx.merchant ?? 'Expense Detail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormatter.format(_currentTx.transactionDate),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormat.format(_currentTx.amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : AppTheme.pureBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
        ),
        const SizedBox(height: 14),

        // Receipt Image Preview (if attached)
        if (_currentTx.receiptUrl != null && _currentTx.receiptUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _currentTx.receiptUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Receipt attached', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Category Pill with Color Accent
        if (_currentTx.category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _currentTx.category!.color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _currentTx.category!.color.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentTx.category!.icon,
                  size: 12,
                  color: _currentTx.category!.color,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentTx.category!.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _currentTx.category!.color,
                  ),
                ),
              ],
            ),
          ),

        // Extracted Receipt Items Section
        if (items.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extracted Items (${items.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : AppTheme.pureBlack,
                ),
              ),
              const Text(
                'AI Parsed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppTheme.pureBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '-${CurrencyFormat.format(item.price)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.pureBlack,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons: Edit Expense & Delete Expense
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppTheme.pureBlack,
              foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(
              'Edit Expense',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              setState(() {
                _initEditFields();
                _isEditing = true;
              });
            },
          ),
        ),

        if (widget.onDelete != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete!();
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEditModule(bool isDark, List<dynamic> categories) {
    final dateFormatter = DateFormat('EEE, d MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Edit Module Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : AppTheme.grayKeypad,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: isDark ? Colors.white : AppTheme.pureBlack,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Edit Expense',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : AppTheme.pureBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
        ),
        const SizedBox(height: 16),

        // 1. Amount Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grayTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Rp ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.pureBlack,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      cursorColor: isDark ? Colors.white : AppTheme.pureBlack,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppTheme.pureBlack,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : AppTheme.grayTextMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Merchant / Store Name
        Text(
          'Merchant / Store',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _merchantController,
          cursorColor: isDark ? Colors.white : AppTheme.pureBlack,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.pureBlack,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.storefront_outlined,
              size: 20,
              color: isDark ? Colors.white70 : AppTheme.pureBlack,
            ),
            hintText: 'Store / merchant name',
            hintStyle: const TextStyle(color: AppTheme.grayTextMuted, fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white : AppTheme.pureBlack,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Category Selector
        Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat.id == _selectedCategoryId;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() => _selectedCategoryId = cat.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: isDark ? 0.28 : 0.16)
                        : (isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.6)
                          : (isDark ? const Color(0xFF27272A) : AppTheme.grayBorder),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 14,
                        color: cat.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected
                              ? cat.color
                              : (isDark ? Colors.white : AppTheme.pureBlack),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 4. Date Row
        Text(
          'Date',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : AppTheme.pureBlack,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  _selectedDate.hour,
                  _selectedDate.minute,
                );
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: isDark ? Colors.white70 : AppTheme.pureBlack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFormatter.format(_selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.pureBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                ),
              ],
            ),
          ),
        ),

        // 5. Extracted Items (If the transaction has Extracted Items)
        if (_extractedItemControllers.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extracted Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : AppTheme.pureBlack,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_extractedItemControllers.length} items',
                    style: const TextStyle(fontSize: 12, color: AppTheme.grayTextMuted),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _addExtractedItem,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 14,
                            color: isDark ? Colors.white70 : AppTheme.pureBlack,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppTheme.pureBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _extractedItemControllers.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
              ),
              itemBuilder: (context, index) {
                final itemC = _extractedItemControllers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Item Name TextField
                      Expanded(
                        child: TextField(
                          controller: itemC.nameController,
                          cursorColor: isDark ? Colors.white : AppTheme.pureBlack,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                            border: InputBorder.none,
                            hintText: 'Item name',
                            hintStyle: TextStyle(
                              color: AppTheme.grayTextMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Item Amount: "Rp [amount]"
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppTheme.pureBlack,
                        ),
                      ),
                      SizedBox(
                        width: 85,
                        child: TextField(
                          controller: itemC.priceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          cursorColor: isDark ? Colors.white : AppTheme.pureBlack,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsSeparatorInputFormatter(),
                          ],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: AppTheme.grayTextMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // Remove item button
                      if (_extractedItemControllers.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                          tooltip: 'Remove item',
                          onPressed: () => _removeExtractedItem(index),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),

        // 6. Save Changes Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppTheme.pureBlack,
              foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: isDark ? AppTheme.pureBlack : Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Changes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
