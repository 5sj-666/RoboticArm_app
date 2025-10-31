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
    return Scaffold(
      // appBar: Text('动作列表'),
      // body: SafeArea(child: Text('11')),
      body: BlocBuilder<MotionsCubit, MotionsState>(
        builder: (context, state) {
          return ListView(
            // 关键：让ListView高度适应Wrap内容（否则会无限延伸）
            shrinkWrap: true,
            // 禁用ListView的滚动边界效果（可选，避免与Wrap视觉冲突）
            // physics: const BouncingScrollPhysics(),
            // padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                // crossAxisAlignment: WrapCrossAlignment.center,
                // verticalDirection: VerticalDirection.up,
                // textDirection: TextDirection.ltr,
                alignment: WrapAlignment.start,
                children: [
                  for (int i = 0; i < state.motions.length; i++)
                    MotionCard(motion: state.motions[i], index: i),
                ],
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

    return SizedBox(
      width: cardWidth,
      height: screenWidth / 2 + 120,
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
              // width: double.infinity,
              width: cardWidth,
              height: screenWidth / 2 + 40,
              fit: BoxFit.cover,
              image: AssetImage('assets/wallfall1.jpg'),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.yellow),
              height: 30,
              child: Text(motion.name),
            ),

            Text(motion.description),
          ],
        ),
      ),
    );
  }
}
