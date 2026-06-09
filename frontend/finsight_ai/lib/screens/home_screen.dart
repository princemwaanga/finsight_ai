import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/finance_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FinanceProvider>().loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: fp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : fp.summary == null
          ? _buildEmpty()
          : _buildContent(fp),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.upload_file_rounded,
            size: 48,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No data yet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload a bank statement in Transactions',
          style: TextStyle(fontSize: 14, color: AppTheme.muted),
        ),
      ],
    ),
  );

  Widget _buildContent(FinanceProvider fp) {
    final s = fp.summary!;
    return RefreshIndicator(
      onRefresh: () => fp.loadAll(),
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          // Collapsible gradient header
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: AppTheme.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _GradientHeader(
                net: s.net,
                month: fp.selectedMonth ?? '',
              ),
            ),
            title: const Text('FinSight AI'),
            actions: [
              if (fp.availableMonths.isNotEmpty)
                _MonthDropdown(
                  months: fp.availableMonths,
                  selected: fp.selectedMonth,
                  onChanged: fp.setMonth,
                ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 3 stat cards
                _StatRow(s: s),
                const SizedBox(height: 16),

                // Savings rate bar
                if (s.totalIncome > 0) ...[
                  _SavingsBar(rate: s.savingsRate),
                  const SizedBox(height: 16),
                ],

                // Spending breakdown
                _SectionLabel(
                  title: 'Spending',
                  trailing: fp.selectedMonth ?? '',
                ),
                const SizedBox(height: 10),
                _SpendingCard(
                  data: s.spendingByCategory,
                  total: s.totalExpenses,
                ),
                const SizedBox(height: 16),

                // Inline AI Insights
                _InsightsCard(month: fp.selectedMonth),
                const SizedBox(height: 16),

                // Recent top expenses
                _SectionLabel(title: 'Largest Expenses', trailing: 'Top 5'),
                const SizedBox(height: 10),
                if (s.topExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No expenses this month',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ),
                ...s.topExpenses.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionTile(tx: t),
                  ),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-widgets

class _GradientHeader extends StatelessWidget {
  final double net;
  final String month;
  const _GradientHeader({required this.net, required this.month});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF06B6D4)],
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Net Savings',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${net >= 0 ? '+' : ''}${net.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: net >= 0 ? Colors.white : Colors.red[200],
              ),
            ),
            Text(
              month,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MonthDropdown extends StatelessWidget {
  final List<String> months;
  final String? selected;
  final void Function(String) onChanged;
  const _MonthDropdown({
    required this.months,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: selected,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppTheme.muted,
      ),
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.ink,
        fontWeight: FontWeight.w500,
      ),
      items: months
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (m) {
        if (m != null) onChanged(m);
      },
    ),
  );
}

class _StatRow extends StatelessWidget {
  final SpendingSummary s;
  const _StatRow({required this.s});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatTile(
        label: 'Income',
        amount: s.totalIncome,
        color: AppTheme.success,
        icon: Icons.arrow_downward_rounded,
      ),
      const SizedBox(width: 10),
      _StatTile(
        label: 'Expenses',
        amount: s.totalExpenses,
        color: AppTheme.danger,
        icon: Icons.arrow_upward_rounded,
      ),
      const SizedBox(width: 10),
      _StatTile(
        label: 'Saved',
        amount: s.net,
        color: s.net >= 0 ? AppTheme.primary : AppTheme.warning,
        icon: Icons.savings_rounded,
      ),
    ],
  );
}

class _StatTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            amount.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SavingsBar extends StatelessWidget {
  final double rate;
  const _SavingsBar({required this.rate});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: AppTheme.radiusLg,
      boxShadow: AppTheme.subtleShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Savings Rate',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const Spacer(),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rate >= 20 ? AppTheme.success : AppTheme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (rate / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.subtle,
            color: rate >= 20 ? AppTheme.success : AppTheme.warning,
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String title, trailing;
  const _SectionLabel({required this.title, required this.trailing});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(fontSize: 12, color: AppTheme.muted),
      ),
    ],
  );
}

class _SpendingCard extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  const _SpendingCard({required this.data, required this.total});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        children: data.entries.take(6).map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          final color = AppTheme.catColor(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      e.value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppTheme.subtle,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Inline AI Insights card on the Home screen
class _InsightsCard extends StatefulWidget {
  final String? month;
  const _InsightsCard({this.month});
  @override
  State<_InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<_InsightsCard> {
  final _api = ApiService();
  String? _content;
  bool _loading = false;
  bool _expanded = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _api.generateInsights(month: widget.month);
      setState(() {
        _content = d['content'] as String;
        _expanded = true;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
      ),
      borderRadius: AppTheme.radiusXl,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4F46E5).withValues(alpha: .28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Phi-4 Mini monthly analysis',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              if (_content != null)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white60,
                  ),
                ),
            ],
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        if (_content != null && _expanded)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: AppTheme.radiusLg,
            ),
            child: MarkdownBody(
              data: _content!,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
                h2: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        if (_content == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _generate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusMd,
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(_loading ? 'Generating...' : 'Generate Report'),
              ),
            ),
          ),
      ],
    ),
  );
}
