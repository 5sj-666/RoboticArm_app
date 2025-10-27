import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
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
          ],
        ),
      ),
    );
  }
}
