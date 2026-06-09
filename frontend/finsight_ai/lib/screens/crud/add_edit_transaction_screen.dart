// AI has NO access to this screen or its API routes.
// It writes directly to POST /transactions/manual or PUT /transactions/{id}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/transaction.dart';
import '../../theme/app_theme.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? tx;
  const AddEditTransactionScreen({super.key, this.tx});
  @override
  State<AddEditTransactionScreen> createState() => _AddEditState();
}

class _AddEditState extends State<AddEditTransactionScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _desc, _amt, _bal, _date;
  String _cat = 'Other';
  bool _expense = true;
  bool _saving = false;

  static const _cats = [
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

  bool get _isEdit => widget.tx != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tx;
    _desc = TextEditingController(text: t?.description ?? '');
    _amt = TextEditingController(
      text: t != null ? t.amount.abs().toStringAsFixed(2) : '',
    );
    _bal = TextEditingController(text: t?.balance?.toStringAsFixed(2) ?? '');
    _date = TextEditingController(
      text: t?.date ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _cat = t?.category ?? 'Other';
    _expense = t != null ? t.isExpense : true;
  }

  @override
  void dispose() {
    _desc.dispose();
    _amt.dispose();
    _bal.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bg,
    appBar: AppBar(
      title: Text(_isEdit ? 'Edit Transaction' : 'Add Transaction'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? 'Saving...' : 'Save',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Income / Expense toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.radiusLg,
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              children: [
                _ToggleBtn(
                  label: 'Expense',
                  active: _expense,
                  activeColor: AppTheme.danger,
                  icon: Icons.arrow_upward_rounded,
                  onTap: () => setState(() {
                    _expense = true;
                  }),
                ),
                _ToggleBtn(
                  label: 'Income',
                  active: !_expense,
                  activeColor: AppTheme.success,
                  icon: Icons.arrow_downward_rounded,
                  onTap: () => setState(() {
                    _expense = false;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _Label('Description'),
          TextFormField(
            controller: _desc,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. SHOPRITE LUSAKA'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Amount'),
                    TextFormField(
                      controller: _amt,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(hintText: '0.00'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Date'),
                    TextFormField(
                      controller: _date,
                      readOnly: true,
                      decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(_date.text) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (d != null) {
                          _date.text = d.toIso8601String().substring(0, 10);
                        }
                      },
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _Label('Category'),
          DropdownButtonFormField<String>(
            value: _cat,
            decoration: const InputDecoration(),
            items: _cats
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.catColor(c),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _cat = v ?? 'Other'),
          ),
          const SizedBox(height: 16),

          _Label('Balance after (optional)'),
          TextFormField(
            controller: _bal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0.00'),
          ),
          const SizedBox(height: 28),

          // AI separation note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: AppTheme.radiusMd,
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manual entries are stored directly — the AI assistant '
                    'cannot modify or delete this data.',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fp = context.read<FinanceProvider>();
      final amt = double.parse(_amt.text.trim());
      final finalAmt = _expense ? -amt.abs() : amt.abs();
      final payload = {
        'description': _desc.text.trim(),
        'amount': finalAmt,
        'category': _cat,
        'date': _date.text.trim(),
        'balance': _bal.text.isEmpty ? 0.0 : double.tryParse(_bal.text) ?? 0.0,
        'account_name': 'Manual Entry',
      };
      if (_isEdit) {
        await fp.updateTransaction(widget.tx!.id, payload);
      } else {
        await fp.addTransaction(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
      ),
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: AppTheme.radiusLg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? activeColor : AppTheme.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active ? activeColor : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
