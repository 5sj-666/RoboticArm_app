import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/components/Bezier/Dialog.dart';
import 'package:robotic_arm_app/components/Bezier/Svg.dart';

typedef ValueChangedWithTwoArgs<T, U> = void Function(T value1, U value2);

class KfCard extends StatelessWidget {
  final Keyframe item;
  final int index;
  final void Function(Keyframe, [String?]) updateKf;
  final ValueChanged<int>? softDel;
  final bool showDelete;

  KfCard({
    super.key,
    required this.item,
    required this.index,
    required this.updateKf,
    this.softDel,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    // print('design_motion build: ${item?.timingFunction}');
    // KeyframeCubit kfCubit = BlocProvider.of<KeyframeCubit>(context);
    final timeController = TextEditingController(text: item.time.toString());
    final countController = TextEditingController(
      text: item.repeatCount.toString(),
    );
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
                  controller: timeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '运行时间/s',
                  ),
                  onChanged: (value) {
                    item.time = double.tryParse(value) ?? 0.0;
                  },
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                    item.time = double.tryParse(timeController.text) ?? 0.0;
                    updateKf(item, "changeTime");
                  },
                  onTap: () {
                    timeController.text = "";
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  enabled: index != 0,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                  ), // 弹出数字键盘
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                  ],
                  controller: countController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '重复次数',
                  ),
                  onChanged: (value) {
                    item.repeatCount = int.tryParse(value) ?? 0;
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    updateKf(item, "changeRepeat");
                  },
                  onTapOutside: (event) {
                    countController.text = item.repeatCount.toString();
                  },
                  onTap: () {
                    countController.text = "";
                  },
                ),
              ),
              InkWell(
                onTap: () async {
                  final dynamic customTimingFunc = await showDialog(
                    context: context,
                    builder: (context) => SetBezier(
                      initTimingFunc: item.timingFunction ?? 'linear',
                    ),
                  );
                  if (customTimingFunc != null) {
                    item.timingFunction = customTimingFunc;

                    try {
                      updateKf(item, "changeTimingFunc");
                    } catch (error) {
                      print(error);
                    }
                  }
                },
                child: SvgCubicBezier(
                  timingFunc: item.timingFunction ?? 'ease-in',
                  bg: Colors.white70,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Text(
                    "名称: ${(item.name ?? '').replaceFirst('keyframe_', '')}",
                  ),
                ),
              ),
              FilledButton(
                onPressed: () {
                  motorAngleDialog(
                    context: context,
                    motorAngles: item.positions,
                    onConfirm: (list) {
                      item.positions = list;
                      updateKf(item, "changePositions");
                    },
                  );
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsetsGeometry.zero),
                  minimumSize: WidgetStateProperty.all<Size>(Size(40, 25)),
                ),
                child: Icon(Icons.edit),
              ),

              FilledButton(
                onPressed: () {
                  updateKf(item, "duplicate");
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsetsGeometry.zero),
                  minimumSize: WidgetStateProperty.all<Size>(Size(40, 25)),
                ),
                child: Icon(Icons.copy),
              ),
              SizedBox(
                child: showDelete
                    ? FilledButton(
                        onPressed: () {
                          if (softDel != null) {
                            softDel!(index);
                          }
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            EdgeInsetsGeometry.zero,
                          ),
                          minimumSize: WidgetStateProperty.all<Size>(
                            Size(40, 25),
                          ),
                          backgroundColor: WidgetStateProperty.all(
                            Colors.red.shade400,
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

Future<void> motorAngleDialog({
  required BuildContext context,
  required List<double> motorAngles, // 当前电机角度列表
  required ValueChanged<List<double>> onConfirm, // 确定按钮回调
}) async {
  // 创建控制器列表，每个输入框对应一个控制器
  final controllers = List.generate(
    motorAngles.length,
    (index) => TextEditingController(text: motorAngles[index].toString()),
  );

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 点击空白处收起键盘
        },
        child: AlertDialog(
          title: Text('修改电机角度', style: TextStyle(fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              children: List.generate(
                motorAngles.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: controllers[index],
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
                    ],
                    decoration: InputDecoration(
                      labelText: '电机 ${index + 1} 角度',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭弹框
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                // 获取用户输入的角度值
                final updatedAngles = controllers
                    .map(
                      (controller) => double.tryParse(controller.text) ?? 0.0,
                    )
                    .toList();

                // 调用回调函数
                onConfirm(updatedAngles);

                Navigator.of(context).pop(); // 关闭弹框
              },
              child: Text('确定'),
            ),
          ],
        ),
      );
    },
  );
}
