import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://api.dreaminterpretation.ai';
  static const String _apiKey = 'your_api_key_here';

  static Future<String> interpretDream(String dreamText) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/interpret'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({'dream': dreamText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['interpretation'] ?? 'No interpretation available';
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  static Future<List<String>> getDreamThemes() async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/themes'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['themes']);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
}