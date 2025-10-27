import 'package:flutter/material.dart';

class MotionNode extends StatefulWidget {
  const MotionNode({super.key});

  @override
  MotionNodeState createState() => MotionNodeState();
}

class MotionNodeState extends State<MotionNode> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(width: 1, color: Colors.green.shade500),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '时间',
                ),
              ),
              Text('动作名称1'),
              Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black54),
                  ),
                  width: 60,
                  height: 60,
                  child: Text('机械臂位置示意图'))
            ],
          ),
        ),
      ],
    );
  }
}
