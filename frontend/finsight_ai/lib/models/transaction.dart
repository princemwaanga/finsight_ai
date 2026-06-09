class Transaction {
  final int id;
  final String date;
  final String description;
  final double amount;
  final String category;
  final double? balance;

  const Transaction({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    this.balance,
  });

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id: (j['id'] as int?) ?? 0, // ← was: j['id'] as int
    date: j['date'] as String,
    description: j['description'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] as String? ?? 'Other',
    balance: (j['balance'] as num?)?.toDouble(),
  );
}

class SpendingSummary {
  final double totalIncome;
  final double totalExpenses;
  final double net;
  final Map<String, double> spendingByCategory;
  final List<Transaction> topExpenses;

  const SpendingSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.net,
    required this.spendingByCategory,
    required this.topExpenses,
  });

  // What percentage of income was saved?
  double get savingsRate => totalIncome > 0 ? (net / totalIncome) * 100 : 0;

  factory SpendingSummary.fromJson(Map<String, dynamic> j) => SpendingSummary(
    totalIncome: (j['total_income'] as num).toDouble(),
    totalExpenses: (j['total_expenses'] as num).toDouble(),
    net: (j['net'] as num).toDouble(),
    spendingByCategory: (j['spending_by_category'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
    topExpenses: ((j['top_expenses'] as List?) ?? [])
        .map((e) => Transaction.fromJson(e))
        .toList(),
  );
}
