import 'package:flutter/material.dart';
import '../providers/finance_provider.dart';

class CategoryBar extends StatelessWidget {
  final Map<String, double> data;
  final double total;

  const CategoryBar({super.key, required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || total == 0) {
      return const Center(
        child: Text('No spending data', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: data.entries.map((entry) {
        final pct = entry.value / total;
        final color = Color(
          FinanceProvider.categoryColors[entry.key] ?? 0xFF9E9E9E,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Category name (fixed width so bars align)
              SizedBox(
                width: 130,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // The bar itself — grey background + coloured fill
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount (right-aligned)
              SizedBox(
                width: 72,
                child: Text(
                  entry.value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
