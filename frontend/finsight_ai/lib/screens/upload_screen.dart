import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _nameCtrl = TextEditingController(text: 'My Account');
  String? _filename;
  List<int>? _bytes;

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Import Statement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fp.uploadStatus != null) ...[
              _InfoTile(
                icon: Icons.check_circle_rounded,
                text: fp.uploadStatus!,
                bg: AppTheme.successSoft,
                fg: AppTheme.success,
              ),
              const SizedBox(height: 16),
            ],
            if (fp.error != null) ...[
              _InfoTile(
                icon: Icons.error_outline_rounded,
                text: fp.error!,
                bg: AppTheme.dangerSoft,
                fg: AppTheme.danger,
              ),
              const SizedBox(height: 16),
            ],

            // Supported formats
            _InfoTile(
              icon: Icons.info_outline_rounded,
              bg: AppTheme.primarySoft,
              fg: AppTheme.primary,
              text:
                  'Supported: Date/Description/Amount/Balance  '
                  'or  Date/Description/Debit/Credit/Balance',
            ),
            const SizedBox(height: 24),

            _FieldLabel('Account Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Zanaco Savings',
                prefixIcon: Icon(
                  Icons.account_balance_outlined,
                  size: 18,
                  color: AppTheme.muted,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _FieldLabel('CSV File'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: fp.isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.radiusLg,
                  border: Border.all(
                    color: _filename != null
                        ? AppTheme.primary
                        : AppTheme.subtle,
                    width: _filename != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _filename != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      size: 40,
                      color: _filename != null
                          ? AppTheme.primary
                          : AppTheme.muted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _filename ?? 'Tap to select CSV file',
                      style: TextStyle(
                        fontSize: 14,
                        color: _filename != null
                            ? AppTheme.primary
                            : AppTheme.muted,
                        fontWeight: _filename != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_filename == null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        '.csv files only',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress note
            if (fp.isUploading) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warningSoft,
                  borderRadius: AppTheme.radiusLg,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fp.uploadStatus ?? 'Processing...',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Phi-4 Mini categorises each row individually.\n'
                            '~1–3 minutes for a typical statement.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.warning,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (fp.isUploading || _bytes == null) ? null : _upload,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: fp.isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: Text(fp.isUploading ? 'Importing...' : 'Import'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (r == null || r.files.single.bytes == null) return;
    setState(() {
      _bytes = r.files.single.bytes!;
      _filename = r.files.single.name;
    });
  }

  Future<void> _upload() async {
    final name = _nameCtrl.text.trim();
    await context.read<FinanceProvider>().uploadStatement(
      _bytes!,
      _filename!,
      accountName: name.isEmpty ? 'My Account' : name,
    );
    if (mounted && context.read<FinanceProvider>().error == null) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg, fg;
  const _InfoTile({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: bg, borderRadius: AppTheme.radiusLg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: fg),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: fg, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.ink,
    ),
  );
}
