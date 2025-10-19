import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

import 'motions/waterfall.dart';
import 'profile.dart';
import 'ai_chat.dart';
// // import 'pages/devices.dart';
import 'devices_page.dart';
// import 'package:robotic_arm_app/cubit/joints_cubit.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 定义页面列表
  final List<Widget> _pages = [
    // Center(child: Text('Home Page')), // 首页
    WaterfallPage(), // 瀑布流页面
    // Center(child: Text('Search Page')), // 搜索页
    // WebViewPage(url: 'https://flutter.dev'),
    DevicesPage(), // 设备页面
    AiChatPage(), // AI聊天页面
    ProfilePage(), // 个人资料页
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(''),
      // ),
      // body: IndexedStack(
      //   index: _selectedIndex, // 当前选中的索引
      //   children: _pages, // 所有页面
      // ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex, // 当前选中的索引
          children: _pages, // 所有页面
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        fixedColor: Colors.deepOrange,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.gesture),
            label: '模型',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.device_hub),
            label: '设备',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
