import 'package:auto_route/auto_route.dart';
import 'package:robotic_arm_app/pages/home/HomeScreen.dart';
import 'package:robotic_arm_app/pages/motions/design_motion.dart';
import 'package:robotic_arm_app/pages/waterfall/search.dart';

import 'package:robotic_arm_app/pages/motions/detail.dart';

part 'app_router.gr.dart';

// 页面名字中的page和screen会被替换成Route
@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material(); //.cupertino, .adaptive ..etc

  @override
  List<AutoRoute> get routes => [
    // 手动定义路由
    // NamedRouteDef(
    //   name: 'BookDetailsRoute',
    //   path: '/books/:id', // optional
    //   builder: (context, data) {
    //     return BookDetailsPage(id: data.params.getInt('id'));
    //   },
    // ),
    // 使用生成的路由
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: OrderKeyframeRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: DetailRoute.page),
  ];

  @override
  List<AutoRouteGuard> get guards => [
    // optionally add root guards here
  ];
}
