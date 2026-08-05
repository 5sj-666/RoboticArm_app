import 'package:flutter/material.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'package:robotic_arm_app/utils/motorCmd.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mortorCmd = MotorCmdGenerator();
    BleCubit bleCubit = BlocProvider.of<BleCubit>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  // backgroundImage: Colors.red,
                  backgroundColor: Colors.red,
                  // backgroundImage: NetworkImage(
                  //   'https://via.placeholder.com/150', // 替换为用户头像的 URL
                  // ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '用户名',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'user@example.com',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('设置'),
              onTap: () {
                // 添加设置页面的导航逻辑
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('历史记录'),
              onTap: () {
                // 添加历史记录页面的导航逻辑
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('退出登录'),
              onTap: () {
                // 添加退出登录逻辑
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('删除所有记录'),
              onTap: () {
                SharedPrefsStorage.clearAllData();
              },
            ),

            ListTile(
              leading: Icon(Icons.logout),
              title: Text('使能电机'),
              onTap: () {
                ///使能电机
                final cmd = mortorCmd.generateCMD('enable', {'motorId': 21});
                bleCubit.sendSingleCmd(cmd);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('停止电机'),
              onTap: () {
                /// 停止电机
                final cmd = mortorCmd.generateCMD('disable', {'motorId': 21});
                bleCubit.sendSingleCmd(cmd);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('设置运行模式'),
              onTap: () {
                ///设置runmode
                final cmd = mortorCmd.generateCMD('run_mode', {
                  'motorId': 21,
                  'run_mode': 1,
                });
                bleCubit.sendSingleCmd(cmd);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('设置速度'),
              onTap: () {
                ///设置速度
                final cmd = mortorCmd.generateCMD('limit_spd', {
                  'motorId': 21,
                  'limit_spd': 1.0,
                });
                bleCubit.sendSingleCmd(cmd);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('设置位置'),
              onTap: () {
                ///设置位置
                final cmd = mortorCmd.generateCMD('loc_ref', {
                  'motorId': 21,
                  'loc_ref': 1.0,
                });
                bleCubit.sendSingleCmd(cmd);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('力矩模式 t'),
              onTap: () {
                // for (int i = 21; i < 21 + 6; i++) {
                //   /// 设置runmode
                //   final cmd = mortorCmd.generateCMD('run_mode', {
                //     'motorId': i,
                //     'run_mode': 3,
                //   });
                //   bleCubit.sendSingleCmd(cmd);
                //   print('设置力矩:$i');
                // }
                final cmd = mortorCmd.generateCMD('run_mode', {
                  'motorId': 23,
                  'run_mode': 3,
                });
                bleCubit.sendSingleCmd(cmd);
                final iqcmd = mortorCmd.generateCMD('iq_ref', {
                  'motorId': 23,
                  'iq_ref': 0.5,
                });
                bleCubit.sendSingleCmd(iqcmd);
              },
            ),
          ],
        ),
      ),
    );
  }
}
