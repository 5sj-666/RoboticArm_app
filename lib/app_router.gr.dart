// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DetailPage]
class DetailRoute extends PageRouteInfo<DetailRouteArgs> {
  DetailRoute({required String id, List<PageRouteInfo>? children})
    : super(
        DetailRoute.name,
        args: DetailRouteArgs(id: id),
        initialChildren: children,
      );

  static const String name = 'DetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DetailRouteArgs>();
      return DetailPage(id: args.id);
    },
  );
}

class DetailRouteArgs {
  const DetailRouteArgs({required this.id});

  final String id;

  @override
  String toString() {
    return 'DetailRouteArgs{id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DetailRouteArgs) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return HomeScreen();
    },
  );
}

/// generated route for
/// [OrderKeyframePage]
class OrderKeyframeRoute extends PageRouteInfo<void> {
  const OrderKeyframeRoute({List<PageRouteInfo>? children})
    : super(OrderKeyframeRoute.name, initialChildren: children);

  static const String name = 'OrderKeyframeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OrderKeyframePage();
    },
  );
}

/// generated route for
/// [SearchPage]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
    : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return SearchPage();
    },
  );
}
