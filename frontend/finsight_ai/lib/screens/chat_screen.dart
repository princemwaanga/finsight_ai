import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'How much did I spend last month?',
    'What is my biggest spending category?',
    'Show my top 5 largest expenses',
    'How much did I spend on food?',
    'What was my total income this month?',
    'How many transport transactions do I have?',
  ];

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? preset]) {
    final t = (preset ?? _ctrl.text).trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    context.read<ChatProvider>().send(t);
    _scrollBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    if (chat.messages.isNotEmpty) _scrollBottom();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask FinSight',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Powered by Phi-4 Mini',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New conversation',
            onPressed: () => context.read<ChatProvider>().clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chat.error != null)
            Container(
              width: double.infinity,
              color: AppTheme.dangerSoft,
              padding: const EdgeInsets.all(10),
              child: Text(
                chat.error!,
                style: const TextStyle(color: AppTheme.danger, fontSize: 13),
              ),
            ),

          Expanded(
            child: chat.messages.isEmpty
                ? _buildSuggestions()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == chat.messages.length) return _buildTyping();
                      return _buildBubble(chat.messages[i]);
                    },
                  ),
          ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.subtle)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Ask about your spending...',
                        filled: true,
                        fillColor: AppTheme.bg,
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.radiusXxl,
                          borderSide: BorderSide(color: AppTheme.subtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppTheme.radiusXxl,
                          borderSide: BorderSide(color: AppTheme.subtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppTheme.radiusXxl,
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: chat.isLoading ? null : () => _send(),
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      backgroundColor: AppTheme.primary,
                    ),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 12),
      Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: AppTheme.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 32,
            color: AppTheme.primary,
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Center(
        child: Text(
          'Ask anything about your finances',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Center(
        child: Text(
          'Phi-4 Mini turns questions into SQL automatically',
          style: TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
      ),
      const SizedBox(height: 24),
      ..._suggestions.map(
        (s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => _send(s),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              side: BorderSide(color: AppTheme.subtle),
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
            ),
            child: Text(
              s,
              style: const TextStyle(fontSize: 13, color: AppTheme.ink),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: AppTheme.subtleShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isUser
                ? Text(
                    msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: msg.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.ink,
                        height: 1.5,
                      ),
                      code: const TextStyle(
                        backgroundColor: AppTheme.bg,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
            if (msg.sqlUsed != null) ...[
              const SizedBox(height: 10),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  title: Row(
                    children: [
                      const Icon(
                        Icons.code_rounded,
                        size: 13,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'SQL used',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: AppTheme.radiusMd,
                      ),
                      child: SelectableText(
                        msg.sqlUsed!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Thinking...',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );
}
