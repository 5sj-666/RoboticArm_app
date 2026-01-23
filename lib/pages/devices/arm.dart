import 'package:flutter/material.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:flutter/services.dart';
import 'package:robotic_arm_app/utils/bezierX2Y.dart';
import 'package:robotic_arm_app/pages/devices/motor/motorLogCubit.dart';
import 'package:robotic_arm_app/cubit/ble_cubit.dart';
import 'package:robotic_arm_app/cubit/motions_cubit.dart';
import 'package:robotic_arm_app/cubit/joints_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ArmPage extends StatefulWidget {
  const ArmPage({super.key});

  @override
  FlutterGameState createState() => FlutterGameState();
}

class FlutterGameState extends State<ArmPage> {
  late three.ThreeJS threeJs;
  late JointsCubit jointsCubit;
  late MotionsCubit motionsCubit;
  late BleCubit bleCubit;
  late MotorLogCubit motorLogCubit;

  late RunTimeWorkSpace rt;
  // '准备中'阶段需要记录初始位置，以便计算回到第一帧位置时的过渡值计算
  late List preparingInitPosition;

  // late

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      onSetupComplete: () {
        setState(() {});
      },
      setup: setup,
    );

    // 在这里安全获取 context 相关的依赖
    jointsCubit = BlocProvider.of<JointsCubit>(context);
    motionsCubit = BlocProvider.of<MotionsCubit>(context);
    motorLogCubit = BlocProvider.of<MotorLogCubit>(context);
    bleCubit = BlocProvider.of<BleCubit>(context);

    rt = RunTimeWorkSpace(curMotion: motionsCubit.state.currentMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    rt = RunTimeWorkSpace(curMotion: motionsCubit.state.currentMotion);
  }

  @override
  void dispose() {
    super.dispose();
    threeJs.dispose();
    three.loading.clear();
    joystick?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    return isCurrent
        ? FocusScope(
            // 当不可见时禁止请求焦点，进一步避免抢焦点
            canRequestFocus: true,
            child: threeJs.build(),
          )
        : FocusScope(
            // 当不可见时禁止请求焦点，进一步避免抢焦点
            canRequestFocus: false,
            child: threeJs.build(),
          );
  }

  Map<LogicalKeyboardKey, bool> keyStates = {
    LogicalKeyboardKey.space: false,
    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
  };

  double gravity = 30;
  int stepsPerFrame = 5;
  three.Joystick? joystick; // 手柄

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(
      45,
      threeJs.width / threeJs.height,
      1,
      2200,
    );
    threeJs.camera.position.setValues(10, 8, 8);
    threeJs.scene = three.Scene();
    // init();

    final gridHelper = GridHelper(100, 100, 0x888888, 0x444444);
    threeJs.scene.add(gridHelper);

    final axesHelper = AxesHelper(5);
    threeJs.scene.add(axesHelper);

    final ambientLight = three.AmbientLight(0xffffff, 0.3);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.1);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    final orbitControle = three.OrbitControls(
      threeJs.camera,
      threeJs.globalKey,
    );
    orbitControle.update();

    await addGltfAsset('zero.glb', 'zero');
    var oneWrapper = three.Object3D();
    oneWrapper.position.x = 0.5;
    oneWrapper.position.y = 0.4;
    // oneWrapper.add(new THREE.AxesHelper(2));
    // oneWrapper.position.z = 1;
    threeJs.scene.add(oneWrapper);
    // oneWrapper.add(new THREE.AxesHelper(2));
    var one = await addGltfAsset('one.glb', 'one');

    //
    var twoWrapper = three.Object3D();
    twoWrapper.position.x = 0;
    twoWrapper.position.y = 0.25;
    twoWrapper.position.z = -0.32;
    threeJs.scene.add(twoWrapper);
    // twoWrapper.add(new THREE.AxesHelper(2));
    var two = await addGltfAsset('two.glb', 'two');

    //
    var threeWrapper = three.Object3D();
    threeWrapper.position.x = 0;
    threeWrapper.position.y = 1.5;
    threeWrapper.position.z = -0.02;
    threeJs.scene.add(threeWrapper);
    // threeWrapper.add(new THREE.AxesHelper(2));
    var threeGltf = await addGltfAsset('three.glb', 'three');

    //
    var fourWrapper = three.Object3D();
    fourWrapper.position.x = 0.175;
    fourWrapper.position.y = 0.32;
    fourWrapper.position.z = 0.32;
    threeJs.scene.add(fourWrapper);
    // fourWrapper.add(new THREE.AxesHelper(2));
    var four = await addGltfAsset('four.glb', 'four');

    //
    var fiveWrapper = three.Object3D();
    fiveWrapper.position.x = 0;
    fiveWrapper.position.y = 1.25;
    fiveWrapper.position.z = 0.197;
    threeJs.scene.add(fiveWrapper);
    // fiveWrapper.add(new THREE.AxesHelper(2));
    var five = await addGltfAsset('five.glb', 'five');

    // 类似web的requestAniamtionFrame
    threeJs.addAnimationEvent((dt) {
      //这里添加动画效果
      if (motionsCubit.state.status == MotionStatus.goToZero) {
        if (rt.elapsedTime == 0.0) {
          preparingInitPosition = List.from([
            jointsCubit.state.joint1,
            jointsCubit.state.joint2,
            jointsCubit.state.joint3,
            jointsCubit.state.joint4,
            jointsCubit.state.joint5,
            jointsCubit.state.joint6,
          ]);
          for (int i = 0; i < 6; i++) {
            rt.deltaDeg[i] = 0.0 - preparingInitPosition[i];

            rt.result[i * 2] = 0.0;
            rt.result[i * 2 + 1] = (rt.deltaDeg[i] / 2.0).clamp(0, 15);
          }
          // 如果当前的动作位置和目标位置完全一致，则直接切换到ready状态
          bool allZero = rt.deltaDeg.every((deg) => deg.abs() < 0.001);
          if (allZero) {
            motionsCubit.updateStatus(MotionStatus.idle);
            return;
          }
        }
        // 将机械臂姿态移动到第一帧位置
        rt.elapsedTime += dt;
        // 直接是等比例速度移动到第一帧位置, 过渡时间为2秒
        double progress = (rt.elapsedTime) / 2.0;

        if (progress >= 1.0) {
          for (int j = 0; j < 6; j++) {
            jointsCubit.setSingleJoint('joint${j + 1}', 0.0);
          }
          // 准备完成，切换到ready状态
          motionsCubit.updateStatus(MotionStatus.idle);
          rt.elapsedTime = 0.0;
        } else {
          for (int j = 0; j < 6; j++) {
            double deg = rt.deltaDeg[j] * progress + preparingInitPosition[j];
            jointsCubit.setSingleJoint(
              'joint${j + 1}',
              deg.clamp(-145.0, 145.0),
            );
          }
        }

        // print('gotozero: $progress, --- ');
      } else if (motionsCubit.state.status == MotionStatus.preparing) {
        print('---准备动作中');
        if (rt.elapsedTime == 0.0) {
          // 目标关节位置在于动作的第一帧
          rt.curKeyframe = rt.keyframeList[0];

          preparingInitPosition = [
            jointsCubit.state.joint1,
            jointsCubit.state.joint2,
            jointsCubit.state.joint3,
            jointsCubit.state.joint4,
            jointsCubit.state.joint5,
            jointsCubit.state.joint6,
          ];
          for (int i = 0; i < rt.curKeyframe!.positions.length; i++) {
            rt.deltaDeg[i] =
                rt.curKeyframe!.positions[i] - preparingInitPosition[i];

            // 因为是初始化，所以将匀速位置和速度直接发送给单片机
            rt.result[i * 2] = (rt.curKeyframe!.positions[i] / 180 * math.pi)
                .clamp(-145.0, 145.0);
            rt.result[i * 2 + 1] = (rt.deltaDeg[i] / 2.0).clamp(0, 15);
          }
          bleCubit.sendMsg(rt.result);
          print('---准备动作中，目标位置差值: ${rt.deltaDeg}');
          print('-- currentPositions $preparingInitPosition');

          // 如果当前的动作位置和目标位置完全一致，则直接切换到ready状态
          bool allZero = rt.deltaDeg.every((deg) => deg.abs() < 0.01);
          if (allZero) {
            motionsCubit.updateStatus(MotionStatus.ready);
            return;
          }
        }
        // 将机械臂姿态移动到第一帧位置
        rt.elapsedTime += dt;
        // 直接是等比例速度移动到第一帧位置, 过渡时间为2秒
        double progress = (rt.elapsedTime) / 2.0;

        // 最后一帧有溢出的可能性，比如progress = 1.0079999999999987,
        if (progress >= 1.0) {
          for (int j = 0; j < rt.curKeyframe!.positions.length; j++) {
            double deg = rt.deltaDeg[j] * 1 + preparingInitPosition[j];
            jointsCubit.setSingleJoint(
              'joint${j + 1}',
              deg.clamp(-145.0, 145.0),
            );
          }
          // 准备完成，切换到ready状态
          motionsCubit.updateStatus(MotionStatus.ready);
          rt.elapsedTime = 0.0;
        } else {
          for (int j = 0; j < rt.curKeyframe!.positions.length; j++) {
            double deg = rt.deltaDeg[j] * progress + preparingInitPosition[j];
            jointsCubit.setSingleJoint(
              'joint${j + 1}',
              deg.clamp(-145.0, 145.0),
            );
          }
        }
      } else if (motionsCubit.state.status == MotionStatus.running) {
        // print('---运行动画${rt.len}');
        rt.elapsedTime += dt;

        /// 如歌当前关键帧的指针 大于 关键帧列表的最大下标值，则直接结束
        if (rt.keyframeCursor >= rt.len) {
          motionsCubit.updateStatus(MotionStatus.prepare);
          rt.elapsedTime = 0;
          rt.keyframeCursor = 0;

          // 结束时将剩余的指令抽帧发出
          combinPostion(rt.results, bleCubit);
          rt.results.clear();
          rt.curSize = 0;
          return;
        }

        /// 关键帧数量要大于等于2帧
        if (rt.len > 1) {
          /// 判断是否有当前关键帧, 没有的话：初始化赋值
          if (rt.curKeyframe == null) {
            rt.curKeyframe = rt.keyframeList[rt.keyframeCursor];
            rt.preKeyframe = rt.keyframeList[rt.keyframeCursor];
          }

          /// 如果当前的经历时间大于当前关键帧的时间，则需要赋值下一个关键帧
          if (rt.elapsedTime >= rt.curKeyframe!.time) {
            rt.keyframeCursor += 1;

            /// 切换关键帧可能导致方向变化，会影响计算，所以直接存储的帧直接计算并发送
            combinPostion(rt.results, bleCubit);
            rt.results.clear();
            rt.curSize = 0;

            /// 超出关键帧数量。直接结束
            if (rt.keyframeCursor >= rt.len) {
              motionsCubit.updateStatus(MotionStatus.prepare);
              rt.elapsedTime = 0;
              rt.keyframeCursor = 0;
              return;
            }
            rt.curKeyframe = rt.keyframeList[rt.keyframeCursor];
            rt.preKeyframe = rt.keyframeList[rt.keyframeCursor - 1];

            // if (rt.curKeyframe!.time <= rt.preKeyframe!.time) {
            //   motionsCubit.updateStatus(MotionStatus.prepare);
            //   rt.elapsedTime = 0;
            //   rt.keyframeCursor = 0;
            //   return;
            // }

            /// 计算时间差
            rt.deltaTime = rt.curKeyframe!.time - rt.preKeyframe!.time;

            /// 计算位置差
            for (int i = 0; i < rt.curKeyframe!.positions.length; i++) {
              rt.deltaDeg[i] =
                  rt.curKeyframe!.positions[i] - rt.preKeyframe!.positions[i];
            }

            /// 获取控制点
            rt.controlPoints = timingFuncToDoubleList(
              rt.curKeyframe!.timingFunction,
            );
          }

          /// 接下来要计算当前时刻的位置
          /// 第一步： 获取当前时的时间 在 总时间 里的百分几
          double t =
              (rt.elapsedTime - rt.preKeyframe!.time) /
              (rt.curKeyframe!.time - rt.preKeyframe!.time);

          t = t.clamp(0, 1);

          /// 获取t时间时对应的y值
          double? ratio = bezierXToY(
            t,
            [rt.controlPoints[0], rt.controlPoints[1]],
            [rt.controlPoints[2], rt.controlPoints[3]],
          );

          /// 6个关节
          for (int i = 0; i < 6; i++) {
            /// 此处可能有bug，比如关键帧的children如果不是必须6帧（待校验），可能会导致赋值bug
            // 当前位置是基于上一帧的位置的增量
            double curDeg =
                rt.deltaDeg[i] * ratio + rt.preKeyframe!.positions[i];
            jointsCubit.setSingleJoint('joint${i + 1}', curDeg);

            /// 位置： 单片机需要 i *2 是位置，  边界值为-145.0, 145.0
            rt.result[i * 2] = (curDeg / 180 * math.pi).clamp(-145.0, 145.0);

            /// 速度： delta距离 / delta时间 = 速度 边界值为0.0, 15.0
            rt.result[i * 2 + 1] =
                ((rt.deltaDeg[i] * ratio - rt.deltaDeg[i] * rt.preRatio) /
                        dt /
                        180 *
                        math.pi)
                    .clamp(-15.0, 15.0);
          }

          print('位置指令: ${rt.result}');

          /// 由于发送指令太快会导致指令积压，造成动作严重延迟
          /// 所以在此做抽帧操作，比如将10个帧抽离合并成一个帧发送
          rt.results.add(List.from(rt.result));
          rt.curSize += 1;

          /// 滑动窗口思想
          if (rt.curSize == rt.windowSize) {
            combinPostion(rt.results, bleCubit);
            rt.results.clear();
            rt.curSize = 0;
            // print('rt.results长度: ${rt.results.length}');
          }

          rt.preRatio = ratio;
        }
      } else {
        if (motionsCubit.state.status == MotionStatus.prepare ||
            motionsCubit.state.status == MotionStatus.ready) {
          rt.elapsedTime = 0;
        }
      }
    });

    // 启用抗锯齿
    try {
      threeJs.renderer = three.WebGLRenderer({
        'antialias': true, // 启用抗锯齿
        'alpha': true, // 可选：启用透明背景
      });

      threeJs.renderer?.setSize(threeJs.width, threeJs.height); // 设置渲染器大小
      threeJs.renderer?.autoClear = false; // 允许覆盖渲染
      print('Renderer initialized successfully with antialiasing');
    } catch (e) {
      print('Error initializing renderer: $e');
    }

    // To allow render overlay on top of sprited sphere 允许在精灵球顶部渲染覆盖内容
    threeJs.renderer?.autoClear = false;

    void render() {
      threeJs.addAnimationEvent((dt) {
        oneWrapper.add(one?.scene);
        oneWrapper.add(twoWrapper);

        twoWrapper.add(two?.scene);
        twoWrapper.add(threeWrapper);

        threeWrapper.add(threeGltf?.scene);
        threeWrapper.add(fourWrapper);

        fourWrapper.add(four?.scene);
        fourWrapper.add(fiveWrapper);

        fiveWrapper.add(five?.scene);

        oneWrapper.rotation.y = -(jointsCubit.state.joint1 * math.pi) / 180;
        twoWrapper.rotation.z = -(jointsCubit.state.joint2 * math.pi) / 180;
        threeWrapper.rotation.z = -(jointsCubit.state.joint3 * math.pi) / 180;
        fourWrapper.rotation.y = -(jointsCubit.state.joint4 * math.pi) / 180;
        fiveWrapper.rotation.z = -(jointsCubit.state.joint5 * math.pi) / 180;

        threeJs.renderer?.render(threeJs.scene, threeJs.camera);
      });
    }

    render();
  }

  void initMesh() {}

  addGltfAsset(name, type) async {
    three.GLTFLoader loader = three.GLTFLoader(flipY: true).setPath('assets/');
    final gltf = await loader.fromAsset(name);
    threeJs.scene.add(gltf!.scene);
    initGLTF(gltf, type);
    return gltf;
  }

  void initGLTF(gltf, type) {
    gltf.scene.scale = three.Vector3(5, 5, 5);

    if (type == 'zero') {
      gltf.scene.translateX(0.5);
    } else if (type == 'one') {
      gltf.scene.translateX(0.5);
      gltf.scene.translateX(-0.5);
    } else if (type == 'two') {
      gltf.scene.translateZ(-0.2);
      double oneDegree = math.pi / 180;
      gltf.scene.rotation.set(oneDegree * 90, oneDegree * 90, oneDegree * 0.0);
    } else if (type == 'three') {
      gltf.scene.rotation.set(math.pi / 2, math.pi / 180 * -116, 0.0);
    } else if (type == 'four') {
      gltf.scene.rotation.set(0.0, math.pi / 180 * 90, math.pi / 180 * -90);
      gltf.scene.translateX(-1.25);
      gltf.scene.translateY(-0.35);
    } else if (type == 'five') {
      gltf.scene.rotation.set(
        math.pi / 180 * 0.0,
        math.pi / 180 * 270,
        math.pi / 180 * 90,
      );
    }
  }
}

