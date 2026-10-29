import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/transaction_model.dart';
import '../utils/currency_format.dart';
import 'expand_hover_highlight.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = transaction.category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor =
        category?.color ?? (isDark ? Colors.white70 : AppTheme.pureBlack);
    final catBg = catColor.withValues(alpha: isDark ? 0.20 : 0.14);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: ExpandHoverHighlight(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Vector Category Avatar with Color Accent
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: catBg,
              ),
              child: Center(
                child: Icon(
                  category?.icon ?? Icons.inventory_2_rounded,
                  size: 20,
                  color: catColor,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Category & Merchant
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category?.name ?? 'expense',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.hasReceipt) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.receipt,
                          size: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.merchant?.toLowerCase() ?? 'store',
                    style: const TextStyle(
                      color: AppTheme.grayTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Amount: -Rp XX.XXX
            Text(
              '-${CurrencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : AppTheme.pureBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
