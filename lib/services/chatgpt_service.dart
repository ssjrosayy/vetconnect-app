import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPTService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey;

  ChatGPTService(this._apiKey);

  Future<String> getPetCareResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a knowledgeable pet care assistant. Provide helpful, accurate, '
                  'and concise information about pet care, but always remind users to consult '
                  'a veterinarian for specific medical advice. Focus on general pet care, '
                  'behavior, nutrition, and wellness topics.',
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error communicating with ChatGPT: $e');
    }
  }
}