class BleMsgPositions {
  List<double> postions = List.filled(12, 0.0);
  BleMsgPositions(this.postions);
}

///  运行动作时的变量
class RunTimeWorkSpace {
  Motion? curMotion;
  List<Keyframe> keyframeList;

  /// 用来记录当前运行到第几帧关键帧
  int keyframeCursor;
  Keyframe? curKeyframe;
  Keyframe? preKeyframe;
  int len;
  double elapsedTime;
  List<double> deltaDeg;
  double deltaTime;
  List<double> controlPoints;
  //最终需要的位置和速度信息
  List<double> result;
  double preRatio;
  // 用来计算与上一帧的时间差，因为有可能并非严格等差时间。
  // double preElapsedTime;
  /// 由于发送指令太快，会造成指令积压，导致电机执行时间严重拉长，所以在此做合并帧操作，将四帧数合并成一帧
  List<List<double>> results;
  // 合并帧数量
  int windowSize;
  int curSize;

  RunTimeWorkSpace({
    required this.curMotion,
    this.keyframeList = const [],
    this.keyframeCursor = 0,
    this.curKeyframe,
    this.preKeyframe,
    this.len = 0,
    this.elapsedTime = 0.0,
    this.deltaDeg = const [],
    this.deltaTime = 0,
    this.controlPoints = const [.2, .2, .5, .5],
    this.result = const [],
    this.preRatio = 0.0,
    this.results = const [],
    this.windowSize = 30,
    this.curSize = 0,
  }) {
    keyframeList = curMotion?.keyframes ?? const [];
    curKeyframe =
        curMotion?.keyframes[1] ??
        Keyframe(name: '', timingFunction: '', time: 0, positions: []);
    preKeyframe =
        curMotion?.keyframes[1] ??
        Keyframe(name: '', timingFunction: '', time: 0, positions: []);
    len = curMotion?.keyframes.length ?? 0;

    deltaDeg = List<double>.filled(6, 0.0);
    result = List<double>.filled(12, 0.0);
    results = List.filled(0, [], growable: true);
  }
}

