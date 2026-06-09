import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import 'upload_screen.dart';
import 'crud/add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  bool _fabOpen = false;

  static const _cats = [
    'All',
    'Food & Groceries',
    'Transport',
    'Entertainment',
    'Utilities',
    'Shopping',
    'Healthcare',
    'Education',
    'Income',
    'Rent & Housing',
    'Other',
  ];

  List<Transaction> _filtered(List<Transaction> txs) {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return txs;
    return txs
        .where(
          (t) =>
              t.description.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final txs = _filtered(fp.transactions);

    return GestureDetector(
      onTap: () {
        if (_fabOpen) setState(() => _fabOpen = false);
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text('Transactions'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: fp.loadAll,
            ),
          ],
        ),
        floatingActionButton: _SpeedDial(
          open: _fabOpen,
          onToggle: () => setState(() => _fabOpen = !_fabOpen),
          onUpload: () {
            setState(() => _fabOpen = false);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadScreen()),
            );
          },
          onAdd: () {
            setState(() => _fabOpen = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditTransactionScreen(),
              ),
            );
          },
        ),
        body: Column(
          children: [
            if (fp.uploadStatus != null)
              _StatusBanner(
                text: fp.uploadStatus!,
                bg: AppTheme.successSoft,
                fg: AppTheme.success,
              ),
            if (fp.error != null)
              _StatusBanner(
                text: fp.error!,
                bg: AppTheme.dangerSoft,
                fg: AppTheme.danger,
              ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppTheme.muted,
                  ),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: AppTheme.muted,
                          ),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Category chips
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final cat = _cats[i];
                  final sel = cat == 'All'
                      ? fp.selectedCategory == null
                      : fp.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: sel,
                      onSelected: (_) =>
                          fp.setCategory(cat == 'All' ? null : cat),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${txs.length} transaction${txs.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: fp.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : txs.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: txs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => TransactionTile(
                        tx: txs[i],
                        showActions: true,
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditTransactionScreen(tx: txs[i]),
                          ),
                        ),
                        onDelete: () => _confirmDelete(context, fp, txs[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.receipt_long_rounded,
          size: 56,
          color: AppTheme.muted.withValues(alpha: .35),
        ),
        const SizedBox(height: 12),
        const Text(
          'No transactions found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload a CSV or add one manually',
          style: TextStyle(fontSize: 13, color: AppTheme.muted),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(
    BuildContext ctx,
    FinanceProvider fp,
    Transaction tx,
  ) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXl),
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.description}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) await fp.deleteTransaction(tx.id);
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _StatusBanner({required this.text, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: bg,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}

class _SpeedDial extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle, onUpload, onAdd;
  const _SpeedDial({
    required this.open,
    required this.onToggle,
    required this.onUpload,
    required this.onAdd,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (open) ...[
        _DialItem(
          label: 'Import CSV',
          icon: Icons.upload_file_rounded,
          color: AppTheme.success,
          onTap: onUpload,
        ),
        const SizedBox(height: 10),
        _DialItem(
          label: 'Add Manually',
          icon: Icons.edit_note_rounded,
          color: AppTheme.primary,
          onTap: onAdd,
        ),
        const SizedBox(height: 14),
      ],
      FloatingActionButton(
        onPressed: onToggle,
        child: AnimatedRotation(
          turns: open ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    ],
  );
}

class _DialItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DialItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.radiusMd,
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
      ),
      const SizedBox(width: 10),
      FloatingActionButton.small(
        heroTag: label,
        onPressed: onTap,
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Icon(icon, size: 20),
      ),
    ],
  );
}
