import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class SearchPage extends StatelessWidget {
  // SearchPage({super.key});

  @override
  build(BuildContext context) {
    // return Text('search page');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 24,
        backgroundColor: Colors.white,
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadiusGeometry.all(Radius.circular(18)),
          ),
          clipBehavior: Clip.hardEdge,
          child: TextField(
            cursorHeight: 16,
            cursorColor: Colors.grey.shade500,
            decoration: InputDecoration(
              prefix: SizedBox(width: 16),
              hintText: '请输入动作名称',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search),
            ),
            // style: TextStyle(fontSize: 18),
          ),
        ),

        // actions: [],
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          // width: double.infinity,
          // height: double.infinity,
          // color: Colors.white,
          child: Text('历史搜索'),
        ),
      ),
    );
  }
}
