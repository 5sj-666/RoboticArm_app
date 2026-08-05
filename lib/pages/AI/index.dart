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

      // ## 机械臂物理运动学模型 (MDH 规范)
      // 本机械臂采用 Modified Denavit-Hartenberg (Craig 约定) 进行建模,拥有经典的拟人化结构与球形手腕。末端执行器 (TCP) 已精确定义。

      // **参数表 (单位: 米/度):**
      // | 连杆 (Link) | \$\\alpha_{i-1}\$ (扭转角) | \$a_{i-1}\$ (连杆长度) | \$d_i\$ (连杆偏距) | \$\theta_i\$ (关节角) |
      // | :--- | :--- | :--- | :--- | :--- |
      // | **Link 1 (Base)** | 0 | 0 | 0 | J1 |
      // | **Link 2 (Shoulder)**| 90 | 0 | 0 | J2 |
      // | **Link 3 (Upper Arm)**| 0 | 0.3 | 0 | J3 |
      // | **Link 4 (Forearm)** | -90 | 0 | 0.316 | J4 |
      // | **Link 5 (Wrist 1)** | 90 | 0 | 0 | J5 |
      // | **Link 6 (Wrist 2)** | -90 | 0 | 0 | J6 |

      // **工具中心点 (TCP / End Effector):**
      // - 沿 J6 (Link 6) 的 Z 轴正方向延伸 0.065 米。
      // - 所有的“末端指向”或“绘制轨迹”均以此 TCP 为绝对参考点。

      // **结构特性声明 (AI 逻辑参考):**
      // 1. J1 与 J2 轴线相交。
      // 2. J2 与 J3 轴线平行,构成主升降平面。
      // 3. J4, J5, J6 轴线交于一点,构成标准的球形手腕 (Spherical Wrist),姿态与位置解耦。

      //  - J1, J4, J6:数值增加 (+) -> 向右旋转；减少 (-) -> 向左旋转。
      // - J2, J3, J5:数值增加 (+) -> 往前趴/往下低头；减少 (-) -> 往后仰/往回缩。

      // 最后在回复中解释他的动作设计思路,动作适合什么场景使用。

      _model = GenerativeModel(
        // model: 'gemini-robotics-er-1.5-preview',
        model: 'gemini-2.5-flash',
        // model: 'gemini-2.5-flash-lite',
        // model: 'gemma-3-12b',
        apiKey: widget.apiKey,
        systemInstruction: Content.text('''
          # 角色:机械臂运动逻辑专家
          ## 核心任务
          将用户的交互意图转化为高精度的机械臂运动控制 JSON 数据。

          ## 物理与安全约束(核心准则)
          1. **角度硬限位**:所有关节(J1-J6)的有效运动范围严格限制在 [-145.0, 145.0] 度之间。绝对禁止生成超出此范围的数值。
          2. **坐标单位**:必须使用 角度(Degrees)。
          3. **关节极性方向**:
            遵循左手坐标系法,角度增加,关节往右转。
            J1: 基座关节:数值增加 (+) -> 向右旋转；减少 (-) -> 向左旋转。
            J2: 肩部关节:数值增加 (+) -> 向前趴；减少 (-) -> 向后仰。
            J3: 肘部关节:数值增加 (+) -> 向前趴；减少 (-) -> 向后仰。
            J4: 小臂关节:数值增加 (+) -> 往右旋转；减少 (-) -> 往左旋转。
            J5: 腕部关节:数值增加 (+) -> 往上；减少 (-) -> 往下。
            J6: 工具坐标系: 数值增加 (+) -> 往右旋转；减少 (-) -> 往左旋转。
           
          4. **初始姿态**:keyframes[0] 为动作起势,不需要保持全零位。

          ## 动画逻辑
          - **time**:是该帧动画的运行时间
          - **repeatCount**:若 keyframes[i] 的 repeatCount > 0,则在关键帧 i-1 和 i 之间往复执行该次数。
          - **平滑度**:默认 timingFunction 使用 "0.42, 0, 0.58, 1"。
          - **markerTimeStart**:保持为0.0
          - **markerTimeEnd**:保持为0.0

          ## JSON 输出规范
          仅返回标准 JSON 代码块。
          {
            "id": "String (时间戳)",
            "name": "String",
            "author": "gemini",
            "description": "String",
            "keyframes": [
              {
                "name": String, // 帧名字:  kf_ + 序号
                "time": double, 
                "positions": [J1, J2, J3, J4, J5, J6], 
                "timingFunction": "String", 
                "repeatCount": int, 
                "markerTimeStart": 0.0, 
                "markerTimeEnd": 0.0
              }
            ]
          }

   
          '''),
      );

      _chat = _model.startChat();
    } catch (e) {
      // _showError(e.toString());
    }

    ///  读取本地存储的历史对话
    SharedPrefsStorage.findByKeyPrefix("AI_").then((value) {
      print(r'$value');
      // String? savedResponse = value['AI_response'];
      String? savedResponse = '';
      // const String savedResponse =
      //     '```json{"id":"1712629308000","name":"Horizontal_Circle_Trace_Degrees","author":"gemini","description":"末端绕圆心(0.25,0.25,0.25)的水平圆轨迹,安全运行半径为0.05m。注意:positions 中的关节数据已转换为角度(Degrees),适配前端本地计算。","keyframes":[{"time":0,"positions":[39.76,54.55,-43.95,0,79.41,0],"timingFunction":"0.25, 0.1, 0.25, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":2,"positions":[50.19,54.55,-43.95,0,79.41,0],"timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":4,"positions":[51.34,73.68,-71.33,0,87.66,0],"timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":6,"positions":[38.68,73.68,-71.33,0,87.66,0],"timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":8,"positions":[39.76,54.55,-43.95,0,79.41,0],"timingFunction":"0.25, 0.1, 0.25, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0}]}```';
      // const String savedResponse =
      //     '```json{"id":"1712632947000","name":"Robot_Wave_Test","author":"gemini","description":"挥手动作测试:J2/J3抬起手臂,J4负责左右旋转挥动。验证 J4 增加向右、减少向左的逻辑。","keyframes":[{"time":0,"positions":[0,0,0,0,0,0],"timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":1.2,"positions":[0,45,80,0,-35,0],"description":"抬起手臂,手腕稍稍后仰准备挥手","timingFunction":"0.25, 0.1, 0.25, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":2,"positions":[0,45,80,-30,-35,0],"description":"向左挥动 (J4 减少)","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":2.8,"positions":[0,45,80,30,-35,0],"description":"向右挥动 (J4 增加)","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":3.6,"positions":[0,45,80,-30,-35,0],"description":"再次向左挥动","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":4.8,"positions":[0,0,0,0,0,0],"description":"动作结束,回到初始位","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0}]}```';

      // const String savedResponse =
      //     '```json{"id":"1712635589000","name":"Figure_Eight_Demo","author":"gemini","description":"垂直面 8 字轨迹测试。验证 J1(左右)与 J2/J3(上下)的联动协调性。采用 9 个关键帧实现平滑闭环。","keyframes":[{"time":0,"positions":[0,0,0,0,0,0],"timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":1.5,"positions":[0,35,70,0,-105,0],"description":"起始点:8 字中心","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":2.5,"positions":[-15,25,50,0,-75,0],"description":"左上环 (J1减少, J2/J3减少)","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":3.5,"positions":[-15,45,90,0,-135,0],"description":"左下环 (J1维持, J2/J3增加)","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":4.5,"positions":[0,35,70,0,-105,0],"description":"回到中心交汇点","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":5.5,"positions":[15,25,50,0,-75,0],"description":"右上环 (J1增加, J2/J3减少)","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":6.5,"positions":[15,45,90,0,-135,0],"description":"右下环 (J1维持, J2/J3增加)","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":7.5,"positions":[0,35,70,0,-105,0],"description":"回到中心完成 8 字","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":9,"positions":[0,0,0,0,0,0],"description":"归位","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0}]}```';
      // 画8字测试,笔尖正对屏幕
      // const String savedResponse =
      //     '```json{"id":"1712637100000","name":"Figure_Eight_Forward_Facing","author":"gemini","description":"修正版 8 字:通过调整 J5,使笔尖始终指向正前方(水平),适合在垂直平面演示。","keyframes":[{"time":0,"positions":[0,0,0,0,0,0],"timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":1.5,"positions":[0,35,70,0,-15,0],"description":"J2(35)+J3(70)+J5(-15) = 90, 笔尖水平指向前方","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":2.5,"positions":[-15,25,50,0,15,0],"description":"左上环,J5 自动补偿维持水平","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":4.5,"positions":[0,35,70,0,-15,0],"description":"中心交汇点","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":5.5,"positions":[15,25,50,0,15,0],"description":"右上环","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":7.5,"positions":[0,35,70,0,-15,0],"description":"完成 8 字","timingFunction":"0.0, 0.0, 1.0, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":9,"positions":[0,0,0,0,0,0],"timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0}]}```';

      // const String savedResponse =
      //     '```json{"id":"1712638500000","name":"Woodpecker_Test","author":"gemini","description":"测试 repeatCount 参数。J5 在抬起和落下之间重复执行,模拟敲门或啄木鸟动作。","keyframes":[{"time":0,"positions":[0,0,0,0,0,0],"timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":1.2,"positions":[0,40,60,0,-10,0],"description":"伸向前方,手腕微抬 (J5=-10) 预备","timingFunction":"0.25, 0.1, 0.25, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0},{"time":1.6,"positions":[0,40,60,0,30,0],"description":"快速向下敲击 (J5=30)。设置重复 5 次,应观察到连续敲击。","timingFunction":"0.42, 0, 0.58, 1","repeatCount":5,"markerTimeStart":0,"markerTimeEnd":0},{"time":3,"positions":[0,0,0,0,0,0],"description":"测试结束,平稳归位","timingFunction":"0.42, 0, 0.58, 1","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0}]}```';
      // final savedResponse = (image: null, text: motion, fromUser: true);
      // ignore: unnecessary_null_comparison
      // const String savedResponse =
      //     '```json{"id":"1712662400000","name":"快速大半径画圆测试-MDH校准版","author":"gemini","description":"半径0.3m,总历时3s。用于验证大幅度动作下的偏置补偿准确性。","keyframes":[{"time":0,"positions":[0,55,-110,0,55,0],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0.25},{"time":0.25,"positions":[18.5,53.8,-108.5,0,54.7,18.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":0.25,"markerTimeEnd":0.5},{"time":0.5,"positions":[32,48.5,-98.2,0,49.7,32],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":0.5,"markerTimeEnd":0.75},{"time":0.75,"positions":[38.2,40.2,-82.5,0,42.3,38.2],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":0.75,"markerTimeEnd":1},{"time":1,"positions":[32,31.8,-66.8,0,35,32],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":1,"markerTimeEnd":1.25},{"time":1.25,"positions":[18.5,26.5,-56.5,0,30,18.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":1.25,"markerTimeEnd":1.5},{"time":1.5,"positions":[0,24.5,-52,0,27.5,0],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":1.5,"markerTimeEnd":1.75},{"time":1.75,"positions":[-18.5,26.5,-56.5,0,30,-18.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":1.75,"markerTimeEnd":2},{"time":2,"positions":[-32,31.8,-66.8,0,35,-32],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":2,"markerTimeEnd":2.25},{"time":2.25,"positions":[-38.2,40.2,-82.5,0,42.3,-38.2],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":2.25,"markerTimeEnd":2.5},{"time":2.5,"positions":[-32,48.5,-98.2,0,49.7,-32],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":2.5,"markerTimeEnd":2.75},{"time":2.75,"positions":[-18.5,53.8,-108.5,0,54.7,-18.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":2.75,"markerTimeEnd":3},{"time":3,"positions":[0,55,-110,0,55,0],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":3,"markerTimeEnd":3}]}```';
      // '```json{"id":"1712662400000","name":"水平面画圆测试-MDH校准版","author":"gemini","description":"基于W=0.07偏置共轴模型生成。末端TCP在(0.4, 0, 0.1)处画半径0.1m的圆,保持垂直姿态。","keyframes":[{"time":0,"positions":[0,45,-85,0,40,0],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":0,"markerTimeEnd":0.5},{"time":0.5,"positions":[6.8,44.5,-84.2,0,39.7,6.8],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":0.5,"markerTimeEnd":1},{"time":1,"positions":[11.5,43.1,-81.8,0,38.7,11.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":1,"markerTimeEnd":1.5},{"time":1.5,"positions":[13.2,41.2,-78.5,0,37.3,13.2],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":1.5,"markerTimeEnd":2},{"time":2,"positions":[11.5,39.3,-75.2,0,35.9,11.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":2,"markerTimeEnd":2.5},{"time":2.5,"positions":[6.8,37.9,-72.8,0,34.9,6.8],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":2.5,"markerTimeEnd":3},{"time":3,"positions":[0,37.4,-72,0,34.6,0],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":3,"markerTimeEnd":3.5},{"time":3.5,"positions":[-6.8,37.9,-72.8,0,34.9,-6.8],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":3.5,"markerTimeEnd":4},{"time":4,"positions":[-11.5,39.3,-75.2,0,35.9,-11.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":4,"markerTimeEnd":4.5},{"time":4.5,"positions":[-13.2,41.2,-78.5,0,37.3,-13.2],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":4.5,"markerTimeEnd":5},{"time":5,"positions":[-11.5,43.1,-81.8,0,38.7,-11.5],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":5,"markerTimeEnd":5.5},{"time":5.5,"positions":[-6.8,44.5,-84.2,0,39.7,-6.8],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":5.5,"markerTimeEnd":6},{"time":6,"positions":[0,45,-85,0,40,0],"timingFunction":"0.42, 0.0, 0.58, 1.0","repeatCount":0,"markerTimeStart":6,"markerTimeEnd":6}]}```';
      // ignore: unnecessary_null_comparison
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

                        Motion parseMotion = Motion.fromJson(jsonMap);

                        Motion motion = computedKF(parseMotion);

                        // logger.i(
                        //   '--ai chat motion keyframe: ${motion.toJson()}',
                        // );

                        /// 将动作存储于本地
                        await SharedPrefsStorage.save(
                          key: 'motion_${motion.name}',
                          jsonValue: json.encode(motion.toJson()),
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

// 核心方法:提取并解析JSON
String _extractJson(String rawText) {
  // // 步骤1:清理日志前缀(去掉"flutter: │ 💡 "这类标识)
  // String cleanedText = rawText.replaceAll(RegExp(r'flutter: │ 💡\s*'), '');

  // 步骤2:匹配```json和```之间的内容
  RegExp jsonRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
  Match? match = jsonRegex.firstMatch(rawText);

  if (match != null && match.groupCount >= 1) {
    // String jsonString = match.group(0)!.trim().replaceAll('json', '');
    String jsonString = match.group(1)!.trim();
    // return escapeSpecialChars(jsonString);
    return jsonString;
    // 步骤3:解析JSON字符串为Map
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

/// 处理AI返回的动作
Motion computedKF(Motion motion) {
  final keyframeList = motion.keyframes;
  // 构造motion类型数据
  List<Keyframe> _keyframeList = [];
  for (int i = 0; i < keyframeList.length; i++) {
    // 第一帧的时间必须为0
    if (i == 0) {
      keyframeList[i].markerTimeStart = 0;
      keyframeList[i].markerTimeEnd = 0;
    } else {
      // 后续时间要加上前一帧的时间,之后就像一个时间尺
      // keyframeList[i].time += keyframeList[i - 1].time;
      /// 需要再加上 (重复次数的时间 x 2)。
      final repeatTime = keyframeList[i].repeatCount * keyframeList[i].time * 2;
      keyframeList[i].markerTimeEnd =
          keyframeList[i - 1].markerTimeEnd + repeatTime + keyframeList[i].time;
      keyframeList[i].markerTimeStart = keyframeList[i - 1].markerTimeEnd;
    }

    _keyframeList.add(keyframeList[i]);
  }
  motion.keyframes = _keyframeList;
  return motion;
}
