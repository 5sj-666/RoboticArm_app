import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
// import 'package:robotic_arm_app/components/MotionNode.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

@RoutePage()
class OrderKeyframePage extends StatefulWidget {
  const OrderKeyframePage({super.key});

  @override
  State<OrderKeyframePage> createState() => _orderKeyframe();
}

// ignore: camel_case_types
class _orderKeyframe extends State<OrderKeyframePage> {
  final List<KeyframeWrapper> keyframeList = [];

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
        keyframeList.add(
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

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // print('保存动作');
          // print('保存动作${keyframeList.toJson()}');
          // keyframeList.forEach((a) {
          //   print(json.encode(a.toJson()));
          // });
          List<Keyframe> list = [];
          for (int i = 0; i < keyframeList.length; i++) {
            // print(json.encode(keyframeList[i].toJson()));
            // list.add(keyframeList[i].keyframe.toJson());
            list.add(keyframeList[i].keyframe);
          }
          // debugPrint('保存的动作: ${json.encode(list)}');
          var logger = Logger();
          Motion saveDate = Motion(
            id: '5id',
            name: '5名称',
            description: '5描述',
            children: list,
          );
          // logger.d('设计动作： $Motion');
          try {
            json.encode(saveDate.toJson());
          } catch (err) {
            logger.w('动作设计错误$err');
          }

          await SharedPrefsStorage.save(
            key: 'motion5',
            jsonValue: json.encode(saveDate.toJson()),
          );

          print('保存成功');
          final a = await SharedPrefsStorage.findByKeyPrefix('motion1');

          if (!mounted) return;

          // showDialog(
          //   context: context,
          //   builder: (BuildContext context) {
          //     return AlertDialog(
          //       title: Text('json数据'),
          //       content: Text(a['motion1']),
          //     );
          //   },
          // );

          // logger.d("Logger is working! $a");
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
            for (int index = 0; index < keyframeList.length; index += 1)
              Material(
                key: ValueKey<int>(keyframeList[index].order ?? index),
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
                    item: keyframeList[index].keyframe,
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
              final KeyframeWrapper item = keyframeList.removeAt(oldIndex);
              keyframeList.insert(newIndex, item);
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
