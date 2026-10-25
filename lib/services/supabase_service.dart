import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../config/supabase_config.dart';
import '../models/auth_user.dart';
import '../models/category_model.dart';
import '../models/receipt_data.dart';
import '../models/transaction_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _initialized = false;

  // In-memory mock database for instant interactive demo
  final List<TransactionModel> _mockTransactions = [];
  final List<CategoryModel> _mockCategories = List.from(CategoryModel.defaultCategories);

  bool get isDemoMode => SupabaseConfig.isDemoMode || _client == null;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  void Function(AuthUser?)? onAuthStateChanged;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!SupabaseConfig.isDemoMode) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
        );
        _client = Supabase.instance.client;
        final currentAuthUser = _client?.auth.currentUser;
        if (currentAuthUser != null) {
          _currentUser = AuthUser.fromSupabaseUser(currentAuthUser);
        }
        _client?.auth.onAuthStateChange.listen((data) {
          final session = data.session;
          if (session?.user != null) {
            _currentUser = AuthUser.fromSupabaseUser(session!.user);
          } else if (data.event == AuthChangeEvent.signedOut) {
            _currentUser = null;
          }
          onAuthStateChanged?.call(_currentUser);
        });
        debugPrint('Supabase successfully initialized.');
      } catch (e) {
        debugPrint('Failed to initialize Supabase, fallback to Demo Mode: $e');
      }
    }

    _seedMockData();
    _initialized = true;
  }

  Future<void> signInWithGoogle() async {
    if (!isDemoMode && _client != null) {
      try {
        final redirectUrl = kIsWeb
            ? '${Uri.base.origin}${Uri.base.path}'
            : 'io.supabase.finlogs://login-callback/';
        debugPrint('Launching Supabase Google OAuth with redirectTo: $redirectUrl');
        await _client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
      } catch (e) {
        debugPrint('Supabase Google OAuth failed: $e');
        rethrow;
      }
    } else {
      _currentUser = AuthUser.mockGoogleUser();
      onAuthStateChanged?.call(_currentUser);
    }
  }

  Future<AuthUser?> signUpWithPhone({
    required String phone,
    required String password,
    String? displayName,
  }) async {
    if (!isDemoMode && _client != null) {
      try {
        final res = await _client!.auth.signUp(
          phone: phone,
          password: password,
          data: displayName != null ? {'display_name': displayName} : null,
        );
        final user = res.user;
        if (user != null) {
          _currentUser = AuthUser.fromSupabaseUser(user);
          onAuthStateChanged?.call(_currentUser);
          return _currentUser;
        }
        return null;
      } catch (e) {
        debugPrint('Supabase phone sign up failed: $e');
        rethrow;
      }
    }
    _currentUser = AuthUser(
      id: 'demo-phone-user',
      email: '$phone@demo.finsail.app',
      displayName: displayName ?? 'User ${phone.length >= 4 ? phone.substring(phone.length - 4) : phone}',
      provider: 'phone',
    );
    onAuthStateChanged?.call(_currentUser);
    return _currentUser;
  }

  Future<AuthUser?> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    if (!isDemoMode && _client != null) {
      try {
        final res = await _client!.auth.signInWithPassword(
          phone: phone,
          password: password,
        );
        final user = res.user;
        if (user != null) {
          _currentUser = AuthUser.fromSupabaseUser(user);
          onAuthStateChanged?.call(_currentUser);
          return _currentUser;
        }
        return null;
      } catch (e) {
        debugPrint('Supabase phone sign in failed: $e');
        rethrow;
      }
    }
    _currentUser = AuthUser(
      id: 'demo-phone-user',
      email: '$phone@demo.finsail.app',
      displayName: 'User ${phone.length >= 4 ? phone.substring(phone.length - 4) : phone}',
      provider: 'phone',
    );
    onAuthStateChanged?.call(_currentUser);
    return _currentUser;
  }

  Future<AuthUser> signInAsGuest() async {
    _currentUser = AuthUser.guest();
    _seedMockData();
    onAuthStateChanged?.call(_currentUser);
    return _currentUser!;
  }

  Future<void> signOut() async {
    if (!isDemoMode && _client != null) {
      try {
        await _client!.auth.signOut();
      } catch (e) {
        debugPrint('Supabase sign out error: $e');
      }
    }
    _currentUser = null;
    onAuthStateChanged?.call(null);
  }

  void _seedMockData() {
    _mockTransactions.clear();
    final now = DateTime.now();

    // Helper to get or fallback category
    CategoryModel getCat(String id) {
      return _mockCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => _mockCategories.first,
      );
    }

    // 1. TODAY SAMPLE DATA
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-today-1',
        userId: 'demo-user',
        categoryId: 'cat-coffee',
        category: getCat('cat-coffee'),
        amount: 38000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Kopi Kenangan',
        transactionDate: DateTime(now.year, now.month, now.day, 9, 30),
        receiptUrl: 'https://images.unsplash.com/photo-1534452203293-494d7ddbf7e0?w=500&auto=format&fit=crop&q=60',
        extractedData: ReceiptData(
          merchant: 'Kopi Kenangan',
          amount: 38000,
          currency: 'IDR',
          date: now,
          suggestedCategory: 'coffee',
          items: [
            ReceiptItem(name: 'Kopi Kenangan Mantan Large', price: 24000),
            ReceiptItem(name: 'Roti Coklat Klasik', price: 14000),
          ],
        ),
      ),
      TransactionModel(
        id: 'tx-today-2',
        userId: 'demo-user',
        categoryId: 'cat-food',
        category: getCat('cat-food'),
        amount: 65000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Burger King',
        transactionDate: DateTime(now.year, now.month, now.day, 12, 45),
      ),
      TransactionModel(
        id: 'tx-today-3',
        userId: 'demo-user',
        categoryId: 'cat-commute',
        category: getCat('cat-commute'),
        amount: 25000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Gojek Ride',
        transactionDate: DateTime(now.year, now.month, now.day, 17, 15),
      ),
    ]);

    // 2. YESTERDAY SAMPLE DATA
    final yesterday = now.subtract(const Duration(days: 1));
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-yest-1',
        userId: 'demo-user',
        categoryId: 'cat-groceries',
        category: getCat('cat-groceries'),
        amount: 145000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Super Indo',
        transactionDate: DateTime(yesterday.year, yesterday.month, yesterday.day, 18, 20),
        receiptUrl: 'https://images.unsplash.com/photo-1554415707-9e4466759538?w=500&auto=format&fit=crop&q=60',
        extractedData: ReceiptData(
          merchant: 'Super Indo',
          amount: 145000,
          currency: 'IDR',
          date: yesterday,
          suggestedCategory: 'groceries',
          items: [
            ReceiptItem(name: 'Telur Ayam 1kg', price: 32000),
            ReceiptItem(name: 'Susu UHT Fresh 1L', price: 21500),
            ReceiptItem(name: 'Buah Apel Fuji', price: 48000),
            ReceiptItem(name: 'Beras Pandan Wangi 2.5kg', price: 43500),
          ],
        ),
      ),
      TransactionModel(
        id: 'tx-yest-2',
        userId: 'demo-user',
        categoryId: 'cat-pet',
        category: getCat('cat-pet'),
        amount: 85000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Pet Care Center',
        transactionDate: DateTime(yesterday.year, yesterday.month, yesterday.day, 15, 0),
      ),
    ]);

    // 3. LAST WEEK SAMPLE DATA (3 to 7 days ago)
    final d3 = now.subtract(const Duration(days: 3));
    final d5 = now.subtract(const Duration(days: 5));
    final d7 = now.subtract(const Duration(days: 7));
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-lastweek-1',
        userId: 'demo-user',
        categoryId: 'cat-repair',
        category: getCat('cat-repair'),
        amount: 120000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Toko Bangunan Makmur',
        transactionDate: DateTime(d3.year, d3.month, d3.day, 11, 0),
      ),
      TransactionModel(
        id: 'tx-lastweek-2',
        userId: 'demo-user',
        categoryId: 'cat-shopping',
        category: getCat('cat-shopping'),
        amount: 299000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Uniqlo',
        transactionDate: DateTime(d5.year, d5.month, d5.day, 16, 30),
        receiptUrl: 'https://images.unsplash.com/photo-1526628953301-3e589a6a8b74?w=500&auto=format&fit=crop&q=60',
      ),
      TransactionModel(
        id: 'tx-lastweek-3',
        userId: 'demo-user',
        categoryId: 'cat-bills',
        category: getCat('cat-bills'),
        amount: 375000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'IndiHome Fiber',
        transactionDate: DateTime(d7.year, d7.month, d7.day, 10, 0),
      ),
    ]);

    // 4. PASSED 3 MONTHS SAMPLE DATA
    // Month -1 (Matches user's reference image: Total Rp 1.350.000)
    final m1 = DateTime(now.year, now.month - 1, 15);
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-m1-1',
        userId: 'demo-user',
        categoryId: 'cat-food',
        category: getCat('cat-food'),
        amount: 472500, // Food 35%
        currency: 'IDR',
        type: 'expense',
        merchant: 'Restoran Seafood & Cafe',
        transactionDate: DateTime(m1.year, m1.month, 10),
      ),
      TransactionModel(
        id: 'tx-m1-2',
        userId: 'demo-user',
        categoryId: 'cat-shopping',
        category: getCat('cat-shopping'),
        amount: 270000, // Shopping 25% (or 20%)
        currency: 'IDR',
        type: 'expense',
        merchant: 'Zara Fashion',
        transactionDate: DateTime(m1.year, m1.month, 14),
      ),
      TransactionModel(
        id: 'tx-m1-3',
        userId: 'demo-user',
        categoryId: 'cat-commute',
        category: getCat('cat-commute'),
        amount: 337500, // Transportation 20%
        currency: 'IDR',
        type: 'expense',
        merchant: 'Bensin Shell & Tol',
        transactionDate: DateTime(m1.year, m1.month, 18),
      ),
      TransactionModel(
        id: 'tx-m1-4',
        userId: 'demo-user',
        categoryId: 'cat-other',
        category: getCat('cat-other'),
        amount: 270000, // Others 20%
        currency: 'IDR',
        type: 'expense',
        merchant: 'Keperluan Lainnya',
        transactionDate: DateTime(m1.year, m1.month, 24),
      ),
    ]);

    // Month -2
    final m2 = DateTime(now.year, now.month - 2, 12);
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-m2-1',
        userId: 'demo-user',
        categoryId: 'cat-groceries',
        category: getCat('cat-groceries'),
        amount: 620000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Hypermart Bulanan',
        transactionDate: DateTime(m2.year, m2.month, 5),
      ),
      TransactionModel(
        id: 'tx-m2-2',
        userId: 'demo-user',
        categoryId: 'cat-repair',
        category: getCat('cat-repair'),
        amount: 450000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Service AC Rumah',
        transactionDate: DateTime(m2.year, m2.month, 16),
      ),
      TransactionModel(
        id: 'tx-m2-3',
        userId: 'demo-user',
        categoryId: 'cat-food',
        category: getCat('cat-food'),
        amount: 380000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Warung Nasi & Kuliner',
        transactionDate: DateTime(m2.year, m2.month, 22),
      ),
    ]);

    // Month -3
    final m3 = DateTime(now.year, now.month - 3, 8);
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-m3-1',
        userId: 'demo-user',
        categoryId: 'cat-bills',
        category: getCat('cat-bills'),
        amount: 520000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'PLN Listrik Token',
        transactionDate: DateTime(m3.year, m3.month, 4),
      ),
      TransactionModel(
        id: 'tx-m3-2',
        userId: 'demo-user',
        categoryId: 'cat-health',
        category: getCat('cat-health'),
        amount: 285000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Apotek Kimia Farma',
        transactionDate: DateTime(m3.year, m3.month, 12),
      ),
      TransactionModel(
        id: 'tx-m3-3',
        userId: 'demo-user',
        categoryId: 'cat-pet',
        category: getCat('cat-pet'),
        amount: 350000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Grooming & Vaksin Kucing',
        transactionDate: DateTime(m3.year, m3.month, 20),
      ),
    ]);

    // Month -4 (Jun)
    final m4 = DateTime(now.year, now.month - 4, 10);
    _mockTransactions.addAll([
      TransactionModel(
        id: 'tx-m4-1',
        userId: 'demo-user',
        categoryId: 'cat-groceries',
        category: getCat('cat-groceries'),
        amount: 450000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Superindo Bulanan',
        transactionDate: DateTime(m4.year, m4.month, 10),
      ),
      TransactionModel(
        id: 'tx-m4-2',
        userId: 'demo-user',
        categoryId: 'cat-bills',
        category: getCat('cat-bills'),
        amount: 500000,
        currency: 'IDR',
        type: 'expense',
        merchant: 'Listrik & Internet',
        transactionDate: DateTime(m4.year, m4.month, 22),
      ),
    ]);
  }

  // Fetch transactions (purely expenses)
  Future<List<TransactionModel>> getTransactions() async {
    // If guest or demo mode, strictly consume mock seed data
    if (isDemoMode || _client == null || (_currentUser?.isGuest ?? true)) {
      _mockTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return List.unmodifiable(_mockTransactions);
    }

    try {
      final res = await _client!
          .from('transactions')
          .select('*, categories(*)')
          .order('transaction_date', ascending: false);

      return (res as List).map((row) {
        final catData = row['categories'];
        final category = catData != null ? CategoryModel.fromJson(catData) : null;
        return TransactionModel.fromJson(row, category: category);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions from Supabase: $e');
      return [];
    }
  }

  // Add new transaction
  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    if (isDemoMode || _client == null || (_currentUser?.isGuest ?? true)) {
      final newTx = tx.copyWith(
        id: tx.id.isEmpty ? 'tx-${DateTime.now().millisecondsSinceEpoch}' : tx.id,
        currency: 'IDR',
        category: tx.category ?? _mockCategories.firstWhere(
          (c) => c.id == tx.categoryId,
          orElse: () => _mockCategories.first,
        ),
      );
      _mockTransactions.insert(0, newTx);
      return newTx;
    }

    final data = tx.toJson()..remove('id');
    final res = await _client!.from('transactions').insert(data).select().single();
    return TransactionModel.fromJson(res);
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    if (isDemoMode || _client == null || (_currentUser?.isGuest ?? true)) {
      _mockTransactions.removeWhere((tx) => tx.id == id);
      return;
    }

    await _client!.from('transactions').delete().eq('id', id);
  }

  // Update transaction
  Future<TransactionModel> updateTransaction(TransactionModel tx) async {
    if (isDemoMode || _client == null || (_currentUser?.isGuest ?? true)) {
      final index = _mockTransactions.indexWhere((t) => t.id == tx.id);
      if (index != -1) {
        _mockTransactions[index] = tx;
      }
      return tx;
    }

    final res = await _client!
        .from('transactions')
        .update(tx.toJson())
        .eq('id', tx.id)
        .select('*, categories(*)')
        .single();
    return TransactionModel.fromJson(res);
  }

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    if (isDemoMode || _client == null || (_currentUser?.isGuest ?? true)) {
      return List.unmodifiable(_mockCategories);
    }
    try {
      final res = await _client!.from('categories').select().order('name');
      final list = (res as List).map((c) => CategoryModel.fromJson(c)).toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Supabase categories fetch failed: $e');
    }
    return List.unmodifiable(_mockCategories);
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    if (!isDemoMode && _client != null) {
      try {
        final payload = category.toJson();
        final res = await _client!.from('categories').insert(payload).select().single();
        final created = CategoryModel.fromJson(res);
        _mockCategories.add(created);
        return created;
      } catch (e) {
        debugPrint('Supabase category insert failed: $e');
      }
    }
    _mockCategories.add(category);
    return category;
  }

  Future<bool> deleteCategory(String id) async {
    // Only allow deleting custom category (isDefault == false)
    final catIndex = _mockCategories.indexWhere((c) => c.id == id);
    if (catIndex != -1 && _mockCategories[catIndex].isDefault) {
      debugPrint('Cannot delete default category: $id');
      return false;
    }

    if (!isDemoMode && _client != null) {
      try {
        await _client!.from('categories').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase category delete failed: $e');
      }
    }
    if (catIndex != -1) {
      _mockCategories.removeAt(catIndex);
    }
    return true;
  }
}
