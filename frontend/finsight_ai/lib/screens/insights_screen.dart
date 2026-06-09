import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../services/api_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _api = ApiService();
  String? _content;
  bool    _loading = false;
  String? _error;

  Future<void> _generate(String? month) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.generateInsights(month: month);
      setState(() => _content = data['content'] as String);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Insights',
          style: TextStyle(fontWeight: FontWeight.w700))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : () => _generate(fp.selectedMonth),
              icon: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_loading
                  ? 'Phi-4 Mini is writing your report ...'
                  : 'Generate ${fp.selectedMonth ?? ''} Report'),
            ),
          ),

          if (_loading) ...[
            const SizedBox(height: 10),
            const Text(
              'Takes 20–40 seconds on CPU. '
              'The report is cached after the first generation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: TextStyle(
                      color: cs.onErrorContainer, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 16),

          // Report content area
          Expanded(
            child: _content == null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bar_chart_rounded, size: 64,
                           color: cs.primary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('No report yet.',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the button above to generate an\n'
                        'AI-powered monthly financial report.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ]),
                  )
                : Card(
                    elevation: 0,
                    color: cs.surfaceVariant.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Markdown(
                        data:    _content!,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}