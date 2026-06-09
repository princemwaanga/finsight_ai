import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/category_bar.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data after the first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FinanceProvider>().loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.insights_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Text(
              'FinSight AI',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          // Month selector dropdown
          if (fp.availableMonths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DropdownButton<String>(
                value: fp.selectedMonth,
                underline: const SizedBox(),
                items: fp.availableMonths
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (m) {
                  if (m != null) fp.setMonth(m);
                },
              ),
            ),
        ],
      ),
      body: fp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fp.error != null
          ? Center(
              child: Text(fp.error!, style: TextStyle(color: cs.error)),
            )
          : fp.summary == null
          ? _buildEmpty(context)
          : _buildContent(context, fp),
    );
  }

  Widget _buildEmpty(BuildContext ctx) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.upload_file_rounded,
          size: 72,
          color: Theme.of(ctx).colorScheme.primary.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          'No data yet.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Go to Transactions and upload\nyour bank statement CSV.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildContent(BuildContext ctx, FinanceProvider fp) {
    final s = fp.summary!;
    return RefreshIndicator(
      onRefresh: () => fp.loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Income / Expenses / Saved cards ─────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Income',
                amount: s.totalIncome,
                color: Colors.green.shade600,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Expenses',
                amount: s.totalExpenses,
                color: Colors.red.shade600,
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Saved',
                amount: s.net,
                color: s.net >= 0
                    ? Colors.blue.shade600
                    : Colors.orange.shade700,
                icon: Icons.savings_rounded,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Savings rate progress bar ────────────────────────────────────
          if (s.totalIncome > 0) ...[
            Text(
              'Savings Rate',
              style: Theme.of(
                ctx,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (s.savingsRate / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                // Green if saving > 20% of income (recommended benchmark)
                color: s.savingsRate >= 20 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.savingsRate.toStringAsFixed(1)}% of income saved',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
          ],

          // ── Category breakdown bars ──────────────────────────────────────
          Text(
            'Spending by Category',
            style: Theme.of(
              ctx,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          CategoryBar(data: s.spendingByCategory, total: s.totalExpenses),

          const SizedBox(height: 20),

          // ── Largest expenses ─────────────────────────────────────────────
          if (s.topExpenses.isNotEmpty) ...[
            Text(
              'Largest Expenses',
              style: Theme.of(
                ctx,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...s.topExpenses.map((t) => TransactionTile(tx: t)),
          ],
        ],
      ),
    );
  }
}

// Small stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
