import 'package:flutter/material.dart';
import './Selector.dart';
import './Svg.dart';

class SetBezier extends StatefulWidget {
  final String initTimingFunc;

  SetBezier({super.key, this.initTimingFunc = 'linear'}) {
    // print('dialog setBezier: $initTimingFunc');
  }

  @override
  State<SetBezier> createState() => _SetBezierState();
}

class _SetBezierState extends State<SetBezier> {
  // fianl
  String selectedTimingFunc = 'linear';
  String initTimeFunc = 'linear';

  final List<String> preset = ['linear', 'ease-in', 'ease-out', 'ease-in-out'];
  final List<List<Color>> presetColor = [
    [Colors.yellow, Colors.blue],
    [Colors.green, Colors.purple],
    [Colors.cyan, Colors.amber],
    [Colors.red, Colors.grey],
  ];

  final List<String> predefinedsValue = [
    '0.2,0.2,.5,.5',
    '0.42,0,1,1',
    '0,0,0.58,1',
    '0.42,0,0.58,1',
  ];

  final Map<String, String> predefinedsMap = {
    'linear': '0.2,0.2, .5,.5',
    'ease-in': '0.42,0,1,1',
    'ease-out': '0,0,0.58,1',
    'ease-in-out': '0.42,0,0.58,1',
  };

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedTimingFunc = widget.initTimingFunc;
      if (predefinedsMap[widget.initTimingFunc] != null) {
        selectedTimingFunc = predefinedsMap[widget.initTimingFunc]!;
      }
      initTimeFunc = selectedTimingFunc;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置运动函数', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: 400,
        height: 355,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              clipBehavior: Clip.hardEdge,
              child: CubicBezierSelector(
                width: 250,
                height: 250,
                initCubicBezier: initTimeFunc,
                onPointsChanged: (str) {
                  print('onPointsChanged$str');
                  setState(() {
                    selectedTimingFunc = str;
                  });
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < preset.length; i++)
                  InkWell(
                    onTap: () {
                      setState(() {
                        initTimeFunc = predefinedsValue[i];
                        selectedTimingFunc = predefinedsValue[i];
                      });
                      // print('inkwell: ${preset[i]}');
                    },
                    child: SvgCubicBezier(
                      timingFunc: preset[i],
                      size: 35,
                      bg: presetColor[i][1],
                      color: presetColor[i][0],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 250,
              height: 30,
              child: Text('过渡函数: $selectedTimingFunc'),
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
            if (context.mounted) {
              // 显示 SnackBar（需通过 ScaffoldMessenger）
              // ScaffoldMessenger.of(context).showSnackBar(snackBar);
              // motionsCubit.update();
              Navigator.of(context).pop(selectedTimingFunc);
            }
          },
          child: Text('确定'),
        ),
      ],
    );
  }
}
