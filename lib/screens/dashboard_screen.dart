import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/minimal_trend_chart.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _showDetailSheet(BuildContext context, TransactionModel tx, ExpenseProvider provider) {
    TransactionDetailSheet.show(
      context,
      tx,
      onDelete: () => provider.removeTransaction(tx.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalExpense = provider.totalExpense;

    final rawExpenses = provider.monthlyExpenses;
    final expenses = _searchQuery.isEmpty
        ? rawExpenses
        : rawExpenses.where((t) {
            final q = _searchQuery.toLowerCase();
            return (t.merchant?.toLowerCase().contains(q) ?? false) ||
                (t.category?.name.toLowerCase().contains(q) ?? false);
          }).toList();

    // Group expenses into Today, Yesterday, Earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayTxs = expenses.where((t) {
      final d = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      return d == today;
    }).toList();

    final yesterdayTxs = expenses.where((t) {
      final d = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      return d == yesterday;
    }).toList();

    final earlierTxs = expenses.where((t) {
      final d = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      return d.isBefore(yesterday);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.grayTextMuted, fontSize: 15),
                ),
              )
            : Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.pureBlack,
                  letterSpacing: -0.4,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 22,
              color: isDark ? Colors.white : AppTheme.pureBlack,
            ),
            tooltip: 'Reload & Test Skeleton',
            onPressed: () => provider.refreshData(),
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              size: 22,
              color: isDark ? Colors.white : AppTheme.pureBlack,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading
          ? const HomeOverviewSkeleton()
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // Big Headline Expense Amount (IDR Format: Rp 1.350.000)
            Text(
              CurrencyFormat.format(totalExpense),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: isDark ? Colors.white : AppTheme.pureBlack,
              ),
            ),
            const SizedBox(height: 16),

            // Smooth Minimal Bezier Curve Chart for 5 Months (Current month is in the last right & active)
            MinimalTrendChart(
              selectedMonth: provider.selectedMonth,
              onMonthSelected: (m) => provider.changeMonth(m),
              monthlyTotals: provider.getExpenseTrendForMonths(
                MinimalTrendChart.getDisplayMonths(),
              ),
            ),
            const SizedBox(height: 32),

            // 1. TODAY SECTION
            if (todayTxs.isNotEmpty) ...[
              _buildDateSectionHeader(
                title: 'today',
                totalAmount: todayTxs.fold(0.0, (s, t) => s + t.amount),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ...todayTxs.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TransactionTile(
                  transaction: tx,
                  onTap: () => _showDetailSheet(context, tx, provider),
                  onDelete: () => provider.removeTransaction(tx.id),
                ),
              )),
              const SizedBox(height: 16),
            ],

            // 2. YESTERDAY SECTION
            if (yesterdayTxs.isNotEmpty) ...[
              _buildDateSectionHeader(
                title: 'yesterday',
                totalAmount: yesterdayTxs.fold(0.0, (s, t) => s + t.amount),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ...yesterdayTxs.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TransactionTile(
                  transaction: tx,
                  onTap: () => _showDetailSheet(context, tx, provider),
                  onDelete: () => provider.removeTransaction(tx.id),
                ),
              )),
              const SizedBox(height: 16),
            ],

            // 3. EARLIER THIS MONTH SECTION
            if (earlierTxs.isNotEmpty) ...[
              _buildDateSectionHeader(
                title: 'earlier this month',
                totalAmount: earlierTxs.fold(0.0, (s, t) => s + t.amount),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ...earlierTxs.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TransactionTile(
                  transaction: tx,
                  onTap: () => _showDetailSheet(context, tx, provider),
                  onDelete: () => provider.removeTransaction(tx.id),
                ),
              )),
            ],

            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: const [
                    Text('☕', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 12),
                    Text(
                      'No expenses recorded yet',
                      style: TextStyle(color: AppTheme.grayTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSectionHeader({
    required String title,
    required double totalAmount,
    required bool isDark,
  }) {
    final bgColor = isDark ? const Color(0xFF0C0C0E) : Colors.white;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 0.8,
          color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.grayTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Container(
              color: bgColor,
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '-${CurrencyFormat.format(totalAmount)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.grayTextMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
