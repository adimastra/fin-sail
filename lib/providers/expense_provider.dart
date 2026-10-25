import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/auth_user.dart';
import '../models/category_model.dart';
import '../models/receipt_data.dart';
import '../models/transaction_model.dart';
import '../services/receipt_scanner_service.dart';
import '../services/supabase_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  late final ReceiptScannerService _scannerService = ReceiptScannerService();

  ExpenseProvider() {
    _supabaseService.onAuthStateChanged = (user) {
      if (user != null) {
        loadUserData(isGuest: user.isGuest);
      } else {
        _transactions = [];
        _categories = [];
        notifyListeners();
      }
    };
  }

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  bool _isScanning = false;
  String? _error;
  ThemeMode _themeMode = ThemeMode.dark; // Default to sleek dark mode

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get error => _error;
  ThemeMode get themeMode => _themeMode;

  AuthUser? get currentUser => _supabaseService.currentUser;
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _supabaseService.signInWithGoogle();
      if (_supabaseService.currentUser != null) {
        await loadUserData(isGuest: _supabaseService.currentUser!.isGuest);
      }
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Google Sign In failed: ${e.toString().replaceFirst('Exception: ', '')}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _supabaseService.signUpWithPhone(
        phone: phone,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _supabaseService.signInWithPhone(
        phone: phone,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAsGuest() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _supabaseService.signInAsGuest();
      await loadUserData(isGuest: true);
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Guest sign in failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _supabaseService.signOut();
    _transactions = [];
    _categories = [];
    _isLoading = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Filtered transactions for the currently viewed month (purely expenses)
  List<TransactionModel> get monthlyExpenses {
    return _transactions.where((tx) {
      return tx.isExpense &&
          tx.transactionDate.year == _selectedMonth.year &&
          tx.transactionDate.month == _selectedMonth.month;
    }).toList();
  }

  // Total expenses spent in the selected month
  double get totalExpense {
    return monthlyExpenses.fold(0.0, (sum, t) => sum + t.amount);
  }

  // Total expenses spent in any given month
  double getTotalExpenseForMonth(DateTime month) {
    return _transactions.where((tx) {
      return tx.isExpense &&
          tx.transactionDate.year == month.year &&
          tx.transactionDate.month == month.month;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  // Monthly expense trend for a list of months
  List<double> getExpenseTrendForMonths(List<DateTime> months) {
    return months.map((m) => getTotalExpenseForMonth(m)).toList();
  }

  // Calculate percentage change vs last month for a given category in the given month
  double? getCategoryChangeVsLastMonth(String categoryName, DateTime month) {
    final currentMonthTxs = _transactions.where((t) =>
        t.isExpense &&
        t.transactionDate.year == month.year &&
        t.transactionDate.month == month.month &&
        (t.category?.name.toLowerCase() == categoryName.toLowerCase()));
    final currentSum = currentMonthTxs.fold<double>(0.0, (s, t) => s + t.amount);

    final prevMonth = DateTime(month.year, month.month - 1);
    final prevMonthTxs = _transactions.where((t) =>
        t.isExpense &&
        t.transactionDate.year == prevMonth.year &&
        t.transactionDate.month == prevMonth.month &&
        (t.category?.name.toLowerCase() == categoryName.toLowerCase()));
    final prevSum = prevMonthTxs.fold<double>(0.0, (s, t) => s + t.amount);

    if (prevSum <= 0) {
      return null; // new category this month
    }
    return ((currentSum - prevSum) / prevSum) * 100.0;
  }

  // Daily average spent
  double get dailyAverage {
    final now = DateTime.now();
    int daysInCount = 1;
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      daysInCount = now.day > 0 ? now.day : 1;
    } else {
      daysInCount = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    }
    return totalExpense / daysInCount;
  }

  // Count of scanned receipts this month
  int get receiptCount {
    return monthlyExpenses.where((t) => t.hasReceipt).length;
  }

  // Top spending category name
  String get topCategoryName {
    final map = categorySpending;
    if (map.isEmpty) return '';
    var sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  // Category breakdown map for charts
  Map<String, double> get categorySpending {
    final Map<String, double> map = {};
    for (var tx in monthlyExpenses) {
      final catName = tx.category?.name ?? 'Other Expenses';
      map[catName] = (map[catName] ?? 0.0) + tx.amount;
    }
    return map;
  }

  Future<void> init({Duration delay = const Duration(milliseconds: 600)}) async {
    try {
      await _supabaseService.initialize();
      if (_supabaseService.currentUser != null) {
        await loadUserData(
          isGuest: _supabaseService.currentUser!.isGuest,
          delay: delay,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load user data with brief shimmer skeleton delay
  Future<void> loadUserData({
    bool isGuest = false,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
      _categories = List.from(await _supabaseService.getCategories());
      _transactions = List.from(await _supabaseService.getTransactions());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reload data with delay to test and preview skeleton loader anytime
  Future<void> refreshData({Duration delay = const Duration(milliseconds: 2000)}) async {
    await loadUserData(
      isGuest: _supabaseService.currentUser?.isGuest ?? true,
      delay: delay,
    );
  }

  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    notifyListeners();
  }

  Future<TransactionModel?> addNewTransaction({
    required double amount,
    String type = 'expense', // Always expense
    String? categoryId,
    String? merchant,
    required DateTime date,
    String? receiptUrl,
    ReceiptData? extractedData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final category = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => _categories.first,
      );

      final newTx = TransactionModel(
        id: '',
        userId: 'current-user',
        categoryId: categoryId,
        category: category,
        amount: amount,
        currency: 'IDR',
        type: 'expense',
        merchant: merchant,
        transactionDate: date,
        receiptUrl: receiptUrl,
        extractedData: extractedData,
      );

      final saved = await _supabaseService.addTransaction(newTx);
      _transactions.insert(0, saved);
      return saved;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeTransaction(String id) async {
    try {
      await _supabaseService.deleteTransaction(id);
      _transactions.removeWhere((tx) => tx.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<TransactionModel?> updateTransaction(TransactionModel updatedTx) async {
    _isLoading = true;
    notifyListeners();

    try {
      final saved = await _supabaseService.updateTransaction(updatedTx);
      final index = _transactions.indexWhere((tx) => tx.id == saved.id);
      if (index != -1) {
        _transactions[index] = saved;
      }
      return saved;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Receipt Scanner Flow
  Future<ReceiptData?> scanAndExtractReceipt({
    required Uint8List imageBytes,
    required String filename,
    String? mimeType,
  }) async {
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _scannerService.parseReceipt(
        imageBytes: imageBytes,
        filename: filename,
        mimeType: mimeType,
      );
      return data;
    } catch (e) {
      _error = 'Failed to analyze receipt: $e';
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<CategoryModel?> addCategory({
    required String name,
    String emoji = '',
    String? iconName,
    String colorHex = '#111111',
  }) async {
    try {
      final newCat = CategoryModel(
        id: 'cat-custom-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current-user',
        name: name.trim().toLowerCase(),
        emoji: emoji.trim().isEmpty ? '' : emoji.trim(),
        iconName: iconName ?? 'inventory_2',
        colorHex: colorHex,
        isDefault: false,
      );

      final created = await _supabaseService.addCategory(newCat);
      _categories = List.from(await _supabaseService.getCategories());
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create category: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final cat = _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Category not found'),
      );
      if (cat.isDefault) {
        throw Exception('Cannot delete default category');
      }

      final success = await _supabaseService.deleteCategory(id);
      if (success) {
        _categories = List.from(await _supabaseService.getCategories());
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }
}
