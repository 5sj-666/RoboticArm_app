import 'package:bloc/bloc.dart';

class HomeState {
  final int index;
  HomeState({this.index = 0});
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  void setIndex(index) {
    emit(HomeState(index: index));
  }
}
