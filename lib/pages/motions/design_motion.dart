import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/cubit/keyframe_cubit.dart';
import 'package:draggable_float_widget/draggable_float_widget.dart';
import 'package:robotic_arm_app/components/KfCard.dart';

var logger = Logger();

@RoutePage()
class DesignMotionPage extends StatelessWidget {
  const DesignMotionPage({super.key});

  /// 进入页面生命周期

  @override
  Widget build(BuildContext context) {
    Color oddItemColor = Colors.white10;
    final Color evenItemColor = Colors.blue.shade50;
    KeyframeCubit kfCubit = BlocProvider.of<KeyframeCubit>(context);
    MotionsCubit motionsCubit = BlocProvider.of<MotionsCubit>(context);

    return BlocBuilder<KeyframeCubit, KeyframeState>(
      builder: (builderContext, kfState) {
        List<Keyframe> kfList = kfState.kfList;

        return GestureDetector(
          onTap: () {
            // 触摸空白处，收起键盘
            FocusScope.of(context).unfocus();
          },
          onLongPress: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            appBar: AppBar(title: Text('设计动作')),
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.blue.shade200),
                  ),
                  child: ReorderableListView(
                    children: <Widget>[
                      for (int index = 0; index < kfList.length; index += 1)
                        Material(
                          key: ValueKey<int>(
                            int.parse(kfList[index].createTime ?? '0'),
                          ),
                          color: Colors.transparent,
                          child: ListTile(
                            tileColor: index.isOdd
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
                                    width: 1,
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                            title: KfCard(
                              item: kfList[index],
                              index: index,
                              // showDelete: kfList.length > 2,
                              showDelete: true,
                              changeTimingFunc: (str) {
                                kfList[index].timingFunction = str;
                                kfCubit.update(kfList[index]);
                              },
                              changeRepeat: (value) {
                                kfList[index].repeatCount = value;
                                kfCubit.update(kfList[index]);
                              },
                              changeTime: (value) {
                                kfList[index].time = value;
                                kfCubit.update(kfList[index]);
                              },
                              softDel: (index) {
                                kfCubit.softDelete([index]);
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
                    onReorderStart: (idx) {
                      FocusScope.of(context).unfocus();
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      kfCubit.reorderItems(oldIndex, newIndex);
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 80,
                    child: Center(
                      child: SizedBox(
                        width: 0.7 * MediaQuery.of(context).size.width,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            saveDialog(
                              context: context,
                              keyframeList: kfList,
                              motionsCubit: motionsCubit,
                              kfCubit: kfCubit,
                            );
                          },
                          child: Text("保存"),
                        ),
                      ),
                    ),
                  ),
                ),
                DraggableFloatWidget(
                  config: DraggableFloatWidgetBaseConfig(
                    isFullScreen: false,
                    initPositionYInTop: false,
                    initPositionYMarginBorder: 50,
                  ),
                  onTap: () {},
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      iconSize: 28,
                    ),
                    onPressed: () {
                      keyframeHistoryDialog(
                        context: context,
                        keyframeList: kfList,
                        motionsCubit: motionsCubit,
                      );
                    },
                    icon: Icon(Icons.delete, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> saveDialog({
  required BuildContext context,
  required List<Keyframe> keyframeList,
  required MotionsCubit motionsCubit,
  required KeyframeCubit kfCubit,
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
                  keyframeList[i].markerTimeStart = 0;
                  keyframeList[i].markerTimeEnd = 0;
                } else {
                  // 后续时间要加上前一帧的时间，之后就像一个时间尺
                  // keyframeList[i].time += keyframeList[i - 1].time;
                  /// 需要再加上 （重复次数的时间 x 2）。
                  final repeatTime =
                      keyframeList[i].repeatCount * keyframeList[i].time * 2;
                  keyframeList[i].markerTimeEnd +=
                      keyframeList[i - 1].markerTimeEnd +
                      repeatTime +
                      keyframeList[i].time;
                  keyframeList[i].markerTimeStart =
                      keyframeList[i - 1].markerTimeEnd;
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
                motionsCubit.init();
                // 显示 SnackBar（需通过 ScaffoldMessenger）
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

Future<void> keyframeHistoryDialog({
  required BuildContext context,
  required List<Keyframe> keyframeList,
  required MotionsCubit motionsCubit,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      KeyframeCubit kfCubit = BlocProvider.of<KeyframeCubit>(context);

      return BlocBuilder<KeyframeCubit, KeyframeState>(
        builder: (builderContext, kfState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('过期关键帧', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭弹框
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: 0.8 * MediaQuery.of(context).size.width,
              height: 200,
              child: ListView.builder(
                itemCount: kfState.oldKfList.length,
                itemBuilder: (context, index) {
                  final oldKfList = kfState.oldKfList[index];
                  return CheckboxListTile(
                    title: Text("${oldKfList.name}"),
                    value: kfState.selectedIdxs.contains(index),
                    onChanged: (bool? value) {
                      kfCubit.checkSelected(index, value ?? false);
                    },
                  );
                },
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('确认删除'),
                        content: Text('确定要彻底删除这些关键帧吗？此操作无法撤销'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              kfCubit.delete(List.from(kfState.selectedIdxs));
                              // kfCubit.clearSelected();
                              Navigator.of(context).pop();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.red.shade200,
                              ),
                            ),
                            child: Text('彻底删除'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red.shade200),
                ),
                child: Text('彻底删除'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // print('选中的关键帧: $kfState.selectedIdxs');
                  kfCubit.active(List.from(kfState.selectedIdxs));

                  // 在这里添加对选中关键帧的操作逻辑
                  Navigator.of(context).pop();
                },
                child: Text('复活 (${kfState.selectedIdxs.length})'),
              ),
            ],
          );
        },
      );
    },
  );
}
