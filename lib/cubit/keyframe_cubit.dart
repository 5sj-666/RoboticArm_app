import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'package:robotic_arm_app/utils/sharedPreferences.dart';
import 'dart:convert';

final logger = Logger();

/// 枚举类型type add edit
enum OptType { add, edit }

class KeyframeState {
  final List<Keyframe> kfList;
  final List<Keyframe> oldKfList;
  final Set<int> selectedIdxs;
  final List<Keyframe> editingKfList;
  final Motion? editingMotion;
  final OptType optType;

  KeyframeState({
    required this.kfList,
    required this.oldKfList,
    required this.selectedIdxs,
    required this.editingKfList,
    this.optType = OptType.add, // edit add
    this.editingMotion,
  });

  KeyframeState copyWith({
    List<Keyframe>? kfList,
    List<Keyframe>? oldKfList,
    List<Keyframe>? editingKfList,
    Set<int>? selectedIdxs,
    OptType? optType,
    Motion? editingMotion,
  }) {
    return KeyframeState(
      kfList: kfList ?? this.kfList,
      oldKfList: oldKfList ?? this.oldKfList,
      editingKfList: editingKfList ?? this.editingKfList,
      selectedIdxs: selectedIdxs ?? this.selectedIdxs,
      optType: optType ?? this.optType,
      editingMotion: editingMotion ?? this.editingMotion,
    );
  }
}

