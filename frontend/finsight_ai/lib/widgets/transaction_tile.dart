import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard();
    if (!showActions) return card;

    return Dismissible(
      key: ValueKey('tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false; // parent handles confirm dialog
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: AppTheme.radiusLg,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: card,
    );
  }

  Widget _buildCard() {
    final catColor = AppTheme.catColor(tx.category);
    final amtColor = tx.isIncome ? AppTheme.success : AppTheme.danger;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.subtleShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_iconFor(tx.category), color: catColor, size: 20),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tx.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: catColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tx.date,
              style: const TextStyle(fontSize: 11, color: AppTheme.muted),
            ),
          ],
        ),
        trailing: SizedBox(
          width: showActions ? 100 : 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${tx.isIncome ? '+' : ''}${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amtColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              if (showActions) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String cat) => switch (cat) {
    'Food & Groceries' => Icons.local_grocery_store_rounded,
    'Transport' => Icons.directions_car_rounded,
    'Entertainment' => Icons.movie_rounded,
    'Utilities' => Icons.bolt_rounded,
    'Shopping' => Icons.shopping_bag_rounded,
    'Healthcare' => Icons.local_hospital_rounded,
    'Education' => Icons.school_rounded,
    'Income' => Icons.account_balance_wallet_rounded,
    'Rent & Housing' => Icons.home_rounded,
    _ => Icons.receipt_rounded,
  };
}
