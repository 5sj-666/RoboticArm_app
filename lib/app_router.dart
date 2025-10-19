import 'package:auto_route/auto_route.dart';
import 'package:robotic_arm_app/pages/HomeScreen.dart';
// import 'package:robotic_arm_app/pages/motions/order_keyframe.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.material(); //.cupertino, .adaptive ..etc

  @override
  List<AutoRoute> get routes => [
        // HomeScreen is generated as HomeRoute because
        // of the replaceInRouteName property
        // AutoRoute(page: MyHomePage, initial: true),
        // AutoRoute(page: OrderKeyframe.page),
        AutoRoute(page: HomeRoute.page, initial: true)
      ];

  @override
  List<AutoRouteGuard> get guards => [
        // optionally add root guards here
      ];
}
