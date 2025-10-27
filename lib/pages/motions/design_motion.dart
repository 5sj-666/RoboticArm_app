import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
// import 'package:robotic_arm_app/components/MotionNode.dart';
import 'package:robotic_arm_app/types/motions.dart';

@RoutePage()
class OrderKeyframePage extends StatefulWidget {
  const OrderKeyframePage({super.key});

  @override
  State<OrderKeyframePage> createState() => _orderKeyframe();
}

class KeyFrameItem {
  final int order;
  final Keyframe keyframe;

  KeyFrameItem({required this.order, required this.keyframe});
}

// ignore: camel_case_types
class _orderKeyframe extends State<OrderKeyframePage> {
  final List<KeyFrameItem> keyFrameItems = [
    KeyFrameItem(
        order: 300,
        keyframe:
            Keyframe(title: '关键帧1', name: 'joint1', motorId: 21, keyframe: [])),
    KeyFrameItem(
        order: 1112,
        keyframe:
            Keyframe(title: '关键帧2', name: 'joint1', motorId: 21, keyframe: [])),
    KeyFrameItem(
        order: 2221,
        keyframe:
            Keyframe(title: '关键帧3', name: 'joint1', motorId: 21, keyframe: [])),
  ];

  @override
  void initState() {
    super.initState();

    print('designMotion initState');
  }

  @override
  Widget build(BuildContext context) {
    final Color oddItemColor = Colors.grey.shade200;
    final Color evenItemColor = Colors.green.shade100;

    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('添加关键帧');
          },
          child: Icon(Icons.save),
        ),
        appBar: AppBar(
          title: Text('动作设计'),
        ),
        body: Container(
          // width: 360,
          // height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green,
            border: Border.all(width: 1, color: Colors.blue.shade200),
          ),
          child: ReorderableListView(
            // padding: const EdgeInsets.symmetric(horizontal: 40),
            children: <Widget>[
              for (int index = 0; index < keyFrameItems.length; index += 1)
                Material(
                  key: ValueKey<int>(keyFrameItems[index].order),
                  color: Colors.transparent,
                  child: ListTile(
                      tileColor: keyFrameItems[index].order.isOdd
                          ? oddItemColor
                          : evenItemColor,
                      leading: ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            width: 30,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              border: Border.all(
                                  width: 1, color: Colors.blue.shade300),
                            ),
                            child: Icon(Icons.drag_handle),
                          )),
                      // title: Text('Item ${_items[index]}'),
                      title: MotionItemCard(
                          item: keyFrameItems[index], index: index)),
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
                final KeyFrameItem item = keyFrameItems.removeAt(oldIndex);
                keyFrameItems.insert(newIndex, item);
              });
            },
          ),
        ));
  }
}

class MotionItemCard extends StatelessWidget {
  final KeyFrameItem item;
  final int index;

  const MotionItemCard({super.key, required this.item, required this.index});

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
        // child: Text('ceshi ${keyFrameItems[index].order}')),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(width: 10),
            SizedBox(
              width: 20,
              child: Text('${index + 1}'),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '执行时间',
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
                    child: Text(item.keyframe.title))),
          ],
        ));
  }
}
