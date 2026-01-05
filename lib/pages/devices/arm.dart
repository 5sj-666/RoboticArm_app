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
// import 'dart:typed_data';
// import 'package:robotic_arm_app/utils/motorCmd.dart';

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

    // jointsCubit = BlocProvider.of<JointsCubit>(context);

    // 初始化关节cubit
    // jointsCubit = JointsCubit();
    // Future.delayed(const Duration(seconds: 5), () {
    //   jointsCubit.setSingleJoint('joint1', 100.0);
    // });
    // Future.delayed(const Duration(seconds: 10), () {
    //   jointsCubit.setJoints(Joints(
    //       joint1: 45.0,
    //       joint2: 30.0,
    //       joint3: 15.0,
    //       joint4: 60.0,
    //       joint5: 90.0));
    // });
    // print('当前关节6: ${jointsCubit.state.joint6}');
    // jointsCubit.stream.listen((joints) {
    //   print('当前j1值: ${joints.joint1}');
    // });
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

  // initScene() {
  //   this.scene = new THREE.Scene()
  //   // this.scene.background = new THREE.Color(0xa0a0a0);
  //   this.scene.add( new THREE.GridHelper( 5, 10, 0x888888, 0x444444 ) );
  //   // this.scene.fog = new THREE.Fog(0x000000, 0, 10000) // 添加雾的效果
  // }

  Future<void> setup() async {
    // joystick = threeJs.width < 850
    //     ? three.Joystick(
    //         size: 150,
    //         margin: const EdgeInsets.only(left: 35, bottom: 35),
    //         screenSize: Size(threeJs.width, threeJs.height),
    //         listenableKey: threeJs.globalKey)
    //     : null;

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

    // addGltfAsset('cybergearmotor.stp.glb', 'cyber_gear');

    // final zero = await addGltfAsset('zero.glb', 'zero');
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

    // // 获取当前位置
    // var joints = jointsCubit.state;
    // // 获取当前动作关键帧
    // final currentMotion = motionsCubit.state.currentMotion;

    // // 获取当前关键帧
    // var len = currentMotion.children.length;
    // print('--初始化len: $len');
    // var kryframeList = currentMotion.children;

    // double elapsedTime = 0.0;
    // // ignore: unused_local_variable
    // Keyframe preKeyframe = Keyframe(
    //   name: '',
    //   timingFunction: '',
    //   time: 0,
    //   children: [],
    // );
    // Keyframe keyframe = Keyframe(
    //   name: '',
    //   timingFunction: '',
    //   time: 0,
    //   children: [],
    // );
    // // 各个关键的偏差数据
    // // ignore: unused_local_variable
    // List<double> deltaDeg = [
    //   joints.joint1,
    //   joints.joint2,
    //   joints.joint3,
    //   joints.joint4,
    //   joints.joint5,
    //   joints.joint6,
    // ];
    // int deltaTime = 0;

    // 类似web的requestAniamtionFrame
    threeJs.addAnimationEvent((dt) {
      // oneWrapper.rotation.y += 0.1;
      // print('---执行动画');
      // jointsCubit.state.joint1 += 0.1;
      // jointsCubit.setSingleJoint('joint1', jointsCubit.state.joint1 + 0.1);

      // threeJs.renderer?.render(threeJs.scene, threeJs.camera);
      // 渲染场景
      // threeJs.renderer!.render(threeJs.scene, threeJs.camera);

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
          }
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
              double? ratio = bezierXToY(t, [.2, .2], [.5, .5]);
              // double? ratio = calculateBezierY(
              //     (rt.elapsedTime - rt.preKeyframe!.time) /
              //       (rt.curKeyframe!.time - rt.preKeyframe!.time),
              //   [.2, .2],[.5, .5]);
              // ratio = ratio;
              print('t: $t ratio: $ratio');

              var jointsFrame = rt.curKeyframe?.children ?? [];
              for (int j = 0; j < jointsFrame.length; j++) {
                // print('j$j');
                rt.deltaDeg[j] =
                    rt.curKeyframe!.children[j].location -
                    rt.preKeyframe!.children[j].location;

                double deg =
                    rt.deltaDeg[j] * ratio +
                    rt.preKeyframe!.children[j].location;
                jointsCubit.setSingleJoint('joint${j + 1}', deg);
                // 单片机需要 i *2 是位置， i* 2 + 1是速度
                rt.result[j * 2] = deg / 180 * math.pi;
                // delta距离 / delta时间 = 速度
                rt.result[j * 2 + 1] =
                    (rt.deltaDeg[j] * ratio - rt.deltaDeg[j] * rt.preRatio) /
                    dt /
                    180 *
                    math.pi;

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
            // motionsCubit.updateState(false);
            // motionsCubit.updateStatus(MotionStatus.finished);
            motionsCubit.updateStatus(MotionStatus.prepare);
            rt.elapsedTime = 0;
          }

          print(
            '当前关键帧 ${(rt.elapsedTime * 1000).toInt()} : ${rt.curKeyframe?.name}',
          );

          /// 应该需要准备动作：移动到第一帧，之后才可以运行动作。  预备动作，最后开发
          ///
          /// 执行动画需要两个帧：开始帧（preFrame）和结束帧（当前要移动到的帧curFrame）
          // preKeyframe keyframe
          /// 计算出差值，
          ///
          /// 计算当前当前时间的位置

          // jointsCubit.state.toJson().forEach((name, value) {
          //   jointsCubit.state[name]
          // });
          // for(int z = 0; z < jointsCubit.state) {

          // }
        }
      } else {
        if (motionsCubit.state.status == MotionStatus.prepare ||
            motionsCubit.state.status == MotionStatus.ready) {
          rt.elapsedTime = 0;
        }
      }
    });

    // /// 经过三次贝塞尔曲线计算的位置
    // void computedPositionByCubicBezier() {

    // }

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
      // let oneDegree = math.pi / 180;
      // gltf.scene.rotation(oneDegree * 0, oneDegree * 90, oneDegree * 270);
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
