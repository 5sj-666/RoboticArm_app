import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/components/Bezier/Dialog.dart';
import 'package:robotic_arm_app/components/Bezier/Svg.dart';

class KfCard extends StatelessWidget {
  final Keyframe? item;
  final int index;
  final ValueChanged<String>? changeTimingFunc;
  final ValueChanged<double>? changeTime;
  final ValueChanged<int>? changeRepeat;

  final ValueChanged<int>? softDel;
  final bool showDelete;

  KfCard({
    super.key,
    this.item,
    required this.index,
    this.changeTimingFunc,
    this.softDel,
    this.showDelete = false,
    this.changeTime,
    this.changeRepeat,
  });

  @override
  Widget build(BuildContext context) {
    // print('design_motion build: ${item?.timingFunction}');
    // KeyframeCubit kfCubit = BlocProvider.of<KeyframeCubit>(context);
    final timeController = TextEditingController(text: item?.time.toString());
    final countController = TextEditingController(
      text: item?.repeatCount.toString(),
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
                    item!.time = double.tryParse(value) ?? 0.0;
                    // if (changeTime != null) {
                    //   changeTime!(item!.time);
                    // }
                  },
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    item!.time = double.tryParse(value) ?? 0.0;
                    if (changeTime != null) {
                      changeTime!(item!.time);
                    }
                  }, // 失去焦点，收起键盘
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus(); // 失去焦点，收起键盘
                    if (changeTime != null) {
                      changeTime!(item!.time);
                    }
                  },
                  onTapOutside: (event) {
                    // 失去焦点时，更新文本框内容为最新的 repeatCount 值
                    countController.text = item!.repeatCount.toString();
                    // if (changeRepeat != null) {
                    //   changeRepeat!(item!.repeatCount);
                    // }
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
                    item!.repeatCount = int.tryParse(value) ?? 0;
                  },
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    item!.repeatCount = int.tryParse(value) ?? 0;
                    if (changeRepeat != null) {
                      changeRepeat!(item!.repeatCount);
                    }
                  }, // 失去焦点，收起键盘
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus(); // 失去焦点，收起键盘
                    if (changeRepeat != null) {
                      changeRepeat!(item!.repeatCount);
                    }
                  },
                  onTapOutside: (event) {
                    // 失去焦点时，更新文本框内容为最新的 repeatCount 值
                    countController.text = item!.repeatCount.toString();
                    // if (changeRepeat != null) {
                    //   changeRepeat!(item!.repeatCount);
                    // }
                  },
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
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Text(
                    "名称: ${(item?.name ?? '').replaceFirst('keyframe_', '')}",
                  ),
                ),
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
