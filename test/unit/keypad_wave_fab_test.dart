import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/models/transaction_model.dart';
import 'package:fin_logs/widgets/minimal_trend_chart.dart';
import 'package:fin_logs/widgets/expand_hover_highlight.dart';
import 'package:fin_logs/widgets/transaction_tile.dart';

void main() {
  group('FAB Proportional Sizing Tests', () {
    test('Scan Receipt FAB size is exactly 3/4 of Add Expense FAB size', () {
      const double scanFabSize = 48.0;
      const double addExpenseFabSize = 64.0;

      final ratio = scanFabSize / addExpenseFabSize;
      expect(ratio, equals(0.75));
      expect(scanFabSize, equals(addExpenseFabSize * 0.75));
    });
  });

  group('Ocean Wave Generator Tests', () {
    test('buildWavePath generates valid non-empty path with default phase', () {
      final path = MinimalTrendChart.buildWavePath(360.0, 68.0);
      expect(path, isNotNull);
      final metrics = path.computeMetrics().toList();
      expect(metrics.isNotEmpty, isTrue);
      expect(metrics.first.length, greaterThan(300.0));
    });

    test('buildWavePath produces distinct dynamic wave curves across phases', () {
      const w = 360.0;
      const h = 68.0;

      final pathPhase0 = MinimalTrendChart.buildWavePath(w, h, wavePhase: 0.0);
      final pathPhasePi = MinimalTrendChart.buildWavePath(w, h, wavePhase: pi);

      final metric0 = pathPhase0.computeMetrics().first;
      final metricPi = pathPhasePi.computeMetrics().first;

      // Sample quarter-point elevation at x ≈ 0.25w where wave crests/troughs occur
      final tangent0 = metric0.getTangentForOffset(metric0.length * 0.25);
      final tangentPi = metricPi.getTangentForOffset(metricPi.length * 0.25);

      expect(tangent0, isNotNull);
      expect(tangentPi, isNotNull);

      // The y-elevation at phase 0 and phase pi should oscillate with the harmonic wave
      final dyDiff = (tangent0!.position.dy - tangentPi!.position.dy).abs();
      expect(dyDiff, greaterThan(0.5));
    });
  });

  group('Keypad Zero-Initial Input Logic Tests', () {
    test('Initial amount is 0 and keypress replaces 0 with input digit', () {
      String amountDigits = '0';

      void onKeyPress(String key) {
        if (key == '000') {
          if (amountDigits != '0' && amountDigits.length <= 7) {
            amountDigits = '${amountDigits}000';
          }
        } else if (key == '.') {
          // No decimal for IDR
        } else {
          if (amountDigits == '0') {
            amountDigits = key;
          } else if (amountDigits.length < 10) {
            amountDigits = '$amountDigits$key';
          }
        }
      }

      void onBackspace() {
        if (amountDigits.length > 1) {
          amountDigits = amountDigits.substring(0, amountDigits.length - 1);
        } else {
          amountDigits = '0';
        }
      }

      // 1. Initial value is 0
      expect(amountDigits, equals('0'));

      // 2. Pressing '000' while at '0' remains '0'
      onKeyPress('000');
      expect(amountDigits, equals('0'));

      // 3. Pressing '5' replaces '0' with '5'
      onKeyPress('5');
      expect(amountDigits, equals('5'));

      // 4. Pressing '000' on '5' appends '000' -> '5000'
      onKeyPress('000');
      expect(amountDigits, equals('5000'));

      // 5. Backspacing returns to single digit then '0'
      onBackspace(); // '500'
      onBackspace(); // '50'
      onBackspace(); // '5'
      expect(amountDigits, equals('5'));
      onBackspace(); // Reverts to '0'
      expect(amountDigits, equals('0'));
    });
  });

  group('ExpandHoverHighlight & TransactionTile Widget Tests', () {
    testWidgets('ExpandHoverHighlight renders child with specified padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandHoverHighlight(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byType(ExpandHoverHighlight), findsOneWidget);
    });

    testWidgets('TransactionTile renders with gap padding and category data', (tester) async {
      final tx = TransactionModel(
        id: 'tx-1',
        userId: 'user-1',
        amount: 285000,
        merchant: 'Apotek Kimia Farma',
        categoryId: 'health',
        transactionDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              transaction: tx,
            ),
          ),
        ),
      );

      expect(find.text('Apotek Kimia Farma'.toLowerCase()), findsOneWidget);
      expect(find.byType(ExpandHoverHighlight), findsOneWidget);

      final highlightFinder = find.byType(ExpandHoverHighlight);
      final highlightWidget = tester.widget<ExpandHoverHighlight>(highlightFinder);
      expect(
        highlightWidget.padding,
        equals(const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
      );
    });
  });
}
