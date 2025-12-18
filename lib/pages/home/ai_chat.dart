import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _apiKey = dotenv.env['API_KEY'] ?? '';

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({super.key});

  @override
  Widget build(BuildContext context) {
    // return ChatScreen(title: 'Gemini 2.5 Flash-Lite');
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini 2.5 Flash-Lite')),
      body: ChatWidget(apiKey: _apiKey),
    );
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({required this.apiKey, super.key});

  final String apiKey;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({Image? image, String? text, bool fromUser})> _generatedContent =
      <({Image? image, String? text, bool fromUser})>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: widget.apiKey,
      );
      _chat = _model.startChat();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ListView 或其他可滚动组件滚动到底部
  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: '请输入',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: Colors.blue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: Colors.blue.shade100), // 未聚焦时的边框颜色
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        borderSide: BorderSide(color: Colors.red.shade100),
      ),
    );

    return GestureDetector(
      onTap: () {
        _textFieldFocus.unfocus(); // 点击空白处取消焦点
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _apiKey.isNotEmpty
                ? ListView.builder(
                    controller: _scrollController,
                    itemBuilder: (context, idx) {
                      final content = _generatedContent[idx];
                      return MessageWidget(
                        text: content.text,
                        image: content.image,
                        isFromUser: content.fromUser,
                      );
                    },
                    itemCount: _generatedContent.length,
                  )
                : ListView(
                    children: const [
                      Text(
                        'No API key found. Please provide an API Key using '
                        "'--dart-define' to set the 'API_KEY' declaration.",
                      ),
                    ],
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // 背景色
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .02), // 阴影颜色
                  spreadRadius: 1, // 阴影扩散半径
                  blurRadius: 2, // 阴影模糊半径
                  offset: Offset(0, -1), // 阴影向上的偏移量
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: false,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                const SizedBox.square(dimension: 15),
                IconButton(
                  onPressed: !_loading
                      ? () async {
                          _sendImagePrompt(_textController.text);
                        }
                      : null,
                  icon: Icon(
                    Icons.image,
                    color: _loading
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                // if (!_loading)
                IconButton(
                  onPressed: () async {
                    _sendChatMessage(_textController.text);
                  },
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                // else
                //   const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendImagePrompt(String message) async {
    setState(() {
      _loading = true;
    });
    try {
      ByteData catBytes = await rootBundle.load('assets/images/wallfall1.jpg');
      ByteData sconeBytes = await rootBundle.load(
        'assets/images/wallfall1.jpg',
      );
      final content = [
        Content.multi([
          TextPart(message),
          // The only accepted mime types are image/*.
          DataPart('image/jpeg', catBytes.buffer.asUint8List()),
          DataPart('image/jpeg', sconeBytes.buffer.asUint8List()),
        ]),
      ];
      _generatedContent.add((
        image: Image.asset("assets/images/wallfall1.jpg"),
        text: message,
        fromUser: true,
      ));
      _generatedContent.add((
        image: Image.asset("assets/images/wallfall1.jpg"),
        text: null,
        fromUser: true,
      ));

      var response = await _model.generateContent(content);
      var text = response.text;
      _generatedContent.add((image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
    });

    late String? text;

    try {
      _textController.clear();
      _generatedContent.add((image: null, text: message, fromUser: true));
      _generatedContent.add((
        image: null,
        text: null,
        fromUser: false,
      )); // 对方的loading
      _scrollDown();
      final response = await _chat.sendMessage(Content.text(message));
      text = response.text ?? 'No response from API';
    } on Exception catch (e) {
      // 捕获已知异常
      // _showError(e.toString());
      text = 'Error: ${e.toString()}';
    } catch (e) {
      // 捕获其他未知错误
      // _showError('未知错误: $e');
      text = '未知错误: $e';
    } finally {
      setState(() {
        _loading = false;
        _generatedContent.removeLast();
        _scrollDown();
      });
      _generatedContent.add((image: null, text: text, fromUser: false));
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(child: SelectableText(message)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
  });

  final Image? image;
  final String? text;
  final bool isFromUser;
  // Enum messageType = 'normal', 'image', 'text'

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isFromUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: isFromUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              // children: [
              //   if (text case final text?) MarkdownBody(data: text),
              //   if (image case final image?) image,
              // ],
              children: [
                if (text != null)
                  MarkdownBody(data: text!) // 显示文本内容
                else
                  Container(
                    width: 45,
                    height: 25,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: CircularProgressIndicator(), // 显示loading
                  ),
                if (image != null) image!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
