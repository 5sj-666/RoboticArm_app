import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
// import '../motions/details.dart'; // 导入详情页
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/types/motions.dart';

class WaterfallPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final motionList = BlocProvider.of<MotionsCubit>(context);
    print('----waterfall${motionList.state.motions}');
    final list = motionList.state.motions;
    print('----waterfall$list');
    for (int i = 0; i < list.length; i++) {
      print('瀑布流: ${list[i].name}');
    }

    // final _searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          // width: double.infinity,
          child: Text(
            '动作列表',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.router.push(NamedRoute('SearchRoute'));
              // 执行搜索
              // print("执行搜索：${_searchController.text}");
            },
          ),
        ],
      ),
      body: BlocBuilder<MotionsCubit, MotionsState>(
        builder: (context, state) {
          logger.w('更新motiosnCubit状态监听');
          final screenWidth = MediaQuery.of(context).size.width;
          return ListView(
            // 关键：让ListView高度适应Wrap内容（否则会无限延伸）
            shrinkWrap: true,
            children: [
              SizedBox(
                width: screenWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: screenWidth / 2,
                      // decoration: BoxDecoration(color: Colors.green),
                      child: Column(
                        children: [
                          for (
                            int i = 0;
                            i < motionList.state.motions.length;
                            i += 2
                          )
                            MotionCard(
                              motion: motionList.state.motions[i],
                              index: i,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: screenWidth / 2,
                      // decoration: BoxDecoration(color: Colors.yellow),
                      child: Column(
                        children: [
                          for (
                            int i = 1;
                            i < motionList.state.motions.length;
                            i += 2
                          )
                            MotionCard(
                              motion: motionList.state.motions[i],
                              index: i,
                            ),
                        ],
                      ),
                    ),
                  ],
                  // for (int i = 0; i < list.length; i += 2)
                  //           MotionCard(motion: list[i], index: i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MotionCard extends StatelessWidget {
  final Motion motion;
  final int index;

  MotionCard({super.key, required this.motion, required this.index});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth / 2;
    // double ramdomHeight = index % 2 == 0 ? 20 : 0;

    return InkWell(
      onTap: () {
        print('---点击跳转');
        context.router.push(NamedRoute('DetailRoute'));
      },
      child: SizedBox(
        width: cardWidth,
        // height: screenWidth / 2 + 120 + ramdomHeight,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // 圆角半径为12
          ),
          margin: EdgeInsets.fromLTRB(
            index.isOdd ? 0 : 10,
            index > 1 ? 0 : 10,
            10,
            10,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              Image(
                width: cardWidth,
                height: screenWidth / 2 + 10,
                fit: BoxFit.cover,
                image: AssetImage('assets/wallfall1.jpg'),
              ),
              Container(
                padding: EdgeInsetsGeometry.all(6),
                width: cardWidth,
                child: Text(
                  motion.name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 2,
                ),
              ),
              Container(
                padding: EdgeInsetsGeometry.all(6),
                width: cardWidth,
                child: Text(
                  motion.description,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
