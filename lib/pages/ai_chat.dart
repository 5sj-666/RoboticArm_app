import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiChatPage extends StatefulWidget {
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // 替换为你的 Gemini API Key
  final String _apiKey = '';

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': input});
      _isLoading = true;
      _controller.clear();
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', // 或 'gemini-1.0-pro'
        apiKey: _apiKey,
      );
      final content = [Content.text(input)];
      final response = await model.generateContent(content);

      setState(() {
        _messages.add({'role': 'ai', 'content': response.text ?? '无回复'});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': '出错了: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI 聊天')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Row(
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: '输入你的问题...',
                    border: OutlineInputBorder(),
                  ),
                ),
              )),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
