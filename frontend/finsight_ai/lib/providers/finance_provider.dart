import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class FinanceProvider extends ChangeNotifier {
  final _api = ApiService();

  SpendingSummary? summary;
  List<Transaction> transactions = [];
  List<String> availableMonths = [];
  String? selectedMonth;
  String? selectedCategory;
  bool isLoading = false;
  bool isUploading = false;
  String? error;
  String? uploadStatus;

  // Colour map for the category bar chart and transaction icons
  static const Map<String, int> categoryColors = {
    'Food & Groceries': 0xFF4CAF50,
    'Transport': 0xFF2196F3,
    'Entertainment': 0xFFE91E63,
    'Utilities': 0xFFFF9800,
    'Shopping': 0xFF9C27B0,
    'Healthcare': 0xFFF44336,
    'Education': 0xFF00BCD4,
    'Income': 0xFF8BC34A,
    'Rent & Housing': 0xFF795548,
    'Other': 0xFF9E9E9E,
  };

  // ── Load all data ──────────────────────────────────────────────────────────
  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      availableMonths = await _api.getMonths();
      // Default to the most recent month on first load
      if (selectedMonth == null && availableMonths.isNotEmpty) {
        selectedMonth = availableMonths.first;
      }
      await _fetchData();
    } catch (e) {
      error = 'Could not load data: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchData() async {
    // Load summary and transactions in parallel
    final results = await Future.wait([
      _api.getSummary(month: selectedMonth),
      _api.getTransactions(
        month: selectedMonth,
        category: selectedCategory,
        limit: 200,
      ),
    ]);
    summary = results[0] as SpendingSummary;
    final txData = results[1] as Map<String, dynamic>;
    transactions = ((txData['transactions'] as List?) ?? [])
        .map((e) => Transaction.fromJson(e))
        .toList();
  }

  Future<void> setMonth(String m) async {
    selectedMonth = m;
    await loadAll();
  }

  Future<void> setCategory(String? cat) async {
    selectedCategory = cat;
    isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getTransactions(
        month: selectedMonth,
        category: cat,
        limit: 200,
      );
      transactions = ((data['transactions'] as List?) ?? [])
          .map((e) => Transaction.fromJson(e))
          .toList();
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Upload CSV statement ───────────────────────────────────────────────────
  Future<void> uploadStatement(
    List<int> bytes,
    String filename, {
    String accountName = 'My Account',
  }) async {
    isUploading = true;
    uploadStatus = 'Parsing your CSV ...';
    error = null;
    notifyListeners();
    try {
      uploadStatus = 'Phi-4 Mini is categorising transactions (1–3 min) ...';
      notifyListeners();
      final result = await _api.uploadStatement(
        bytes,
        filename,
        accountName: accountName,
      );
      final count = result['transactions_imported'] as int? ?? 0;
      uploadStatus = 'Done! $count transactions imported and categorised.';
      await loadAll();
    } catch (e) {
      error = 'Upload failed: $e';
      uploadStatus = null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  // ── Manual CRUD — called from Flutter UI, AI has no access ─────────────────

  Future<void> addTransaction(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      await _api.addTransaction(data);
      await _fetchData();
    } catch (e) {
      error = 'Could not add transaction: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(int id, Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      await _api.updateTransaction(id, data);
      await _fetchData();
    } catch (e) {
      error = 'Could not update transaction: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      await _api.deleteTransaction(id);
      await _fetchData();
    } catch (e) {
      error = 'Could not delete transaction: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
