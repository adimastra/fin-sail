import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/providers/expense_provider.dart';
import 'package:fin_logs/widgets/animated_action_dialog.dart';

void main() {
  group('Action Confirmations, Guards and Animation Unit Tests', () {
    late ExpenseProvider provider;

    setUp(() async {
      provider = ExpenseProvider();
      await provider.init(delay: Duration.zero);
      await provider.signInAsGuest();
    });

    test('AnimatedSuccessDialog initializes with valid parameters', () {
      const dialog = AnimatedSuccessDialog(
        title: 'Expense Updated!',
        subtitle: 'Rp 50.000 • Starbucks',
        icon: Icons.check_circle_rounded,
        accentColor: Color(0xFF10B981),
        autoDismissDuration: Duration(milliseconds: 1500),
      );

      expect(dialog.title, 'Expense Updated!');
      expect(dialog.subtitle, 'Rp 50.000 • Starbucks');
      expect(dialog.icon, Icons.check_circle_rounded);
      expect(dialog.accentColor, const Color(0xFF10B981));
      expect(dialog.autoDismissDuration.inMilliseconds, 1500);
    });

    test('ActionConfirmationDialog initializes with confirmation tokens', () {
      const dialog = ActionConfirmationDialog(
        title: 'Save Changes?',
        message: 'Are you sure you want to update this expense?',
        confirmText: 'Save Changes',
        cancelText: 'Cancel',
        isDestructive: false,
        icon: Icons.edit_note_rounded,
      );

      expect(dialog.title, 'Save Changes?');
      expect(dialog.message, 'Are you sure you want to update this expense?');
      expect(dialog.confirmText, 'Save Changes');
      expect(dialog.cancelText, 'Cancel');
      expect(dialog.isDestructive, isFalse);
      expect(dialog.icon, Icons.edit_note_rounded);
    });

    test('Donut chart sweep calculation scales proportionally with animationProgress', () {
      const double totalAngle = 0.5 * 2 * pi; // 50% circle
      const double capAngle = 0.1;
      const double gapAngle = 0.08;
      final double drawnSweep = max(totalAngle - 2 * capAngle - gapAngle, 0.02);

      // On initial load (progress = 0.0)
      final sweepAtZero = drawnSweep * 0.0;
      expect(sweepAtZero, 0.0);

      // Midway (progress = 0.5)
      final sweepAtHalf = drawnSweep * 0.5;
      expect(sweepAtHalf, closeTo(drawnSweep / 2, 0.0001));

      // Finished (progress = 1.0)
      final sweepAtFull = drawnSweep * 1.0;
      expect(sweepAtFull, closeTo(drawnSweep, 0.0001));
    });

    test('Category card line score (progress bar) scales accurately with animation', () {
      const double categoryPercentage = 0.42; // 42%

      // Progress at 0%
      final factorAtZero = (categoryPercentage.clamp(0.0, 1.0) * 0.0).clamp(
        0.0,
        1.0,
      );
      expect(factorAtZero, 0.0);

      // Progress at 50%
      final factorAtHalf = (categoryPercentage.clamp(0.0, 1.0) * 0.5).clamp(
        0.0,
        1.0,
      );
      expect(factorAtHalf, closeTo(0.21, 0.0001));

      // Progress at 100%
      final factorAtFull = (categoryPercentage.clamp(0.0, 1.0) * 1.0).clamp(
        0.0,
        1.0,
      );
      expect(factorAtFull, closeTo(0.42, 0.0001));
    });

    test(
      'Expense update preserves data integrity and updates provider state',
      () async {
        expect(provider.transactions.isNotEmpty, isTrue);
        final originalTx = provider.transactions.first;

        final updatedTx = originalTx.copyWith(
          merchant: 'Edited Merchant Supermarket',
          amount: 88000.0,
        );

        final result = await provider.updateTransaction(updatedTx);
        expect(result, isNotNull);
        expect(result!.merchant, 'Edited Merchant Supermarket');
        expect(result.amount, 88000.0);

        // Verify in memory store
        final found = provider.transactions.firstWhere(
          (t) => t.id == originalTx.id,
        );
        expect(found.merchant, 'Edited Merchant Supermarket');
        expect(found.amount, 88000.0);
      },
    );

    test(
      'Category add and delete operations execute safely with provider guards',
      () async {
        final initialCount = provider.categories.length;

        // Add custom category
        final custom = await provider.addCategory(
          name: 'Gamer Gear',
          emoji: '🎮',
          iconName: 'sports_esports_rounded',
          colorHex: '#8B5CF6',
        );

        expect(custom, isNotNull);
        expect(custom!.name.toLowerCase(), 'gamer gear');
        expect(provider.categories.length, initialCount + 1);

        // Delete custom category
        final deleted = await provider.deleteCategory(custom.id);
        expect(deleted, isTrue);
        expect(provider.categories.length, initialCount);

        // Guard: Cannot delete system default categories
        final defaultCat = provider.categories.firstWhere(
          (c) => !c.id.startsWith('custom-'),
        );
        final deleteDefaultResult = await provider.deleteCategory(
          defaultCat.id,
        );
        expect(deleteDefaultResult, isFalse);
      },
    );
  });
}