class KeyframeCubit extends Cubit<KeyframeState> {
  KeyframeCubit()
    : super(
        KeyframeState(
          kfList: [],
          oldKfList: [],
          editingKfList: [],
          selectedIdxs: {},
        ),
      ) {
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
  void softDelete(List<int> indices) async {
    if (state.optType == OptType.edit) {
      List<Keyframe> updatedKfList = List.from(state.editingKfList);
      indices.sort((a, b) => b.compareTo(a)); // 从大到小排序，避免删除时索引错乱
      for (int index in indices) {
        if (index >= 0 && index < updatedKfList.length) {
          updatedKfList.removeAt(index);
        }
      }
      emit(state.copyWith(editingKfList: updatedKfList));
      return;
    }

    List<Keyframe> updatedKfList = List.from(state.kfList);
    List<Keyframe> removedKeyframes = [];
    indices.sort((a, b) => b.compareTo(a)); // 从大到小排序，避免删除时索引错乱
    for (int index in indices) {
      if (index >= 0 && index < updatedKfList.length) {
        Keyframe item = updatedKfList[index];
        updatedKfList.removeAt(index);

        /// 在sharedpreference中删除原来的keyframe_开头的key，
        /// 如果SharedPrefsStorage中存在keyframe_ + item.name，则删除它并将其保存到oldKeyframe_ + item.name中
        /// 存在一种情况： 复制的帧，在SharedPrefsStorage中不存在
        Map<String, dynamic>? keyframeData = await SharedPrefsStorage.readJson(
          key: 'keyframe_${item.name}',
        );
        if (keyframeData != null && keyframeData.isNotEmpty) {
          // print(keyframeData);
          SharedPrefsStorage.deleteData('keyframe_${item.name}');
          removedKeyframes.add(item);

          /// 并以_oldKeyframe_开头的key保存移除的关键帧
          SharedPrefsStorage.save(
            key: 'oldKeyframe_${item.name}',
            jsonValue: json.encode(item.toJson()),
          );
        } else {
          print('未找到 key 为 ${item.name} 的数据');
        }
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
  void update(Keyframe kf) async {
    /// 编辑时的更新不要更新到持久化存储中。等用户保存编辑时，存到持久化的motion中。
    if (state.optType == OptType.edit) {
      List<Keyframe> updatedKfList = List.from(state.editingKfList);
      int index = updatedKfList.indexWhere((item) => item.name == kf.name);
      if (index != -1) {
        updatedKfList[index] = kf;
        emit(state.copyWith(editingKfList: updatedKfList));
      }
      return;
    }

    List<Keyframe> updatedKfList = List.from(state.kfList);
    int index = updatedKfList.indexWhere((item) => item.name == kf.name);
    if (index != -1) {
      updatedKfList[index] = kf;

      /// 先查询持久化存储中是否存在该key
      Map<String, dynamic>? keyframeData = await SharedPrefsStorage.readJson(
        key: '${kf.name}',
      );
      if (keyframeData != null && keyframeData.isNotEmpty) {
        /// 存在的话，更新至sharedpreference中
        SharedPrefsStorage.save(
          key: 'keyframe_${kf.name}',
          jsonValue: json.encode(kf.toJson()),
        );
      }
      emit(state.copyWith(kfList: updatedKfList));
    }
  }

  void reorderItems(int oldIndex, int newIndex) {
    bool isEditMode = state.optType == OptType.edit;
    List<Keyframe> updatedKfList = List.from(
      isEditMode ? state.editingKfList : state.kfList,
    );
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Keyframe item = updatedKfList.removeAt(oldIndex);
    updatedKfList.insert(newIndex, item);
    updatedKfList[0].time = 0.0;
    updatedKfList[0].repeatCount = 0;

    /// 同步更新到sharedpreference中
    for (Keyframe kf in updatedKfList) {
      SharedPrefsStorage.save(
        key: 'keyframe_${kf.name}',
        jsonValue: json.encode(kf.toJson()),
      );
    }
    if (isEditMode) {
      emit(state.copyWith(editingKfList: updatedKfList));
    } else {
      emit(state.copyWith(kfList: updatedKfList));
    }
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

  void duplicateItem(Keyframe kf) {
    String baseName = kf.name ?? 'copy';
    int suffix = 1;

    List<Keyframe> curList = state.optType == OptType.edit
        ? state.editingKfList
        : state.kfList;
    while (curList.any((item) => item.name == '${baseName}_$suffix')) {
      suffix++;
    }

    Keyframe newItem = Keyframe(
      name: '${baseName}_$suffix',
      time: kf.time,
      repeatCount: kf.repeatCount,
      timingFunction: kf.timingFunction,
      positions: List.from(kf.positions),
      createTime: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    if (state.optType == OptType.add) {
      // 更新关键帧列表并发出新状态
      emit(state.copyWith(kfList: List.from(state.kfList + [newItem])));
    } else if (state.optType == OptType.edit) {
      emit(
        state.copyWith(
          editingKfList: List.from(state.editingKfList + [newItem]),
        ),
      );
    }
  }

  void switchOptType(OptType type, Motion? motion) {
    emit(state.copyWith(optType: type));
    if (type == OptType.edit) {
      List<Keyframe> editingKfList = List.from(motion!.keyframes);
      emit(state.copyWith(editingKfList: editingKfList, editingMotion: motion));
    } else {
      emit(state.copyWith(editingKfList: [], editingMotion: null));
    }
  }

  void saveEdit() {
    /// 在motionsCubit中更新当前motion数据
    /// 在sharedpreference中更新motion数据
    /// 重新计算时间轴上的时间点
    List<Keyframe> kf = List.from(state.editingKfList);
    // List<>Keyframe> updatedKfList = List.from(state.editingKfList);
    for (int i = 0; i < kf.length; i++) {
      // 第一帧的时间必须为0
      if (i == 0) {
        kf[i].markerTimeStart = 0;
        kf[i].markerTimeEnd = 0;
      } else {
        final repeatTime = kf[i].repeatCount * kf[i].time * 2;
        kf[i].markerTimeEnd = kf[i - 1].markerTimeEnd + repeatTime + kf[i].time;
        kf[i].markerTimeStart = kf[i - 1].markerTimeEnd;
      }
    }
    state.editingMotion!.keyframes = kf;

    SharedPrefsStorage.save(
      key: 'motion_${state.editingMotion!.name}',
      jsonValue: json.encode(state.editingMotion!.toJson()),
    );
  }

  void add2EditingKf() {
    state.selectedIdxs;
    final kfList = state.kfList + state.oldKfList;
    List<Keyframe> selectedKf = [];
    for (int index in state.selectedIdxs) {
      if (index >= 0 && index < kfList.length) {
        selectedKf.add(kfList[index]);
      }
    }
    emit(
      state.copyWith(
        editingKfList: state.editingKfList + selectedKf,
        selectedIdxs: Set.from({}),
      ),
    );
  }
}
