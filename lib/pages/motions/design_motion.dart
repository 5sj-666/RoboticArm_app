import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:robotic_arm_app/components/MotionNode.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
// import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';

var logger = Logger();

@RoutePage()
class OrderKeyframePage extends StatefulWidget {
  const OrderKeyframePage({super.key});

  @override
  State<OrderKeyframePage> createState() => _orderKeyframe();
}

// ignore: camel_case_types
class _orderKeyframe extends State<OrderKeyframePage> {
  final List<KeyframeWrapper> keyframeWrapperList = [];

  @override
  void initState() {
    super.initState();
    print('designMotion initState');
    initKeyframeList();
  }

  void initKeyframeList() async {
    print('---initKeyframeList');
    final result = await SharedPrefsStorage.findByKeyPrefix('keyframe');

    int i = 0;
    result.forEach((key, value) {
      setState(() {
        keyframeWrapperList.add(
          KeyframeWrapper(
            order: i,
            keyframe: Keyframe.fromJson(json.decode(value)),
          ),
        );
      });
      i++;
    });

    // SharedPrefsStorage.readJson

    print('---initKeyframeList end');
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
            keyframeWrapperList: keyframeWrapperList,
            motionsCubit: motionsCubit,
          );
        },
        child: Icon(Icons.save),
        // child: Text('保存动作'),
      ),
      appBar: AppBar(title: Text('动作设计')),
      body: Container(
        // width: 360,
        // height: double.infinity,
        decoration: BoxDecoration(
          // color: Colors.green,
          border: Border.all(width: 1, color: Colors.blue.shade200),
        ),
        child: ReorderableListView(
          // padding: const EdgeInsets.symmetric(horizontal: 40),
          children: <Widget>[
            for (int index = 0; index < keyframeWrapperList.length; index += 1)
              Material(
                key: ValueKey<int>(keyframeWrapperList[index].order ?? index),
                color: Colors.transparent,
                child: ListTile(
                  // tileColor: (keyframeList[index].order ?? index).isOdd
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
                    item: keyframeWrapperList[index].keyframe,
                    index: index,
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
              final KeyframeWrapper item = keyframeWrapperList.removeAt(
                oldIndex,
              );
              keyframeWrapperList.insert(newIndex, item);
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

  MotionItemCard({super.key, this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1, color: Colors.green.shade500),
        borderRadius: BorderRadius.circular(8),
      ),
      // child: Text('ceshi ${keyframeList[index].order}')),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(width: 10),
          SizedBox(width: 20, child: Text('${index + 1}')),
          SizedBox(
            width: 100,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '时间',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.only(left: 10),
              // height: double.infinity,
              // decoration: BoxDecoration(
              //   border: Border.all(
              //       width: 1, color: Colors.black54),
              // ),
              child: Text((item?.name ?? '').replaceFirst('keyframe_', '')),
            ),
          ),
        ],
      ),
    );
  }
}

// keyframe包裹器， 增加一个order排序
class KeyframeWrapper {
  int? order;
  Keyframe keyframe;

  KeyframeWrapper({this.order, required this.keyframe});

  Map<String, dynamic> toJson() => {'order': order, 'kyframe': keyframe};
}

Future<void> saveDialog({
  required BuildContext context,
  required List<KeyframeWrapper> keyframeWrapperList,
  required MotionsCubit motionsCubit,
  // required JointsCubit jointsCubit,
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
              List<Keyframe> keyframeList = [];
              for (int i = 0; i < keyframeWrapperList.length; i++) {
                keyframeList.add(keyframeWrapperList[i].keyframe);
              }

              Motion saveData = Motion(
                id: '${DateTime.now()}',
                name: saveName,
                createTime: DateFormat(
                  'yyyy-MM-dd HH-mm-ss',
                ).format(DateTime.now()),
                description: description,
                children: keyframeList,
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
