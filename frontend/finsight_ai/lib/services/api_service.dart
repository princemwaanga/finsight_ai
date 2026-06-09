import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class ApiService {
  // Override at build time: flutter run --dart-define=API_URL=http://192.168.x.x:8000
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.179:8000',
  );

  // Reuse a single HTTP client — avoids creating a new TCP connection per request
  static final _client = http.Client();

  // ── Statement upload ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadStatement(
    List<int> bytes,
    String filename, {
    String accountName = 'My Account',
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/statements/upload'
        '?account_name=${Uri.encodeComponent(accountName)}',
      ),
    );
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    // 10-minute timeout: categorising 200 transactions takes ~2-3 min on CPU
    final streamed = await req.send().timeout(const Duration(minutes: 10));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      final err = jsonDecode(body);
      throw Exception(
        err['detail'] ?? 'Upload failed (${streamed.statusCode})',
      );
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ── Transactions ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTransactions({
    String? category,
    String? month,
    int limit = 100,
  }) async {
    final uri = Uri.parse('$baseUrl/transactions').replace(
      queryParameters: {
        if (category != null) 'category': category,
        if (month != null) 'month': month,
        'limit': '$limit',
      },
    );
    final resp = await _client.get(uri).timeout(const Duration(seconds: 15));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<SpendingSummary> getSummary({String? month}) async {
    final uri = Uri.parse(
      '$baseUrl/transactions/summary',
    ).replace(queryParameters: {if (month != null) 'month': month});
    final resp = await _client.get(uri).timeout(const Duration(seconds: 15));
    return SpendingSummary.fromJson(jsonDecode(resp.body));
  }

  Future<List<String>> getMonths() async {
    final resp = await _client
        .get(Uri.parse('$baseUrl/transactions/months'))
        .timeout(const Duration(seconds: 10));
    return (jsonDecode(resp.body) as List).cast<String>();
  }

  // ── Chat ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> chat({
    required String message,
    int? conversationId,
  }) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            if (conversationId != null) 'conversation_id': conversationId,
          }),
        )
        .timeout(const Duration(minutes: 3)); // 3 min: SQL gen + inference
    if (resp.statusCode != 200) {
      throw Exception('Chat error ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ── Insights ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateInsights({String? month}) async {
    final uri = Uri.parse(
      '$baseUrl/insights/generate',
    ).replace(queryParameters: {if (month != null) 'month': month});
    final resp = await _client.post(uri).timeout(const Duration(minutes: 3));
    if (resp.statusCode != 200) {
      throw Exception('Insights error ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<bool> isAlive() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── CRUD — direct DB writes, no AI involvement ─────────────────────────────

  Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> data) async {
    final resp = await _client
        .post(
          Uri.parse('$baseUrl/transactions/manual'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception(resp.body);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTransaction(
    int id,
    Map<String, dynamic> data,
  ) async {
    final resp = await _client
        .put(
          Uri.parse('$baseUrl/transactions/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception(resp.body);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<void> deleteTransaction(int id) async {
    final resp = await _client
        .delete(Uri.parse('$baseUrl/transactions/$id'))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception(resp.body);
  }
}
