import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/waterfall.dart';
import 'pages/profile.dart';
// import 'pages/devices.dart';
import 'pages/devices_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // 定义页面列表
  final List<Widget> _pages = [
    // Center(child: Text('Home Page')), // 首页
    WaterfallPage(), // 瀑布流页面
    // Center(child: Text('Search Page')), // 搜索页
    // WebViewPage(url: 'https://flutter.dev'),
    DevicesPage(), // 设备页面
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
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
