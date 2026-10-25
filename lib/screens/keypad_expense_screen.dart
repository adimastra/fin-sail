import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_format.dart';

class KeypadExpenseScreen extends StatefulWidget {
  const KeypadExpenseScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const KeypadExpenseScreen(),
    );
  }

  @override
  State<KeypadExpenseScreen> createState() => _KeypadExpenseScreenState();
}

class _KeypadExpenseScreenState extends State<KeypadExpenseScreen> {
  String _amountDigits = '20000'; // Default 20,000 IDR
  late DateTime _selectedDate;
  late TextEditingController _storeNameController;
  late FocusNode _storeNameFocusNode;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _storeNameController = TextEditingController(text: 'burger king');
    _storeNameFocusNode = FocusNode();
    _storeNameFocusNode.addListener(() {
      setState(() {}); // Rebuild to toggle numpad visibility when keyboard appears
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategoryId == null) {
      final categories = context.read<ExpenseProvider>().categories;
      if (categories.isNotEmpty) {
        _selectedCategoryId = categories.first.id;
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeNameFocusNode.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '000') {
        if (_amountDigits != '0' && _amountDigits.length <= 7) {
          _amountDigits = '${_amountDigits}000';
        }
      } else if (key == '.') {
        // IDR typically doesn't use decimals, but ignore or append if needed
      } else {
        if (_amountDigits == '0' || _amountDigits == '20000') {
          _amountDigits = key;
        } else if (_amountDigits.length < 10) {
          _amountDigits = '$_amountDigits$key';
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountDigits.length > 1) {
        _amountDigits = _amountDigits.substring(0, _amountDigits.length - 1);
      } else {
        _amountDigits = '0';
      }
    });
  }

  Future<void> _submitExpense() async {
    final amount = double.tryParse(_amountDigits);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final merchant = _storeNameController.text.trim().isEmpty ? 'Expense' : _storeNameController.text.trim();

    await provider.addNewTransaction(
      amount: amount,
      merchant: merchant,
      categoryId: _selectedCategoryId,
      date: _selectedDate,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showCategoryPicker() {
    final categories = context.read<ExpenseProvider>().categories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'select category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: categories.map((cat) {
                  final isSel = cat.id == _selectedCategoryId;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = cat.id;
                        if (_storeNameController.text.trim().isEmpty || _storeNameController.text == 'burger king') {
                          _storeNameController.text = cat.name;
                        }
                      });
                      Navigator.of(ctx).pop();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? cat.color.withValues(alpha: isDark ? 0.28 : 0.16)
                            : (isDark ? const Color(0xFF27272A) : AppTheme.grayKeypad),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel
                              ? cat.color.withValues(alpha: 0.6)
                              : Colors.transparent,
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
                              color: isSel
                                  ? cat.color
                                  : (isDark ? Colors.white : AppTheme.pureBlack),
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // 5 days ending at today
    final days = List.generate(5, (i) => now.subtract(Duration(days: 4 - i)));
    final numpadVisible = !_storeNameFocusNode.hasFocus;
    final parsedAmount = double.tryParse(_amountDigits) ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C0E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Top bar: drag handle in center, close icon button at right top alone
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
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
          ),
          const SizedBox(height: 8),

          // Header with centered expense badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : AppTheme.grayKeypad,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'expense',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),

          // Horizontal Date Selector (5 days)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((d) {
                final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month;
                final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
                final weekdayName = weekdays[d.weekday - 1];

                return InkWell(
                  onTap: () => setState(() => _selectedDate = d),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : AppTheme.pureBlack)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? (isDark ? AppTheme.pureBlack : Colors.white)
                                : (isDark ? Colors.white : AppTheme.pureBlack),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weekdayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppTheme.pureBlack : Colors.white)
                                : AppTheme.grayTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (numpadVisible) const Spacer(),

          // Centered Section: Currency, Category, and Underline Merchant Field
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big Amount Typography + Delete Digit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onHorizontalDragEnd: (_) => _onBackspace(),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormat.format(parsedAmount),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Delete button next to number
                    InkWell(
                      onTap: _onBackspace,
                      onLongPress: () {
                        setState(() => _amountDigits = '0');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E22)
                              : AppTheme.grayKeypad,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : AppTheme.grayBorder,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 19,
                            color: _amountDigits != '0' && _amountDigits.isNotEmpty
                                ? (isDark ? Colors.white70 : AppTheme.pureBlack)
                                : AppTheme.grayTextMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input Row: Category Capsule + Underline Store Name Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. Category Pill Selector with Color Accent
                    Builder(
                      builder: (context) {
                        final cats = context.watch<ExpenseProvider>().categories;
                        final cat = cats.firstWhere(
                          (c) => c.id == _selectedCategoryId,
                          orElse: () => cats.isNotEmpty
                              ? cats.first
                              : CategoryModel(id: 'other', name: 'other', emoji: '📦'),
                        );
                        return InkWell(
                          onTap: _showCategoryPicker,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: isDark ? 0.20 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cat.color.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 16,
                                  color: cat.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: cat.color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: cat.color,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),

                    // 2. Store Name Field Input (Underline style, no rounded box)
                    Expanded(
                      child: TextField(
                        controller: _storeNameController,
                        focusNode: _storeNameFocusNode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.pureBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: 'store / merchant name...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.grayTextMuted,
                            fontWeight: FontWeight.normal,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
                              width: 1,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (numpadVisible) const Spacer(),

          // Circular Numeric Keypad (Hidden when software keyboard is shown)
          if (numpadVisible) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  _buildKeypadRow(['000', '0', '✓']),
                ],
              ),
            ),
          ] else ...[
            // When soft keyboard is open, show quick save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : AppTheme.pureBlack,
                    foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _submitExpense,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSubmit = key == '✓';

    return SizedBox(
      width: 70,
      height: 70,
      child: Material(
        color: isSubmit
            ? (isDark ? Colors.white : AppTheme.pureBlack)
            : (isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            if (isSubmit) {
              _submitExpense();
            } else {
              _onKeyPress(key);
            }
          },
          child: Center(
            child: isSubmit
                ? Icon(
                    Icons.check,
                    color: isDark ? AppTheme.pureBlack : Colors.white,
                    size: 26,
                  )
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: key == '000' ? 18 : 24,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.pureBlack,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
