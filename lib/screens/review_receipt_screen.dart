import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/receipt_data.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_format.dart';
import '../utils/thousands_separator_formatter.dart';

class _ReceiptItemController {
  final TextEditingController nameController;
  final TextEditingController priceController;

  _ReceiptItemController({required String name, required num price})
      : nameController = TextEditingController(text: name),
        priceController = TextEditingController(
          text: ThousandsSeparatorInputFormatter.format(price),
        );

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class ReviewReceiptScreen extends StatefulWidget {
  final ReceiptData receiptData;
  final Uint8List? imageBytes;

  const ReviewReceiptScreen({
    super.key,
    required this.receiptData,
    this.imageBytes,
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  late List<_ReceiptItemController> _itemControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.format(widget.receiptData.amount),
    );
    _merchantController = TextEditingController(text: widget.receiptData.merchant);
    _selectedDate = widget.receiptData.date;
    _itemControllers = widget.receiptData.items
        .map((i) => _ReceiptItemController(name: i.name, price: i.price))
        .toList();
    if (_itemControllers.isEmpty) {
      _itemControllers.add(
        _ReceiptItemController(
          name: widget.receiptData.merchant.isNotEmpty ? widget.receiptData.merchant : 'Item',
          price: widget.receiptData.amount,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategoryId == null) {
      final categories = context.read<ExpenseProvider>().categories;
      final matched = categories.firstWhere(
        (c) => c.name.toLowerCase().contains(widget.receiptData.suggestedCategory.toLowerCase()),
        orElse: () => categories.firstWhere((c) => c.name == 'Groceries', orElse: () => categories.first),
      );
      _selectedCategoryId = matched.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _itemControllers.add(_ReceiptItemController(name: '', price: 0));
    });
  }

  void _removeItem(int index) {
    if (_itemControllers.length <= 1) {
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
      final c = _itemControllers.removeAt(index);
      c.dispose();
    });
  }

  Future<void> _saveExpense() async {
    final amount = ThousandsSeparatorInputFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ExpenseProvider>();

    final itemsToSave = _itemControllers.isNotEmpty
        ? _itemControllers
        : [
            _ReceiptItemController(
              name: _merchantController.text.trim().isEmpty ? 'Item' : _merchantController.text.trim(),
              price: amount,
            ),
          ];

    final updatedItems = itemsToSave.map((c) {
      final name = c.nameController.text.trim().isEmpty ? 'Item' : c.nameController.text.trim();
      final price = ThousandsSeparatorInputFormatter.parse(c.priceController.text);
      return ReceiptItem(name: name, price: price);
    }).toList();

    final updatedReceipt = widget.receiptData.copyWith(
      amount: amount,
      merchant: _merchantController.text.trim(),
      date: _selectedDate,
      items: updatedItems,
    );

    await provider.addNewTransaction(
      amount: amount,
      type: 'expense',
      categoryId: _selectedCategoryId,
      merchant: _merchantController.text.trim(),
      date: _selectedDate,
      receiptUrl: widget.receiptData.receiptUrl,
      extractedData: updatedReceipt,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.income,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Expense of ${CurrencyFormat.format(amount)} saved successfully!'),
            ],
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = context.watch<ExpenseProvider>().categories;
    final dateFormatter = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Review Scanned Expense',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.pureBlack,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.pureBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Confidence badge
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : AppTheme.grayKeypad,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white24 : AppTheme.grayBorder,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: isDark ? Colors.white : AppTheme.pureBlack,
                ),
                const SizedBox(width: 5),
                Text(
                  '${(widget.receiptData.confidenceScore * 100).toInt()}% Match',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.pureBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Extracted Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grayTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Rp ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.pureBlack,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 40, maxWidth: 280),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            cursorColor: isDark ? Colors.white : AppTheme.pureBlack,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              ThousandsSeparatorInputFormatter(),
                            ],
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : AppTheme.grayTextMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : AppTheme.grayKeypad,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Expense',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.pureBlack,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Merchant / Store Name
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
              style: TextStyle(color: isDark ? Colors.white : AppTheme.pureBlack),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.storefront_outlined,
                  size: 20,
                  color: isDark ? Colors.white70 : AppTheme.pureBlack,
                ),
                hintText: 'Store name',
                hintStyle: const TextStyle(color: AppTheme.grayTextMuted),
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
              ),
            ),
            const SizedBox(height: 18),

            // Category Selector Chips
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
            const SizedBox(height: 18),

            // Date Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detected Items (Editable name and amount)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detected Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.pureBlack,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${_itemControllers.length} items',
                      style: const TextStyle(fontSize: 12, color: AppTheme.grayTextMuted),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _addItem,
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
              child: _itemControllers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add an item'),
                          onPressed: _addItem,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _itemControllers.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
                      ),
                      itemBuilder: (context, index) {
                        final itemC = _itemControllers[index];
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
                              if (_itemControllers.length > 1) ...[
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
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0C0E) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppTheme.pureBlack,
              foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: isDark ? AppTheme.pureBlack : Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 22),
            label: Text(
              _isSaving ? 'Saving Expense...' : 'Confirm & Save Expense',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSaving ? null : _saveExpense,
          ),
        ),
      ),
    );
  }
}
