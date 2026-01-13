import 'package:flutter/material.dart';
import 'package:robotic_arm_app/types/motions.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:flutter/services.dart';
import 'package:robotic_arm_app/utils/bezierX2Y.dart';
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
      if (motionsCubit.state.status == MotionStatus.preparing) {
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
          for (int i = 0; i < rt.curKeyframe!.children.length; i++) {
            rt.deltaDeg[i] =
                rt.curKeyframe!.children[i].location - preparingInitPosition[i];

            // 因为是初始化，所以将匀速位置和速度直接发送给单片机
            rt.result[i * 2] =
                rt.curKeyframe!.children[i].location / 180 * math.pi;
            rt.result[i * 2 + 1] = 2.0;
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

        for (int j = 0; j < rt.curKeyframe!.children.length; j++) {
          double deg = rt.deltaDeg[j] * progress + preparingInitPosition[j];
          jointsCubit.setSingleJoint('joint${j + 1}', deg);
        }

        if (progress >= 1.0) {
          // 准备完成，切换到ready状态
          motionsCubit.updateStatus(MotionStatus.ready);
          rt.elapsedTime = 0.0;
        }
      } else if (motionsCubit.state.status == MotionStatus.running) {
        print('---运行动画${rt.len}');
        // print('dt: $dt, ${(elapsedTime * 1000).toInt()}');
        rt.elapsedTime += dt;

        if (rt.len > 0) {
          int i = 0;
          for (i; i < rt.len; i++) {
            /// 关键帧时间大于elapsedTime，表明当前帧正在执行
            if (rt.keyframeList[i].time > (rt.elapsedTime * 1000).toInt()) {
              rt.curKeyframe = rt.keyframeList[i];
              rt.preKeyframe = i > 0 ? rt.keyframeList[i - 1] : rt.curKeyframe;
              // 计算位置差
              /// 计算时间差
              rt.deltaTime = rt.curKeyframe!.time - rt.preKeyframe!.time;
              double t =
                  ((rt.elapsedTime * 1000).toInt() - rt.preKeyframe!.time) /
                  (rt.curKeyframe!.time - rt.preKeyframe!.time);

              List<double> cp = timingFuncToDoubleList(
                rt.curKeyframe!.timingFunction,
              );

              double? ratio = bezierXToY(t, [cp[0], cp[1]], [cp[2], cp[3]]);

              print('t: $t ratio: $ratio');

              var jointsFrame = rt.curKeyframe?.children ?? [];
              for (int j = 0; j < jointsFrame.length; j++) {
                rt.deltaDeg[j] =
                    rt.curKeyframe!.children[j].location -
                    rt.preKeyframe!.children[j].location;

                double deg =
                    rt.deltaDeg[j] * ratio +
                    rt.preKeyframe!.children[j].location;
                jointsCubit.setSingleJoint('joint${j + 1}', deg);
                // 单片机需要 i *2 是位置， i* 2 + 1是速度 边界值为0 ～ 15
                rt.result[j * 2] = (deg / 180 * math.pi).clamp(0.0, 15.0);
                // delta距离 / delta时间 = 速度 边界值为-145和145
                rt.result[j * 2 + 1] =
                    ((rt.deltaDeg[j] * ratio - rt.deltaDeg[j] * rt.preRatio) /
                            dt /
                            180 *
                            math.pi)
                        .clamp(-145.0, 145.0);

                print(
                  '距离差额比例: ${ratio - rt.preRatio} 距离差额$deg, 时间差额: $dt, 历经时间${rt.elapsedTime}',
                );
              }
              rt.preRatio = ratio;

              print('deltaTime: ${rt.deltaTime} ${rt.result}');
              bleCubit.sendMsg(rt.result);
              break;
            }
          }
          if (i == rt.len) {
            motionsCubit.updateStatus(MotionStatus.prepare);
            rt.elapsedTime = 0;
          }

          print(
            '当前关键帧 ${(rt.elapsedTime * 1000).toInt()} : ${rt.curKeyframe?.name}, i: $i',
          );
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
  Keyframe? curKeyframe;
  Keyframe? preKeyframe;
  int len;
  double elapsedTime;
  List<double> deltaDeg;
  int deltaTime;
  //最终需要的位置和速度信息
  List<double> result;
  double preRatio;
  // 用来计算与上一帧的时间差，因为有可能并非严格等差时间。
  // double preElapsedTime;

  RunTimeWorkSpace({
    required this.curMotion,
    this.keyframeList = const [],
    this.curKeyframe,
    this.preKeyframe,
    this.len = 0,
    this.elapsedTime = 0.0,
    this.deltaDeg = const [],
    this.deltaTime = 0,
    this.result = const [],
    this.preRatio = 0.0,
  }) {
    keyframeList = curMotion?.children ?? const [];
    curKeyframe =
        curMotion?.children[1] ??
        Keyframe(name: '', timingFunction: '', time: 0, children: []);
    preKeyframe =
        curMotion?.children[1] ??
        Keyframe(name: '', timingFunction: '', time: 0, children: []);
    len = curMotion?.children.length ?? 0;

    deltaDeg = List<double>.filled(6, 0.0);
    result = List<double>.filled(12, 0.0);
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
