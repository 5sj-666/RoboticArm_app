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
              // SizedBox(width: 20, child: Text('${index + 1}')),
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
                    item.time = double.tryParse(value) ?? 0.5;
                  },
                  onTap: () {
                    // 延迟设置全选
                    Future.delayed(Duration(milliseconds: 10), () {
                      // 全选输入框内容
                      timeController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: timeController.text.length,
                      );
                    });
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
                  onTap: () {
                    // 全选输入框内容
                    // 延迟设置全选
                    Future.delayed(Duration(milliseconds: 10), () {
                      countController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: countController.text.length,
                      );
                    });
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
      return AlertDialog(
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
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?(\d+)?(\.\d+)?$'),
                    ),
                    RangeInputFormatter(min: -145.0, max: 145.0),
                  ],
                  decoration: InputDecoration(
                    labelText: '电机 ${index + 1} 角度',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    // 全选输入框内容
                    // 延迟设置全选
                    Future.delayed(Duration(milliseconds: 10), () {
                      controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controllers[index].text.length,
                      );
                    });
                  },
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
                  .map((controller) => double.tryParse(controller.text) ?? 0.0)
                  .toList();

              // 调用回调函数
              onConfirm(updatedAngles);

              Navigator.of(context).pop(); // 关闭弹框
            },
            child: Text('确定'),
          ),
        ],
      );
    },
  );
}

class RangeInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  RangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 如果输入为空，直接返回
    if (newValue.text.isEmpty ||
        newValue.text == '-' ||
        newValue.text == '.' ||
        newValue.text == '-.' ||
        newValue.text == '') {
      return newValue;
    }

    // 尝试解析输入的值
    final double? value = double.tryParse(newValue.text);

    // // 如果解析失败，直接赋值0.0
    if (value == null) {
      newValue = TextEditingValue(
        text: "0.0",
        selection: TextSelection.collapsed(offset: "0.0".length),
      );
      return newValue;
    }

    // 如果值超出范围，阻止输入
    if (value < -145.0 || value > 145.0) {
      // return value.clamp(-145.0, 145.0).toString();
      double limitedValue = value.clamp(-145.0, 145.0);
      newValue = TextEditingValue(
        text: limitedValue.toString(),
        selection: TextSelection.collapsed(
          offset: limitedValue.toString().length,
        ),
      );
    }

    // 否则允许输入
    return newValue;
  }
}
