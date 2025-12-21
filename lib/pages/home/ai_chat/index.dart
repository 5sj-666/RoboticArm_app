import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_google_generative_ai/genui_google_generative_ai.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'dart:async';
import './configuration.dart';
import './message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String _apiKey = dotenv.env['API_KEY'] ?? '';

class GenerativeAISample extends StatefulWidget {
  final String apiKey = _apiKey;
  final AiBackend aiBackend =
      AiBackend.googleGenerativeAi; // 或 AiBackend.firebase

  GenerativeAISample({super.key});

  @override
  State<GenerativeAISample> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<GenerativeAISample> {
  final TextEditingController _textController = TextEditingController();
  final List<MessageController> _messages = [];
  late final GenUiConversation _genUiConversation;
  late final A2uiMessageProcessor _a2uiMessageProcessor;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final Catalog catalog = CoreCatalogItems.asCatalog();
    _a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);

    const systemInstruction =
        '''You are a helpful assistant who chats with a user,
giving exactly one response for each user message.
Your responses should contain acknowledgment
of the user message.


IMPORTANT: When you generate UI in a response, you MUST always create
a new surface with a unique `surfaceId`. Do NOT reuse or update
existing `surfaceId`s. Each UI response must be in its own new surface.

${GenUiPromptFragments.basicChat}''';

    // Create the appropriate content generator based on configuration
    final ContentGenerator contentGenerator = switch (widget.aiBackend) {
      AiBackend.googleGenerativeAi => () {
        return GoogleGenerativeAiContentGenerator(
          catalog: catalog,
          systemInstruction: systemInstruction,
          apiKey: widget.apiKey,
        );
      }(),
      AiBackend.firebase => FirebaseAiContentGenerator(
        catalog: catalog,
        systemInstruction: systemInstruction,
      ),
    };

    _genUiConversation = GenUiConversation(
      a2uiMessageProcessor: _a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _handleSurfaceAdded,
      onTextResponse: _onTextResponse,
      onError: (error) {
        genUiLogger.severe(
          'Error from content generator',
          error.error,
          error.stackTrace,
        );
      },
    );
  }

  void _handleSurfaceAdded(SurfaceAdded surface) {
    if (!mounted) return;
    setState(() {
      _messages.add(MessageController(surfaceId: surface.surfaceId));
    });
    _scrollToBottom();
  }

  void _onTextResponse(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(MessageController(text: 'AI: $text'));
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final String text = _textController.text;
    if (text.isEmpty) {
      return;
    }
    _textController.clear();

    setState(() {
      _messages.add(MessageController(text: 'You: $text'));
    });

    _scrollToBottom();

    unawaited(_genUiConversation.sendRequest(UserMessage([TextPart(text)])));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final MessageController message = _messages[index];
              return ListTile(
                title: MessageView(message, _genUiConversation.host),
              );
            },
          ),
        ),

        ValueListenableBuilder(
          valueListenable: _genUiConversation.isProcessing,
          builder: (_, isProcessing, __) {
            if (!isProcessing) return Container();
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _genUiConversation.dispose();
    super.dispose();
  }
}
