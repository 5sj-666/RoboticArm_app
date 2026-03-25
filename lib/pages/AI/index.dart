import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:core';
// import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/pages/home_cubit.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/app_router.dart';
import 'package:auto_route/auto_route.dart';

import 'package:robotic_arm_app/utils/sharedPreferences.dart';

// final logger = Logger();

final String _apiKey = dotenv.env['API_KEY'] ?? '';

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({super.key});

  @override
  Widget build(BuildContext context) {
    // return ChatScreen(title: 'Gemini 2.5 Flash-Lite');

    return Scaffold(
      appBar: AppBar(title: const Text('gemini-2.5-flash')),
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
  // ignore: unused_field
  bool _loading = false;
  late MotionsCubit motionsCubit;
  // final homeCubit = BlocProvider.of<HomeCubit>(context);
  late HomeCubit homeCubit;

  @override
  @override
  void initState() {
    super.initState();
    try {
      motionsCubit = BlocProvider.of<MotionsCubit>(context);
      homeCubit = BlocProvider.of<HomeCubit>(context);

      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        // model: 'gemini-2.5-flash-lite',
        // model: 'gemma-3-12b',
        apiKey: widget.apiKey,
        systemInstruction: Content.text('''
          你是一个AI智能助手,在目前这个场景中,
          如果用户需要你生成机械臂动作(六轴机械臂,类似bba的GoFa™ CRB 15000),
          如果六个关节都处于0度位置时(即初始化位),机械臂是垂直向上的,
          你可以按照一下格式进行设计(注意输出给用户时是一个json数据):
          {
            id: String, // 动作唯一标识,当前时间的时间戳
            name: String, // 动作名称
            author: String, // 作者, 是ai生成的就填入gemini
            description: String, // 动作描述
            keyframes: [ // 关键帧列表,
                {
                    //注意: 时间要加上前一帧的时间,且第一帧的time必须是0.0,因为他是动作初始化的姿态。
                    //举个例子： 第一帧的time必须是0.0秒; 第二帧运行时间是1.3秒, 那么第二帧的time是(1.3 + 0.0)秒; 第三帧运行时间是2.2秒,那么它的time是(2.2 + 1.3)秒, 以此类推
                    time: double, 
                    // 六个关节位置, 所有关节的位置单位是度, 范围是-145度至145度(第二个关节的位置是-100度至100度), 例子[-30, -45,60,20,10,0]; 格外注意机械臂关机的可活动范围,不要生成的角度很小
                    // 第三个和第五个关节在现实安装中是反着装的,所以你生成动作的时候，需要将这个两个关节的角度取反, 也就是说如果你想让第三个关节转30度,你需要生成-30度; 如果你想让第五个关节转20度,你需要生成-20度。
                    positions: [], 
                    timingFunction: String, // 三次贝塞尔曲线: '控制点1.x, 控制点2.x, 控制点1.y, 控制点2.y' 示例: '.2,.3,.6,.9'
                },
                ...
            ]
          }
          请确保输出的json数据格式正确且完整,并且时间和位置数据合理。
          '''),
      );
      // 然后在回复中解释他的动作设计思路,动作适合什么场景使用。

      _chat = _model.startChat();
    } catch (e) {
      // _showError(e.toString());
    }

    ///  读取本地存储的历史对话
    SharedPrefsStorage.findByKeyPrefix("AI_").then((value) {
      print(r'$value');
      String? savedResponse = value['AI_response'];
      if (savedResponse != null) {
        print('---savedResponse: $savedResponse');

        setState(() {
          _generatedContent.add((
            image: null,
            text: savedResponse,
            fromUser: false,
          ));
        });
      }
    });
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
                      // print('--text: $content');
                      // logger.i(content);
                      return MessageWidget(
                        text: content.text,
                        image: content.image,
                        isFromUser: content.fromUser,
                        motionsCubit: motionsCubit,
                        homeCubit: homeCubit,
                        context: context,
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
                // IconButton(
                //   onPressed: !_loading
                //       ? () async {
                //           _sendImagePrompt(_textController.text);
                //         }
                //       : null,
                //   icon: Icon(
                //     Icons.image,
                //     color: _loading
                //         ? Theme.of(context).colorScheme.secondary
                //         : Theme.of(context).colorScheme.primary,
                //   ),
                // ),
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

  // Future<void> _sendImagePrompt(String message) async {
  //   setState(() {
  //     _loading = true;
  //   });
  //   try {
  //     ByteData catBytes = await rootBundle.load('assets/images/wallfall1.jpg');
  //     ByteData sconeBytes = await rootBundle.load(
  //       'assets/images/wallfall1.jpg',
  //     );
  //     final content = [
  //       Content.multi([
  //         TextPart(message),
  //         // The only accepted mime types are image/*.
  //         DataPart('image/jpeg', catBytes.buffer.asUint8List()),
  //         DataPart('image/jpeg', sconeBytes.buffer.asUint8List()),
  //       ]),
  //     ];
  //     _generatedContent.add((
  //       image: Image.asset("assets/images/wallfall1.jpg"),
  //       text: message,
  //       fromUser: true,
  //     ));
  //     _generatedContent.add((
  //       image: Image.asset("assets/images/wallfall1.jpg"),
  //       text: null,
  //       fromUser: true,
  //     ));

  //     var response = await _model.generateContent(content);
  //     var text = response.text;
  //     _generatedContent.add((image: null, text: text, fromUser: false));

  //     if (text == null) {
  //       _showError('No response from API.');
  //       return;
  //     } else {
  //       setState(() {
  //         _loading = false;
  //         _scrollDown();
  //       });
  //     }
  //   } catch (e) {
  //     _showError(e.toString());
  //     setState(() {
  //       _loading = false;
  //     });
  //   } finally {
  //     _textController.clear();
  //     setState(() {
  //       _loading = false;
  //     });
  //     _textFieldFocus.requestFocus();
  //   }
  // }

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

      if (text != null) {
        SharedPrefsStorage.save(key: 'AI_response', jsonValue: text);
      }
    }
  }

  // void _showError(String message) {
  //   showDialog<void>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Something went wrong'),
  //         content: SingleChildScrollView(child: SelectableText(message)),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('OK'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
    required this.motionsCubit,
    required this.homeCubit,
    required this.context,
  });

  final Image? image;
  final String? text;
  final bool isFromUser;
  final MotionsCubit motionsCubit;
  final HomeCubit homeCubit;
  final BuildContext context;
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
                // if (stringIsMotion(text ?? ''))
                if (_extractJson(text ?? '') != '')
                  FilledButton(
                    onPressed: () async {
                      try {
                        final motionJson = _extractJson(text ?? '');
                        print('motionJson: $motionJson');
                        final jsonMap = json.decode(motionJson);

                        Motion motion = Motion.fromJson(jsonMap);

                        // logger.i(
                        //   '--ai chat motion keyframe: ${motion.toJson()}',
                        // );

                        /// 将动作存储于本地
                        await SharedPrefsStorage.save(
                          key: 'motion_${motion.name}',
                          jsonValue: motionJson,
                        );
                        bool result = motionsCubit.setCurMotion(motion);
                        // logger.i('--ai chat motion: ${motion.keyframes}');
                        motionsCubit.state.currentMotion;
                        motionsCubit.updateStatus(MotionStatus.prepare);
                        if (result) {
                          homeCubit.setIndex(1);
                          if (context.mounted) {
                            AutoRouter.of(context).popUntil(
                              (route) => route.settings.name == HomeRoute.name,
                            );
                          }
                        }
                      } catch (e) {
                        e;
                        SnackBar snackBar = SnackBar(
                          content: Text('Error reading saved motion: $e'),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      }
                    },
                    child: Text('预览动作'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 核心方法：提取并解析JSON
String _extractJson(String rawText) {
  // // 步骤1：清理日志前缀（去掉"flutter: │ 💡 "这类标识）
  // String cleanedText = rawText.replaceAll(RegExp(r'flutter: │ 💡\s*'), '');

  // 步骤2：匹配```json和```之间的内容
  RegExp jsonRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
  Match? match = jsonRegex.firstMatch(rawText);

  if (match != null && match.groupCount >= 1) {
    // String jsonString = match.group(0)!.trim().replaceAll('json', '');
    String jsonString = match.group(1)!.trim();
    // return escapeSpecialChars(jsonString);
    return jsonString;
    // 步骤3：解析JSON字符串为Map
  } else {
    print('未找到JSON代码块');
  }

  return '';
}

String escapeSpecialChars(String input) {
  return input
      .replaceAll('\\', '\\\\') // 转义反斜杠
      .replaceAll('\n', '\\n') // 转义换行
      .replaceAll('\r', '\\r') // 转义回车
      .replaceAll('\t', '\\t') // 转义制表符
      .replaceAll('"', '\\"'); // 转义双引号
}
