import 'package:flutter/material.dart';
import './Selector.dart';
import './Svg.dart';

class SetBezier extends StatefulWidget {
  final String initTimingFunc;

  SetBezier({super.key, this.initTimingFunc = 'linear'});

  @override
  State<SetBezier> createState() => _SetBezierState();
}

class _SetBezierState extends State<SetBezier> {
  // fianl
  String selectedTimingFunc = 'linear';
  final List<String> predefineds = [
    'linear',
    'ease-in',
    'ease-out',
    'ease-in-out',
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
    // Use a fallback if the lookup returns null to satisfy non-nullable String
    selectedTimingFunc =
        predefinedsMap[widget.initTimingFunc] ?? predefinedsMap['linear']!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置运动函数', style: TextStyle(fontSize: 18)),
      content: SizedBox(
        width: 400,
        height: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CubicBezierSelector(
                width: 250,
                height: 250,
                initCubicBezier: selectedTimingFunc,
                onPointsChanged: (str) {
                  print('onPointsChanged$str');
                  setState(() {
                    selectedTimingFunc = str;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < predefineds.length; i++)
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedTimingFunc = predefinedsValue[i];
                      });
                      print('inkwell: ${predefineds[i]}');
                    },
                    child: SvgCubicBezier(timingFunc: predefineds[i], size: 40),
                  ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 250,
              height: 30,
              child: Text('过渡函数: linear$selectedTimingFunc'),
            ),
          ],
        ),
      ),

      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop('');
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

// Future<void> dialogSetBezier({required BuildContext context}) async {
//   return showDialog<void>(
//     context: context,

//     builder: (BuildContext context) {
//       String selectedTimingFunc = '';
//       final List<dynamic> predefineds = [
//         'linear',
//         'ease-in',
//         'ease-out',
//         'ease-in-out',
//       ];
//       // 创建 GlobalKey 关联子组件
//       return AlertDialog(
//         title: Text('设置运动函数', style: TextStyle(fontSize: 18)),
//         content: SizedBox(
//           width: 400,
//           height: 350,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               SizedBox(
//                 width: 250,
//                 height: 250,
//                 child: CubicBezierSelector(
//                   width: 250,
//                   height: 250,
//                   initCubicBezier: '0.3,0.3,0.8,0.8',
//                   onPointsChanged: (str) {
//                     print('onPointsChanged$str');
//                     selectedTimingFunc = str;
//                   },
//                 ),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   for (int i = 0; i < predefineds.length; i++)
//                     InkWell(
//                       onTap: () {
//                         selectedTimingFunc = predefineds[i];
//                         print('inkwell: ${predefineds[i]}');
//                       },
//                       child: SvgCubicBezier(
//                         timingFunc: predefineds[i],
//                         size: 40,
//                       ),
//                     ),
//                 ],
//               ),
//               SizedBox(height: 8),
//               SizedBox(
//                 width: 250,
//                 height: 30,
//                 child: Text('过渡函数: linear$selectedTimingFunc'),
//               ),
//             ],
//           ),
//         ),

//         actions: [
//           FilledButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: Text('取消'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (context.mounted) {
//                 // 显示 SnackBar（需通过 ScaffoldMessenger）
//                 // ScaffoldMessenger.of(context).showSnackBar(snackBar);
//                 // motionsCubit.update();
//                 Navigator.of(context).pop(selectedTimingFunc);
//               }
//             },
//             child: Text('确定'),
//           ),
//         ],
//       );
//     },
//   );
// }
