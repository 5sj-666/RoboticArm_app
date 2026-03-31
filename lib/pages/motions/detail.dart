import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/app_router.dart';
import 'package:robotic_arm_app/pages/home_cubit.dart';
import 'dart:convert';
import 'package:robotic_arm_app/cubit/keyframe_cubit.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

@RoutePage()
class DetailPage extends StatelessWidget {
  const DetailPage({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final motionsCubit = BlocProvider.of<MotionsCubit>(context);
    final homeCubit = BlocProvider.of<HomeCubit>(context);

    final motion = motionsCubit.findById(id);

    return Scaffold(
      appBar: AppBar(title: Text('详情')),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: 200,
                    child: CarouselSlider(
                      options: CarouselOptions(height: 300.0),
                      items: [1, 2, 3, 4, 5].map((i) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Image(
                              width: screenWidth,
                              fit: BoxFit.cover,
                              image: AssetImage(
                                'assets/Gemini_Generated_cover.png',
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    width: screenWidth,
                    height: 60,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(color: Colors.white),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "名称: ${motion.name}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "描述: ${motion.description}",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Text(
                          //       '作者名字',
                          //       style: TextStyle(
                          //         fontSize: 12,
                          //         color: Colors.black54,
                          //       ),
                          //     ),
                          //     Container(
                          //       padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          //       decoration: BoxDecoration(
                          //         border: Border.all(
                          //           width: 0.5,
                          //           color: Colors.black54,
                          //         ),
                          //         borderRadius: BorderRadius.all(
                          //           Radius.circular(8),
                          //         ),
                          //       ),
                          //       child: Text(
                          //         '关注',
                          //         style: TextStyle(
                          //           fontSize: 12,
                          //           color: Colors.black54,
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 10),
                    width: MediaQuery.of(context).size.width - 16,
                    height: 320,
                    child: SingleChildScrollView(
                      child: JsonViewer(jsonData: motion.toJson()),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Icon(Icons.favorite, color: Colors.grey.shade400),
                        Container(
                          margin: EdgeInsets.only(right: 10),
                          width: screenWidth / 4,
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.lightBlue.shade600,
                              ),
                            ),
                            onPressed: () {
                              KeyframeCubit kfCubit =
                                  BlocProvider.of<KeyframeCubit>(context);
                              kfCubit.switchOptType(OptType.edit, motion);
                              // kfCubit.
                              // kfCubit.state.optType = OptType.edit;
                              // kfCubit.emit(kfCubit.state.copyWith(oldKfList: kfCubit.state.kfList));
                              context.router.push(
                                NamedRoute('DesignMotionRoute'),
                              );
                            },
                            child: Text('编辑'),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth / 4,
                          child: FilledButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                Colors.green.shade300,
                              ),
                            ),
                            onPressed: () {
                              bool result = motionsCubit.setCurMotion(motion);
                              motionsCubit.updateStatus(MotionStatus.prepare);
                              if (result) {
                                homeCubit.setIndex(1);
                                context.router.popUntil(
                                  (route) =>
                                      route.settings.name == HomeRoute.name,
                                );
                              }
                            },
                            child: Text('应用'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JsonViewer extends StatelessWidget {
  final Map<String, dynamic> jsonData;

  const JsonViewer({Key? key, required this.jsonData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 格式化 JSON 数据为带缩进的字符串
    final formattedJson = JsonEncoder.withIndent('  ').convert(jsonData);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SelectableText(
        formattedJson,
        style: const TextStyle(
          fontFamily: 'monospace', // 使用等宽字体
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
