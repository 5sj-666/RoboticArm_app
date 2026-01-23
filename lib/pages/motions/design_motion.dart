import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
// import 'package:intl/intl.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/components/Bezier/Dialog.dart';
import 'package:robotic_arm_app/components/Bezier/Svg.dart';

var logger = Logger();

@RoutePage()
class OrderKeyframePage extends StatefulWidget {
  const OrderKeyframePage({super.key});

  @override
  State<OrderKeyframePage> createState() => _orderKeyframe();
}

// ignore: camel_case_types
class _orderKeyframe extends State<OrderKeyframePage> {
  final List<Keyframe> keyframeList = [];

  late final time = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('designMotion initState');
    initKeyframeList();
  }

  /// 初始化关键帧列表
  void initKeyframeList() async {
    final result = await SharedPrefsStorage.findByKeyPrefix('keyframe');

    result.forEach((key, value) {
      setState(() {
        final keyframe = Keyframe.fromJson(json.decode(value));
        if (keyframe.timingFunction == null || keyframe.timingFunction == '') {
          keyframe.timingFunction = '.1,.1,.9,.9';
        }
        keyframeList.add(keyframe);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Color oddItemColor = Colors.white10;
    final Color evenItemColor = Colors.blue.shade50;
    final motionsCubit = BlocProvider.of<MotionsCubit>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('保存动作');
          saveDialog(
            context: context,
            keyframeList: keyframeList,
            motionsCubit: motionsCubit,
          );
        },
        child: Icon(Icons.save),
      ),
      appBar: AppBar(title: Text('动作设计')),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: Colors.blue.shade200),
        ),
        child: ReorderableListView(
          children: <Widget>[
            for (int index = 0; index < keyframeList.length; index += 1)
              Material(
                key: ValueKey<int>(
                  int.parse(keyframeList[index].createTime ?? '0'),
                ),
                color: Colors.transparent,
                child: ListTile(
                  tileColor: index.isOdd ? oddItemColor : evenItemColor,
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      width: 30,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        border: Border.all(
                          width: 1,
                          color: Colors.blue.shade300,
                        ),
                      ),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                  // title: Text('Item ${_items[index]}'),
                  title: MotionItemCard(
                    item: keyframeList[index],
                    index: index,
                    showDelete: keyframeList.length > 2,
                    changeTimingFunc: (str) {
                      setState(() {
                        if (str != '') {
                          keyframeList[index].timingFunction = str;

                          // var keyframe = keyframeList[index];
                          // print('---keyframe name: ${keyframe.name}');
                          // // 保存至sharedPreferences
                          // final keyframeJson = json.encode(keyframe.toJson());
                          // SharedPrefsStorage.save(
                          //   key: 'keyframe_${keyframe.name}',
                          //   jsonValue: keyframeJson,
                          // );
                        }
                      });
                    },
                    removeTemporary: (index) {
                      print('removeTemporary$index');
                      setState(() {
                        keyframeList.removeAt(index);
                      });
                    },
                  ),
                ),
              ),
          ],
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
                return Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(6),
                  child: child,
                );
              },
          onReorder: (int oldIndex, int newIndex) {
            print('oldIndex: $oldIndex, newIndex: $newIndex');
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final Keyframe item = keyframeList.removeAt(oldIndex);
              keyframeList.insert(newIndex, item);
              keyframeList[0].time = 0.0; // 第一帧时间必须为0
            });
          },
        ),
      ),
    );
  }
}

class MotionItemCard extends StatelessWidget {
  final Keyframe? item;
  final int index;
  final ValueChanged<String>? changeTimingFunc;
  final ValueChanged<int>? removeTemporary;
  final bool showDelete;

