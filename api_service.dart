import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> askQuestion(String question) async {
  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/query'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get response: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
    return {'error': 'Could not connect to server'};
  }
}
