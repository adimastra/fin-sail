import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/providers/expense_provider.dart';

void main() {
  group('Authentication & Session Unit Tests', () {
    late ExpenseProvider provider;

    setUp(() async {
      provider = ExpenseProvider();
      await provider.init(delay: Duration.zero);
    });

    test('Initial auth state is not authenticated before login', () {
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });

    test('signInWithGoogle authenticates user and flags isGuest false', () async {
      final success = await provider.signInWithGoogle();

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.provider, 'google');
      expect(provider.currentUser!.isGuest, isFalse);
    });

    test('signInAsGuest authenticates user with mock data and flags isGuest true', () async {
      final success = await provider.signInAsGuest();

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.isGuest, isTrue);
      expect(provider.currentUser!.displayName, 'Alex Morgan');
      expect(provider.transactions.isNotEmpty, isTrue);
    });

    test('signOut resets auth state to unauthenticated and purges memory transactions', () async {
      await provider.signInAsGuest();
      expect(provider.isAuthenticated, isTrue);
      expect(provider.transactions.isNotEmpty, isTrue);

      await provider.signOut();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.transactions, isEmpty);
    });

    test('legacy phone auth methods succeed and set phone provider', () async {
      final success = await provider.signInWithPhone(
        phone: '+628987654321',
        password: 'securepassword',
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.provider, 'phone');
    });
  });
}
