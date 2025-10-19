// import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'pages/motions/waterfall.dart';
// import 'pages/profile.dart';
// import 'pages/ai_chat.dart';
// import 'pages/devices.dart';
// import 'pages/devices_page.dart';
// import 'pages/my_home_page.dart';
import 'package:robotic_arm_app/cubit/joints_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_router.dart';

void main() {
  runApp(
      // 提供 JointsCubit 给整个应用
      BlocProvider(
    create: (context) => JointsCubit(),
    child: MyApp(),
  ));
  // runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp.router(
        title: 'RobticArm_app',
        theme: ThemeData(
          // useMaterial3: true,
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            primary: Colors.deepOrange,
            onPrimary: Colors.red, // 推荐用白色，保证对比度
          ),
        ),
        // home: MyHomePage(),
        routerConfig: _appRouter.config(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // var current = WordPair.random();
}
