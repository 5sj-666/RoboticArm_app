import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
// import 'arm.dart'; // 引入机械臂页面

class DeviceInformationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      // color: Colors.black,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      // 面板关闭时显示的高度
      minHeight: 80,
      // 面板打开时显示的高度
      maxHeight: 500,
      // 面板内容
      panel: const Column(
        // alignment: Alignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Text('设备信息: 蓝牙状态，关节状态, 当前动作状态'),
            ],
          ),
          Text('滑动面板内容')
        ],
      ),
      // panel: const Center(
      //   child: Text('滑动面板内容'),
      // ),
      // 主内容区域
      // body: ArmPage(),
      // body: const Center(
      //   child: Text('主内容区域'),
      // ),
      // 面板顶部的滑块
      collapsed: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text(
                  //   "蓝牙",
                  //   style: TextStyle(color: Colors.grey),
                  // ),
                  SizedBox(height: 8),
                  Icon(Icons.bluetooth, color: Colors.grey),
                ],
              ),
              SizedBox(width: 8),
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "关节1",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.circle, color: Colors.green, size: 16),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "关节2",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.circle, color: Colors.green, size: 16),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "关节3",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.circle, color: Colors.green, size: 16),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "关节4",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.circle, color: Colors.green, size: 16),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "关节5",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.circle, color: Colors.green, size: 16),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "关节6",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Icon(Icons.circle, color: Colors.green, size: 16),
                    ],
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "动作",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "motions1",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              // Text(
              //   '上滑查看更多设备信息',
              //   style: TextStyle(color: Colors.grey),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
