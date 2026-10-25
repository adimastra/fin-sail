import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/providers/expense_provider.dart';

void main() {
  group('Phone Auth & Authentication Unit Tests', () {
    late ExpenseProvider provider;

    setUp(() async {
      provider = ExpenseProvider();
      await provider.init(delay: Duration.zero);
    });

    test('Initial auth state is not authenticated before login', () {
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });

    test('signUpWithPhone successfully registers and authenticates user', () async {
      final success = await provider.signUpWithPhone(
        phone: '+628123456789',
        password: 'password123',
        displayName: 'John Doe',
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.displayName, 'John Doe');
      expect(provider.currentUser!.provider, 'phone');
    });

    test('signInWithPhone successfully logs in user', () async {
      final success = await provider.signInWithPhone(
        phone: '+628987654321',
        password: 'securepassword',
      );

      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.provider, 'phone');
    });

    test('signOut resets auth state to unauthenticated', () async {
      await provider.signInWithPhone(
        phone: '+628111222333',
        password: 'password123',
      );
      expect(provider.isAuthenticated, isTrue);

      await provider.signOut();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });

    test('signInAsGuest authenticates with mock user', () async {
      final success = await provider.signInAsGuest();
      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.displayName, 'Alex Morgan');
    });
  });
}
