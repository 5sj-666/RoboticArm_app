import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'motionsWaterfall.dart';
import 'profile.dart';
import 'ai_chat.dart';
import 'devices_page.dart';
import './home_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  // 定义页面列表
  final List<Widget> _pages = [
    WaterfallPage(), // 瀑布流页面
    DevicesPage(), // 设备页面
    AiChatPage(), // AI聊天页面
    ProfilePage(), // 个人资料页
  ];

  @override
  Widget build(BuildContext context) {
    final _homeCubit = BlocProvider.of<HomeCubit>(context);
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return IndexedStack(
                  index: state.index, // 当前选中的索引
                  children: _pages, // 所有页面
                );
              },
            ),
          ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: state.index,
            onTap: (index) {
              _homeCubit.setIndex(index);
            },
            unselectedItemColor: Colors.grey,
            fixedColor: Colors.deepOrange,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.gesture), label: '模型'),
              BottomNavigationBarItem(
                icon: Icon(Icons.device_hub),
                label: '设备',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'AI'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
            ],
          ),
        );
      },
    );
  }
}
