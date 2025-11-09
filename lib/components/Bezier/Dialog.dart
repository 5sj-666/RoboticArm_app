import 'package:flutter/material.dart';
import './Selector.dart';
// import './Svg.dart';

Future<void> dialogSetBezier({required BuildContext context}) async {
  // required List<KeyframeWrapper> keyframeWrapperList,
  // required MotionsCubit motionsCubit,
  // required JointsCubit jointsCubit,
  // final _keyframeNameCtrl = TextEditingController();
  // final _keyframeDescriptCtrl = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('设置运动函数', style: TextStyle(fontSize: 18)),
        content: SizedBox(
          width: 800,
          height: 500,
          // clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('111'),
              // CubicBezierSelector(),
              SizedBox(
                width: 400,
                height: 400,
                child: CubicBezierSelector(
                  width: 250,
                  height: 250,
                  initCubicBezier: '1,1,1,1',
                  onPointsChanged: (str) {
                    print('onPointsChanged$str');
                  },
                ),
              ),

              // SizedBox(
              //   width: 300,
              //   height: 300,
              //   child: Transform.scale(
              //     scale: 0.5,
              //     child: CubicBezierSelector(),
              //   ),
              // ),

              // SvgCubicBezier(timingFunc: 'liner'),
              // TextField(controller: _keyframeNameCtrl, autofocus: true),
              // TextField(
              //   controller: _keyframeDescriptCtrl,
              //   autofocus: true,
              //   maxLines: 2,
              //   maxLength: 30,
              // ),
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
              // late SnackBar snackBar;
              // 存储在sharedPreferences
              // try {
              //   await SharedPrefsStorage.save(
              //     key: 'motion_$saveName',
              //     jsonValue: json.encode(saveData.toJson()),
              //   );

              //   // 创建 SnackBar
              //   snackBar = SnackBar(
              //     content: const Text("保存动作成功"), // 提示文本
              //     duration: const Duration(seconds: 2), // 显示时长（默认 4 秒）
              //     backgroundColor: Colors.green, // 背景色
              //   );
              // } catch (err) {
              //   logger.w('动作设计错误$err');
              // }

              if (context.mounted) {
                // 显示 SnackBar（需通过 ScaffoldMessenger）
                // ScaffoldMessenger.of(context).showSnackBar(snackBar);
                // motionsCubit.update();
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
