import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/transaction_tile.dart';
import 'skeleton_loader.dart';
import 'package:provider/provider.dart';

class CategorySpendingItem {
  final String name;
  final String emoji;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;

  CategorySpendingItem({
    required this.name,
    required this.emoji,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class TopCategoriesDonutChart extends StatelessWidget {
  final List<TransactionModel> allTransactions;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Widget? tabToggle;

  const TopCategoriesDonutChart({
    super.key,
    required this.allTransactions,
    required this.selectedMonth,
    required this.onMonthChanged,
    this.tabToggle,
  });


  void _showMonthDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MonthDetailsSheetModal(selectedMonth: selectedMonth),
    );
  }

  void _showCategoryDetailsSheet(BuildContext context, String categoryName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MonthDetailsSheetModal(
        selectedMonth: selectedMonth,
        categoryFilter: categoryName,
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) {
    final now = DateTime.now();
    int currentSelectedYear = selectedMonth.year;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isCurrentYear = currentSelectedYear == now.year;
          final months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentSelectedYear > 2020
                          ? () => setModalState(() => currentSelectedYear--)
                          : null,
                    ),
                    Text(
                      '$currentSelectedYear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentSelectedYear < now.year
                          ? () => setModalState(() => currentSelectedYear++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (ctx, index) {
                    final monthNum = index + 1;
                    final isFuture = isCurrentYear && monthNum > now.month;
                    final isSelected =
                        currentSelectedYear == selectedMonth.year &&
                        monthNum == selectedMonth.month;

                    return InkWell(
                      onTap: isFuture
                          ? null
                          : () {
                              onMonthChanged(
                                DateTime(currentSelectedYear, monthNum),
                              );
                              Navigator.of(ctx).pop();
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white : AppTheme.pureBlack)
                              : isFuture
                              ? Colors.transparent
                              : (isDark
                                    ? const Color(0xFF27272A)
                                    : AppTheme.grayKeypad),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          months[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isFuture
                                ? Colors.grey.withOpacity(0.35)
                                : isSelected
                                ? (isDark ? AppTheme.pureBlack : Colors.white)
                                : (isDark ? Colors.white : AppTheme.pureBlack),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions strictly for the selected month
    final monthlyTxs = allTransactions.where((t) {
      return t.isExpense &&
          t.transactionDate.year == selectedMonth.year &&
          t.transactionDate.month == selectedMonth.month;
    }).toList();

    final double totalMonthSpend = monthlyTxs.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // Group into categories
    final Map<String, double> catMap = {};
    final Map<String, String> emojiMap = {};
    for (var tx in monthlyTxs) {
      final name = tx.category?.name ?? 'others';
      catMap[name] = (catMap[name] ?? 0.0) + tx.amount;
      emojiMap[name] = tx.category?.emoji ?? '📦';
    }

    // Sort descending by spend amount
    final sortedEntries = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 5 categories
    final top5 = sortedEntries.take(5).toList();

    final List<CategorySpendingItem> items = [];
    for (int i = 0; i < top5.length; i++) {
      final entry = top5[i];
      final pct = totalMonthSpend > 0 ? (entry.value / totalMonthSpend) : 0.0;

      // Look up category model to use its actual configured color and icon
      CategoryModel? catModel;
      for (final c in provider.categories) {
        if (c.name.toLowerCase() == entry.key.toLowerCase()) {
          catModel = c;
          break;
        }
      }

      final catColor = catModel?.color ??
          CategoryModel.getDefaultColorForName(entry.key);
      final catIcon = catModel?.icon ??
          CategoryModel.getIconForName(entry.key);

      items.add(
        CategorySpendingItem(
          name: entry.key,
          emoji: emojiMap[entry.key] ?? '📦',
          amount: entry.value,
          percentage: pct,
          color: catColor,
          icon: catIcon,
        ),
      );
    }

    final monthFormatter = DateFormat('MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Row: Month/Year filter chip on left, Tab Menu Toggle on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Month Picker Filter Chip
            InkWell(
              onTap: () => _showMonthYearPicker(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F1F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: AppTheme.grayTextMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      monthFormatter.format(selectedMonth),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.pureBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppTheme.grayTextMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Tab menu toggle (All Expense Transaction, Chart by categories)
            ?tabToggle,
          ],
        ),
        const SizedBox(height: 16),

        // Donut Chart with Center "Total Expenses" and Rounded Segments
        Center(
          child: SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _DonutChartPainter(
                    items: items,
                    total: totalMonthSpend,
                    isDark: isDark,
                  ),
                ),
                // Center text: "Total Expenses" & formatted amount (Tap to view all monthly transactions)
                GestureDetector(
                  onTap: () => _showMonthDetailsSheet(context),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Expenses',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grayTextMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          CurrencyFormat.format(totalMonthSpend),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Header: "All Expenses"
        Text(
          'All Expenses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.pureBlack,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),

        // List of Category Cards (Matching user's reference design with icon box, %, and progress bar!)
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'No expenses logged for ${monthFormatter.format(selectedMonth)}',
                style: const TextStyle(
                  color: AppTheme.grayTextMuted,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...items.map((item) {
            final diffPct = provider.getCategoryChangeVsLastMonth(
              item.name,
              selectedMonth,
            );
            return _buildCategoryCard(
              context,
              item: item,
              diffPct: diffPct,
              isDark: isDark,
              onTap: () {
                _showCategoryDetailsSheet(context, item.name);
              },
            );
          }),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required CategorySpendingItem item,
    required double? diffPct,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Tinted square category icon box with category color accent
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: isDark ? 0.20 : 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: item.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Category name and "% of total"
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${(item.percentage * 100).toStringAsFixed(1)}% of total',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.grayTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount and vs last month badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormat.format(item.amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildVsLastMonthBadge(diffPct),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Horizontal Progress Bar matching the category segment color
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        color: isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFF1F1F4),
                      ),
                      FractionallySizedBox(
                        widthFactor: item.percentage.clamp(0.0, 1.0),
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVsLastMonthBadge(double? diffPct) {
    if (diffPct == null) {
      // New category: Blue badge for "new", grey text for "vs previous month"
      const blueColor = Color(0xFF0EA5E9);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: blueColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'new',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: blueColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'vs previous month',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppTheme.grayTextMuted,
            ),
          ),
        ],
      );
    }

    // Expense increase is RED (higher spend), decrease is GREEN (savings)
    final isIncrease = diffPct >= 0;
    final badgeColor = isIncrease ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final text = '${isIncrease ? '+' : ''}${diffPct.toStringAsFixed(0)}%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'vs previous month',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppTheme.grayTextMuted,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategorySpendingItem> items;
  final double total;
  final bool isDark;

  _DonutChartPainter({
    required this.items,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 26.0;

    final basePaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C21) : const Color(0xFFF0F0F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0 || items.isEmpty) {
      canvas.drawCircle(center, radius, basePaint);
      return;
    }

    double startAngle = -pi / 2;
    final capAngle = (strokeWidth / 2) / radius;
    const gapAngle = 0.08;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final totalAngle = item.percentage * 2 * pi;
      if (totalAngle <= 0.01) continue;

      final drawnSweep = max(totalAngle - 2 * capAngle - gapAngle, 0.02);
      final drawnStart = startAngle + capAngle + (gapAngle / 2);

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        drawnStart,
        drawnSweep,
        false,
        paint,
      );

      startAngle += totalAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.items.length != items.length ||
        oldDelegate.isDark != isDark;
  }
}

class MonthDetailsSheetModal extends StatefulWidget {
  final DateTime selectedMonth;
  final String? categoryFilter;

  const MonthDetailsSheetModal({
    super.key,
    required this.selectedMonth,
    this.categoryFilter,
  });

  @override
  State<MonthDetailsSheetModal> createState() => _MonthDetailsSheetModalState();
}

class _MonthDetailsSheetModalState extends State<MonthDetailsSheetModal> {
  bool _isReloading = false;

  Future<void> _handleReload() async {
    setState(() => _isReloading = true);
    await context
        .read<ExpenseProvider>()
        .refreshData(delay: const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() => _isReloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthStr = DateFormat('MMMM yyyy').format(widget.selectedMonth);
    final provider = context.watch<ExpenseProvider>();
    final isLoading = _isReloading || provider.isLoading;

    final monthlyTxs = provider.transactions
        .where((t) =>
            t.isExpense &&
            t.transactionDate.year == widget.selectedMonth.year &&
            t.transactionDate.month == widget.selectedMonth.month &&
            (widget.categoryFilter == null ||
                (t.category?.name.toLowerCase() ==
                    widget.categoryFilter!.toLowerCase())))
        .toList();
    final total = monthlyTxs.fold<double>(0.0, (sum, t) => sum + t.amount);

    final headerTitle = widget.categoryFilter != null
        ? widget.categoryFilter!
        : monthStr;
    final headerSubtitle = widget.categoryFilter != null
        ? '$monthStr • ${monthlyTxs.length} transactions'
        : '${monthlyTxs.length} transactions logged';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C0E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Top bar: Reload on left, drag handle in center, close icon button at right
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

          // Content: Skeleton Loader or Loaded Data
          Expanded(
            child: isLoading
                ? const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: DetailChartSkeleton(),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (widget.categoryFilter != null) ...[
                                Builder(
                                  builder: (context) {
                                    final catModel = provider.categories
                                        .where((c) =>
                                            c.name.toLowerCase() ==
                                            widget.categoryFilter!.toLowerCase())
                                        .firstOrNull;
                                    final color = catModel?.color ??
                                        CategoryModel.getDefaultColorForName(
                                            widget.categoryFilter!);
                                    final icon = catModel?.icon ??
                                        CategoryModel.getIconForName(
                                            widget.categoryFilter!);
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                            alpha: isDark ? 0.20 : 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Icon(icon, size: 20, color: color),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headerTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.pureBlack,
                                    ),
                                  ),
                                  Text(
                                    headerSubtitle,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormat.format(total),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: isDark
                            ? const Color(0xFF27272A)
                            : AppTheme.grayBorder,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: monthlyTxs.isEmpty
                            ? Center(
                                child: Text(
                                  widget.categoryFilter != null
                                      ? 'No expenses for ${widget.categoryFilter} in this month.'
                                      : 'No expenses in this month.',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: monthlyTxs.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return TransactionTile(
                                    transaction: monthlyTxs[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
