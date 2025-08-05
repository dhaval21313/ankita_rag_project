import 'package:flutter/material.dart';
import 'api_service.dart'; // Import the api_service.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1A1A1A), // Dark background like Grok
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF121212)),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          labelStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A90E2),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Ankita Physio Assistant')),
        body: QuestionScreen(),
      ),
    );
  }
}

class QuestionScreen extends StatefulWidget {
  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _conversation = []; // Store conversation history
  bool _isLoading = false; // Track loading state

  void _submitMessage() async {
    if (_isLoading || _controller.text.isEmpty) return; // Prevent empty submissions
    setState(() {
      _isLoading = true;
      _conversation.add({'role': 'user', 'text': _controller.text});
      _controller.clear(); // Clear input after sending
    });
    final result = await askQuestion(_conversation.last['text']);
    setState(() {
      _conversation.add({'role': 'assistant', 'text': result['answer'] ?? 'Error: ${result['error']}'});
      if (result['sources'] != null) {
        _conversation.addAll((result['sources'] as List)
            .map((s) => {'role': 'source', 'text': 'Source: ${s['source']}, Page: ${s['page']}'})
            .toList());
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._conversation.map((msg) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '${msg['role'] == 'user' ? 'You: ' : msg['role'] == 'assistant' ? 'Ankita: ' : 'Source: '} ${msg['text']}',
                  style: TextStyle(
                    fontSize: msg['role'] == 'assistant' ? 16 : 14,
                    fontWeight: msg['role'] == 'assistant' ? FontWeight.bold : FontWeight.normal,
                    color: msg['role'] == 'source' ? Colors.grey : null,
                  ),
                ),
              )),
              SizedBox(height: 10),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Type your message or reply',
                  hintText: 'e.g., Answer Anka\'s question',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitMessage,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text('Send'),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