  MotionItemCard({
    super.key,
    this.item,
    required this.index,
    this.changeTimingFunc,
    this.removeTemporary,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    // print('design_motion build: ${item?.timingFunction}');
    return Container(
      // width: 100,
      height: 130,
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1, color: Colors.green.shade500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(width: 20, child: Text('${index + 1}')),
              SizedBox(
                width: 100,
                child: TextField(
                  enabled: index != 0,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ), // 弹出数字键盘
                  inputFormatters: [
                    // FilteringTextInputFormatter.digitsOnly, // 仅允许数字
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
                  ],
                  controller: TextEditingController(
                    text: item?.time.toString(),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '时间/s',
                  ),
                  onChanged: (value) {
                    // print('输入');
                    // var num = double.tryParse(value);
                    item!.time = double.tryParse(value) ?? -1.0;
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Text((item?.name ?? '').replaceFirst('keyframe_', '')),
                ),
              ),
              InkWell(
                onTap: () async {
                  final dynamic customTimingFunc = await showDialog(
                    context: context,
                    builder: (context) => SetBezier(
                      initTimingFunc: item?.timingFunction ?? 'linear',
                    ),
                  );
                  // final String a = await dialogSetBezier(context: context);
                  // print('获取到的缓动函数 : $customTimingFunc');
                  if (customTimingFunc != null) {
                    item?.timingFunction = customTimingFunc;

                    try {
                      changeTimingFunc!(customTimingFunc);
                    } catch (error) {
                      print(error);
                    }
                  }
                },
                child: SvgCubicBezier(
                  timingFunc: item?.timingFunction ?? 'ease-in',
                  bg: Colors.white70,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text('缓动函数${item?.timingFunction}'),
              SizedBox(width: 1),
              SizedBox(
                child: showDelete
                    ? FilledButton(
                        onPressed: () {
                          if (removeTemporary != null) {
                            removeTemporary!(index);
                          }
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            EdgeInsetsGeometry.zero,
                          ),
                          minimumSize: WidgetStateProperty.all<Size>(
                            Size(40, 25),
                          ),
                        ),
                        child: Icon(Icons.delete),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> saveDialog({
  required BuildContext context,
  required List<Keyframe> keyframeList,
  required MotionsCubit motionsCubit,
}) async {
  final _keyframeNameCtrl = TextEditingController();
  final _keyframeDescriptCtrl = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('动作名称', style: TextStyle(fontSize: 18)),
        content: SizedBox(
          height: 200,
          child: Column(
            children: [
              TextField(controller: _keyframeNameCtrl, autofocus: true),
              TextField(
                controller: _keyframeDescriptCtrl,
                autofocus: true,
                maxLines: 2,
                maxLength: 30,
              ),
            ],
          ),
        ),

        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              //获取用户输入的saveName
              final saveName = _keyframeNameCtrl.text;
              final description = _keyframeDescriptCtrl.text;

              print('saveName: $saveName  description: $description');

              // 构造motion类型数据
              List<Keyframe> _keyframeList = [];
              for (int i = 0; i < keyframeList.length; i++) {
                // 第一帧的时间必须为0
                if (i == 0) {
                  keyframeList[i].time = 0;
                } else {
                  // 后续时间要加上前一帧的时间，之后就像一个时间尺
                  keyframeList[i].time += keyframeList[i - 1].time;
                }

                _keyframeList.add(keyframeList[i]);
              }

              Motion saveData = Motion(
                id: '${DateTime.now()}',
                name: saveName,
                createTime: DateTime.now().millisecondsSinceEpoch.toString(),
                description: description,
                keyframes: _keyframeList,
              );

              late SnackBar snackBar;
              // 存储在sharedPreferences
              try {
                await SharedPrefsStorage.save(
                  key: 'motion_$saveName',
                  jsonValue: json.encode(saveData.toJson()),
                );

                // 创建 SnackBar
                snackBar = SnackBar(
                  content: const Text("保存动作成功"), // 提示文本
                  duration: const Duration(seconds: 2), // 显示时长（默认 4 秒）
                  backgroundColor: Colors.green, // 背景色
                );
              } catch (err) {
                logger.w('动作设计错误$err');
              }

              if (context.mounted) {
                // 显示 SnackBar（需通过 ScaffoldMessenger）
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                motionsCubit.update();
                Navigator.of(context).pop();
              }
            },
            child: Text('确定'),
          ),
        ],
      );
    },
  );
}