/// 将缓动函数（如 '.2,.2,.5,.5'）转为 List<double> [.2,.2,.5,.5]
List<double> timingFuncToDoubleList(String? input) {
  // 1. 边界处理：空字符串直接返回匀速
  if (input == null || input.isEmpty) return [.2, .2, .5, .5];

  // 2. 按逗号拆分字符串 → 遍历处理每个子项
  return input.split(',').map((String item) {
    // 3. 去除子项前后空格（处理 '.2, .2, .5' 这种带空格的场景）
    String trimmedItem = item.trim();

    // 4. 尝试将字符串转为 double（处理无效数值）
    double? numValue = double.tryParse(trimmedItem);

    // 5. 无效数值返回 0.0（也可根据业务需求返回 null 再过滤）
    return numValue ?? 0.0;
  }).toList();
}

/// 合并帧，将多个帧合并起来，并发送给单片机
// List<double> combinPostion(List<List<double>> positionArr) {
void combinPostion(List<List<double>> positionArr, BleCubit bleCubit) {
  List<double> result = List.filled(12, 0.0, growable: false);
  print('combinPostion: ${positionArr.toString()}');

  /// 位置只取最后一帧
  for (int i = 0; i < positionArr.length; i++) {
    for (int j = 0; j < positionArr[i].length; j++) {
      if (j % 2 == 0) {
        // i是位置
        // 最后一个数组时候，直接将位置赋值给result
        if (i == positionArr.length - 1) {
          result[j] = positionArr[i][j];
        }
      } else {
        // i + 1是速度
        /// 平均速度就是 所有速度的总和 / 个数, 设置最小转动速度，以免指令积压
        result[j] += (positionArr[i][j] / positionArr.length);
        // result[j] += positionArr[i][j] / positionArr.length;
        // result[j] = 2.0;
      }
    }

    /// 设置最低和最高速度
    for (int i = 0; i < result.length; i++) {
      if (i % 2 == 1) {
        result[i] = result[i].abs().clamp(0.5, 15);
      }
    }
  }
  print('---合并帧$result');

  bleCubit.sendMsg(result);

  /// 返回结果帧
  // return result;
}
