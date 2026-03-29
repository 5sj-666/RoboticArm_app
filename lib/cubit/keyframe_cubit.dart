import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'dart:convert';

final logger = Logger();

class KeyframeState {
  final List<Keyframe> kfList;
  final List<Keyframe> oldKfList;
  final Set<int> selectedIdxs;

  KeyframeState({
    required this.kfList,
    required this.oldKfList,
    required this.selectedIdxs,
  });

  KeyframeState copyWith({
    List<Keyframe>? kfList,
    List<Keyframe>? oldKfList,
    Set<int>? selectedIdxs,
  }) {
    return KeyframeState(
      kfList: kfList ?? this.kfList,
      oldKfList: oldKfList ?? this.oldKfList,
      selectedIdxs: selectedIdxs ?? this.selectedIdxs,
    );
  }
}

class KeyframeCubit extends Cubit<KeyframeState> {
  KeyframeCubit()
    : super(KeyframeState(kfList: [], oldKfList: [], selectedIdxs: {})) {
    init();
  }

  void init() async {
    List<Keyframe> kfList = [];
    final result = await SharedPrefsStorage.findByKeyPrefix('keyframe_');

    result.forEach((key, value) {
      final keyframe = Keyframe.fromJson(json.decode(value));
      // 用户未设置时候，贝塞尔曲线为空，在此做默认赋值
      if (keyframe.timingFunction == null || keyframe.timingFunction == '') {
        keyframe.timingFunction = '.3,.3,.6,.6';
      }
      kfList.add(keyframe);
    });

    /// key = keyframe_ + name ; 所以过期的key直接用oldkeyframe_ + name 存储
    /// 既然过期了，需要将keyframe_ + name删除
    emit(state.copyWith(kfList: kfList));

    List<Keyframe> oldkfList = [];
    final oldKfResult = await SharedPrefsStorage.findByKeyPrefix(
      'oldKeyframe_',
    );

    oldKfResult.forEach((key, value) {
      final keyframe = Keyframe.fromJson(json.decode(value));
      if (keyframe.timingFunction == null || keyframe.timingFunction == '') {
        keyframe.timingFunction = '.3,.3,.6,.6';
      }
      oldkfList.add(keyframe);
    });
    emit(state.copyWith(kfList: kfList, oldKfList: oldkfList));
  }

  void add(Keyframe keyframe) {
    List<Keyframe> updatedKfList = List.from(state.kfList)..add(keyframe);
    emit(state.copyWith(kfList: updatedKfList));
  }

  /// 移除制定索引列表的关键帧，然后将其们保存到_oldKeyframe_开头的key中，并删除原来的Keyframe_开头的key
  void softDelete(List<int> indices) {
    List<Keyframe> updatedKfList = List.from(state.kfList);
    List<Keyframe> removedKeyframes = [];
    indices.sort((a, b) => b.compareTo(a)); // 从大到小排序，避免删除时索引错乱
    for (int index in indices) {
      if (index >= 0 && index < updatedKfList.length) {
        Keyframe item = updatedKfList[index];
        removedKeyframes.add(item);
        updatedKfList.removeAt(index);

        /// 在sharedpreference中删除原来的keyframe_开头的key，
        /// 并以_oldKeyframe_开头的key保存移除的关键帧
        SharedPrefsStorage.deleteData('keyframe_${item.name}');
        SharedPrefsStorage.save(
          key: 'oldKeyframe_${item.name}',
          jsonValue: json.encode(item.toJson()),
        );
      }
    }

    emit(
      state.copyWith(
        kfList: updatedKfList,
        oldKfList: state.oldKfList + removedKeyframes,
      ),
    );
    // emit(state.copyWith());
  }

  void delete(List<int> indices) {
    List<Keyframe> updatedKfList = List.from(state.oldKfList);
    indices.sort((a, b) => b.compareTo(a)); // 从大到小排序，避免删除时索引错乱
    for (int index in indices) {
      if (index >= 0 && index < updatedKfList.length) {
        Keyframe item = updatedKfList[index];
        updatedKfList.removeAt(index);
        SharedPrefsStorage.deleteData('oldKeyframe_${item.name}');
      }
    }

    emit(state.copyWith(oldKfList: updatedKfList, selectedIdxs: Set.from({})));
  }

  void active(List<int> indices) {
    List<Keyframe> updatedKfList = List.from(state.oldKfList);
    List<Keyframe> removedKeyframes = [];
    indices.sort((a, b) => b.compareTo(a)); // 从大到小排序，避免删除时索引错乱
    for (int index in indices) {
      if (index >= 0 && index < updatedKfList.length) {
        Keyframe item = updatedKfList[index];
        removedKeyframes.add(item);
        updatedKfList.removeAt(index);
        SharedPrefsStorage.deleteData('oldKeyframe_${item.name}');
        SharedPrefsStorage.save(
          key: 'keyframe_${item.name}',
          jsonValue: json.encode(item.toJson()),
        );
      }
    }

    emit(
      state.copyWith(
        kfList: state.kfList + removedKeyframes,
        oldKfList: updatedKfList,
        selectedIdxs: Set.from({}),
      ),
    );
  }

  /// 更新某一项
  void update(Keyframe keyframe) {
    List<Keyframe> updatedKfList = List.from(state.kfList);
    int index = updatedKfList.indexWhere((item) => item.name == keyframe.name);
    if (index != -1) {
      updatedKfList[index] = keyframe;
      emit(state.copyWith(kfList: updatedKfList));
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    List<Keyframe> updatedKfList = List.from(state.kfList);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Keyframe item = updatedKfList.removeAt(oldIndex);
    updatedKfList.insert(newIndex, item);
    updatedKfList[0].time = 0.0;
    updatedKfList[0].repeatCount = 0;
    emit(state.copyWith(kfList: updatedKfList));
  }

  void checkSelected(int index, bool isSelected) {
    Set<int> updatedSelectedIdxs = Set.from(state.selectedIdxs);
    if (isSelected) {
      updatedSelectedIdxs.add(index);
    } else {
      updatedSelectedIdxs.remove(index);
    }
    emit(state.copyWith(selectedIdxs: updatedSelectedIdxs));
  }

  void clearSelected() {
    emit(state.copyWith(selectedIdxs: {}));
  }
}
