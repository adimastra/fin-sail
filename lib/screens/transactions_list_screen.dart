import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/top_categories_donut_chart.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  // 2-tab menu: 0: All Expense Transaction, 1: Chart by categories
  int _selectedSubTab = 1;
  int _chartAnimNonce = 0;
  String _searchQuery = '';
  bool _onlyWithReceipts = false;
  String? _selectedCategoryFilter;

  // Month for the Top 5 Donut Chart
  late DateTime _chartMonth;

  // Date range filter: selects start & end date (capped at today)
  DateTimeRange? _selectedDateRangeFilter;

  String _formatDateRangeLabel(DateTimeRange? range) {
    if (range == null) return 'Filter Date Range';
    final start = range.start;
    final end = range.end;
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return DateFormat('d MMM yyyy').format(start);
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
    }
    return '${DateFormat('d MMM yyyy').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
  }

  @override
  void initState() {
    super.initState();
    _chartMonth = DateTime.now();
  }

  void _showDetailSheet(
    BuildContext context,
    TransactionModel tx,
    ExpenseProvider provider,
  ) {
    TransactionDetailSheet.show(
      context,
      tx,
      onDelete: () => provider.removeTransaction(tx.id),
    );
  }

  Widget _buildTopTabToggle(bool isDark) {
    // Active background: white in dark mode, black in light mode
    final activeBgColor = isDark ? Colors.white : AppTheme.pureBlack;
    // Active icon: black in dark mode, white in light mode
    final activeIconColor = isDark ? AppTheme.pureBlack : Colors.white;
    // Inactive icon: muted grey
    final inactiveIconColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF1F1F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E33) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab 0: All Expense Transaction (Bar Chart Icon)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_selectedSubTab != 0) {
                setState(() => _selectedSubTab = 0);
              }
            },
            child: Tooltip(
              message: 'All Expense Transaction',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _selectedSubTab == 0
                      ? activeBgColor
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 19,
                  color: _selectedSubTab == 0
                      ? activeIconColor
                      : inactiveIconColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          // Tab 1: Chart by categories (Pie/Donut Chart Icon)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedSubTab = 1;
                _chartAnimNonce++;
              });
            },
            child: Tooltip(
              message: 'Chart by categories',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _selectedSubTab == 1
                      ? activeBgColor
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  size: 19,
                  color: _selectedSubTab == 1
                      ? activeIconColor
                      : inactiveIconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allExpenses = provider.transactions
        .where((t) => t.isExpense)
        .toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final filtered = allExpenses.where((tx) {
      if (_onlyWithReceipts && !tx.hasReceipt) return false;
      if (_selectedCategoryFilter != null &&
          tx.categoryId != _selectedCategoryFilter) {
        return false;
      }

      // Filter by selected date range (inclusive, <= today)
      if (_selectedDateRangeFilter != null) {
        final d = DateTime(
          tx.transactionDate.year,
          tx.transactionDate.month,
          tx.transactionDate.day,
        );
        final start = DateTime(
          _selectedDateRangeFilter!.start.year,
          _selectedDateRangeFilter!.start.month,
          _selectedDateRangeFilter!.start.day,
        );
        final end = DateTime(
          _selectedDateRangeFilter!.end.year,
          _selectedDateRangeFilter!.end.month,
          _selectedDateRangeFilter!.end.day,
        );
        if (d.isBefore(start) || d.isAfter(end)) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final merchantMatch =
            tx.merchant?.toLowerCase().contains(query) ?? false;
        final categoryMatch =
            tx.category?.name.toLowerCase().contains(query) ?? false;
        return merchantMatch || categoryMatch;
      }
      return true;
    }).toList();

    // Group filtered transactions by date
    final Map<DateTime, List<TransactionModel>> groupedByDate = {};
    for (var tx in filtered) {
      final key = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      groupedByDate.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.pureBlack,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 22,
                color: isDark ? Colors.white : AppTheme.pureBlack,
              ),
              tooltip: 'Reload & Test Skeleton',
              onPressed: () => context.read<ExpenseProvider>().refreshData(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? AnalyticsSkeleton(selectedTab: _selectedSubTab)
          : (_selectedSubTab == 0
              ? SingleChildScrollView(
                  key: const ValueKey('AllExpenseTransactionTab'),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Date filter on left, Tab Menu Toggle on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date Range Filter Button (selects date range <= today)
                          InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                initialDateRange: _selectedDateRangeFilter,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  23,
                                  59,
                                  59,
                                ),
                                builder: (ctx, child) {
                                  return Theme(
                                    data: isDark
                                        ? ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: Colors.white,
                                              onPrimary: AppTheme.pureBlack,
                                              surface: Color(0xFF18181B),
                                              onSurface: Colors.white,
                                            ),
                                          )
                                        : ThemeData.light().copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
                                                  primary: AppTheme.pureBlack,
                                                  onPrimary: Colors.white,
                                                  surface: Colors.white,
                                                  onSurface: AppTheme.pureBlack,
                                                ),
                                          ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(
                                  () => _selectedDateRangeFilter = picked,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedDateRangeFilter != null
                                    ? (isDark
                                          ? Colors.white
                                          : AppTheme.pureBlack)
                                    : (isDark
                                          ? const Color(0xFF18181B)
                                          : const Color(0xFFF1F1F4)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF27272A)
                                      : AppTheme.grayBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.date_range_rounded,
                                    size: 15,
                                    color: _selectedDateRangeFilter != null
                                        ? (isDark
                                              ? AppTheme.pureBlack
                                              : Colors.white)
                                        : AppTheme.grayTextMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDateRangeLabel(
                                      _selectedDateRangeFilter,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedDateRangeFilter != null
                                          ? (isDark
                                                ? AppTheme.pureBlack
                                                : Colors.white)
                                          : (isDark
                                                ? Colors.white70
                                                : AppTheme.pureBlack),
                                    ),
                                  ),
                                  if (_selectedDateRangeFilter != null) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedDateRangeFilter = null,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: _selectedDateRangeFilter != null
                                            ? (isDark
                                                  ? AppTheme.pureBlack
                                                  : Colors.white)
                                            : AppTheme.grayTextMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Tab Menu Toggle at the top right
                          _buildTopTabToggle(isDark),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Full Width Search Input Field
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF18181B)
                              : AppTheme.grayKeypad,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: AppTheme.grayTextMuted,
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 26,
                              minHeight: 0,
                            ),
                            hintText: 'search expense or merchant...',
                            hintStyle: TextStyle(
                              color: AppTheme.grayTextMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category & Receipt Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'all',
                              isSelected:
                                  !_onlyWithReceipts &&
                                  _selectedCategoryFilter == null,
                              onTap: () {
                                setState(() {
                                  _onlyWithReceipts = false;
                                  _selectedCategoryFilter = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'Receipts',
                              icon: Icons.receipt_long,
                              isSelected: _onlyWithReceipts,
                              onTap: () => setState(
                                () => _onlyWithReceipts = !_onlyWithReceipts,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ...provider.categories.map((cat) {
                              final isSel = _selectedCategoryFilter == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(
                                  icon: cat.icon,
                                  iconColor: cat.color,
                                  label: cat.name,
                                  isSelected: isSel,
                                  onTap: () {
                                    setState(
                                      () => _selectedCategoryFilter = isSel
                                          ? null
                                          : cat.id,
                                    );
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Header with count and total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} Transactions',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '-${CurrencyFormat.format(filtered.fold(0.0, (sum, t) => sum + t.amount))}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Transactions List Grouped and Separated by Date
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text(
                              'No expenses matched your filter.',
                              style: TextStyle(
                                color: AppTheme.grayTextMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ...sortedDates.map((dateKey) {
                          final groupTxs = groupedByDate[dateKey]!;
                          final groupTotal = groupTxs.fold(
                            0.0,
                            (sum, t) => sum + t.amount,
                          );
                          String title;
                          if (dateKey == today) {
                            title = 'today';
                          } else if (dateKey == yesterday) {
                            title = 'yesterday';
                          } else {
                            title = DateFormat('d MMMM yyyy')
                                .format(dateKey)
                                .toLowerCase();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateSectionHeader(
                                title: title,
                                totalAmount: groupTotal,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              ...groupTxs.map(
                                (tx) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TransactionTile(
                                    transaction: tx,
                                    onTap: () =>
                                        _showDetailSheet(context, tx, provider),
                                    onDelete: () =>
                                        provider.removeTransaction(tx.id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),
                    ],
                  ),
                )
                // Tab 1: Chart by categories (Matching user's reference design)
              : SingleChildScrollView(
                  key: ValueKey('ChartByCategoriesTab-$_selectedSubTab-$_chartAnimNonce-${_chartMonth.month}-${_chartMonth.year}'),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: TopCategoriesDonutChart(
                    key: ValueKey('TopCategoriesDonutChart-$_selectedSubTab-$_chartAnimNonce-${_chartMonth.month}-${_chartMonth.year}'),
                    allTransactions: allExpenses,
                    selectedMonth: _chartMonth,
                    onMonthChanged: (m) => setState(() {
                      _chartMonth = m;
                      _chartAnimNonce++;
                    }),
                    tabToggle: _buildTopTabToggle(isDark),
                  ),
                )),
    );
  }

  Widget _buildDateSectionHeader({
    required String title,
    required double totalAmount,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.grayTextMuted,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 0.8,
            color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
          ),
        ),
        Text(
          '-${CurrencyFormat.format(totalAmount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.grayTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (iconColor != null
                    ? iconColor.withValues(alpha: isDark ? 0.28 : 0.16)
                    : (isDark ? Colors.white : AppTheme.pureBlack))
              : (isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected && iconColor != null
                ? iconColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? (iconColor ??
                          (isDark ? AppTheme.pureBlack : Colors.white))
                    : (iconColor ?? AppTheme.grayTextMuted),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (iconColor ??
                          (isDark ? AppTheme.pureBlack : Colors.white))
                    : (isDark ? Colors.white70 : AppTheme.pureBlack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
