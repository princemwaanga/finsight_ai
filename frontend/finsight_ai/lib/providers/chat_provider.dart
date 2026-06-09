import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final String? sqlUsed; // the SQL Phi-4 generated (shown in chat bubble)

  const ChatMessage({required this.role, required this.content, this.sqlUsed});
}

class ChatProvider extends ChangeNotifier {
  final _api = ApiService();

  List<ChatMessage> messages = [];
  int? conversationId;
  bool isLoading = false;
  String? error;

  Future<void> send(String text) async {
    // Optimistic update: show user message immediately before waiting for AI
    messages = [...messages, ChatMessage(role: 'user', content: text)];
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _api.chat(
        message: text,
        conversationId: conversationId,
      );
      conversationId = data['conversation_id'] as int;
      messages = [
        ...messages,
        ChatMessage(
          role: 'assistant',
          content: data['response'] as String,
          sqlUsed: data['sql_used'] as String?,
        ),
      ];
    } catch (e) {
      error =
          'Cannot reach FinSight AI server.\n'
          'Make sure uvicorn is running on port 8000.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    messages = [];
    conversationId = null;
    error = null;
    notifyListeners();
  }
}
