import 'dart:typed_data';

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
import 'package:robotic_arm_app/cubit/ik_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:three_js_objects/three_js_objects.dart';
// import 'package:three_js_controls/three_js_controls.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';
// import 'package:robotic_arm_app/utils/kinematics.dart';
// import 'package:robotic_arm_app/utils/ik.dart';
// import 'package:robotic_arm_app/utils/kinematics_grok.dart';
// import 'package:robotic_arm_app/utils/km_chatgpt.dart';
// import 'package:vector_math/vector_math_64.dart';
// import 'package:robotic_arm_app/utils/km_simple.dart';
import 'package:robotic_arm_app/utils/km_simple_gemini.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

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
  late IKCubit ikCubit;

  late RunTimeWorkSpace rt;
  // '准备中'阶段需要记录初始位置，以便计算回到第一帧位置时的过渡值计算
  late List preparingInitPosition;

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
    ikCubit = BlocProvider.of<IKCubit>(context);

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
    threeJs.camera.position.setValues(2.5, 0.6, 0);
    threeJs.scene = three.Scene();
    // init();

    // final gridHelper = GridHelper(5, 5, 0x888888, 0x444444);
    // final gridHelper = GridHelper(2, 2, 0xffffff, 0xffffff);
    // threeJs.scene.add(gridHelper);

    final axesHelper = AxesHelper(1);
    threeJs.scene.add(axesHelper);

    // 创建 Sky 对象
    final sky = Sky.create();
    // 设置天空的缩放比例
    sky.scale.setScalar(45000);
    // 将 Sky 添加到场景中
    threeJs.scene.add(sky);
    // 配置天空的属性
    final uniforms = sky.material!.uniforms;

    // 设置大气参数
    uniforms['turbidity']['value'] = 10.0; // 浑浊度
    uniforms['rayleigh']['value'] = 2.0; // 瑞利散射系数
    uniforms['mieCoefficient']['value'] = 0.005; // 米散射系数
    uniforms['mieDirectionalG']['value'] = 0.8; // 米散射方向性

    // 设置太阳的位置
    final sunPosition = three.Vector3(100, 10, -50);
    uniforms['sunPosition']['value'] = sunPosition;

    final geometry = three.PlaneGeometry(100, 100); // 创建一个 1000x1000 的平面
    final options = WaterOptions(
      color: 0x00BFFF, // 水的颜色
      scale: 4.0, // 水面波纹的缩放比例
      flowSpeed: 0.02, // 水流速度
      reflectivity: 0.5, // 反射率
    );
    final water = Water(geometry, options);
    water.rotation.x = -math.pi / 2; // 将水面旋转为水平面
    water.position.y = -0.5;
    // threeJs.scene.add(water);

    final directionalLight = three.DirectionalLight(0xffffff, 0.5);
    directionalLight.position.setValues(100, 10, -50);
    threeJs.scene.add(directionalLight);

    final ambientLight = three.AmbientLight(0xffffff, 0.8);
    threeJs.scene.add(ambientLight);

    // final pointLight = three.PointLight(0xffffff, 0.5, 0, 0);

    // pointLight.position.setValues(10, 10, 10);

    // threeJs.scene.add(pointLight);
    threeJs.scene.add(ambientLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    final orbitControle = three.OrbitControls(
      threeJs.camera,
      threeJs.globalKey,
    );
    orbitControle.update();

    var zeroWrapper = three.Object3D();
    zeroWrapper.position.y = 0;
    threeJs.scene.add(zeroWrapper);
    var zero = await addGltfAsset('zero.glb', 'zero');
    zeroWrapper.add(AxesHelper(0.2));
    // 世界坐标默认是y up，在此旋转改为z up
    zeroWrapper.rotation.x = -math.pi / 2;
    var oneWrapper = three.Object3D();
    oneWrapper.position.z = 0.091;
    threeJs.scene.add(oneWrapper);
    oneWrapper.add(AxesHelper(0.1));
    var one = await addGltfAsset('one.glb', 'one');

    var twoWrapper = three.Object3D();
    twoWrapper.position.z = 0.05;
    twoWrapper.position.y = -0.067;
    twoWrapper.rotateX(math.pi / 2);
    threeJs.scene.add(twoWrapper);
    twoWrapper.add(AxesHelper(0.1));
    var two = await addGltfAsset('two.glb', 'two');

    var threeWrapper = three.Object3D();
    threeWrapper.position.x = 0;
    threeWrapper.position.y = 0.30;
    threeJs.scene.add(threeWrapper);
    threeWrapper.add(AxesHelper(0.1));
    // var threeGltf = await addGltfAsset('three.glb', 'three');
    var threeGltf = await addGltfAsset('link-3_simple.glb', 'three');

    var fourWrapper = three.Object3D();
    // fourWrapper.position.x = -0.036;
    // fourWrapper.position.y = 0.067;
    fourWrapper.position.y = 0.075;
    fourWrapper.position.z = -0.065;
    fourWrapper.rotateX(-math.pi / 2);
    threeJs.scene.add(fourWrapper);
    fourWrapper.add(AxesHelper(0.2));
    var four = await addGltfAsset('four.glb', 'four');

    var fiveWrapper = three.Object3D();
    fiveWrapper.position.z = 0.25;
    fiveWrapper.rotateX(math.pi / 2);
    threeJs.scene.add(fiveWrapper);
    fiveWrapper.add(AxesHelper(0.1));
    var five = await addGltfAsset('link-5_simple.glb', 'five');

    var sixWrapper = three.Object3D();
    sixWrapper.position.y = 0.09;
    sixWrapper.rotateX(-math.pi / 2);
    threeJs.scene.add(sixWrapper);
    sixWrapper.add(AxesHelper(0.1));

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
            rt.result[i * 2 + 1] = (rt.deltaDeg[i] / 180 * math.pi / 2.0).abs();
          }

          bleCubit.sendMsg(rt.result);

          // 如果当前的动作位置和目标位置完全一致，则直接切换到ready状态
          bool allZero = rt.deltaDeg.every((deg) => deg.abs() < 0.001);
          if (allZero) {
            motionsCubit.updateStatus(MotionStatus.idle);
            return;
          }
        }
        // 将机械臂姿态移动到第一帧位置
        rt.elapsedTime += dt;
        // 直接是等比例速度移动到第一帧位置, 过渡时间为3秒
        double progress = (rt.elapsedTime) / 3.0;

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
            // 第二个关节
            if (j == 1) {
              jointsCubit.setSingleJoint(
                'joint${j + 1}',
                deg.clamp(-90.0, 90.0),
              );
            }
          }
        }

        // print('gotozero: $progress, --- ');
      } else if (motionsCubit.state.status == MotionStatus.preparing) {
        print('---准备动作中');
        if (rt.elapsedTime == 0.0) {
          // 目标关节位置在于动作的第一帧
          /// 从ai 应用动作 跳转到此页面不会出发生命周期，所以在此手动初始化。需要优化:将其放到生命周期里
          rt = RunTimeWorkSpace(curMotion: motionsCubit.state.currentMotion);

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

            // double deltaTime = rt.curKeyframe!.time - rt.preKeyframe!.time;
            // 因为是初始化，所以将匀速位置和速度直接发送给单片机
            rt.result[i * 2] = (rt.curKeyframe!.positions[i] / 180 * math.pi);
            rt.result[i * 2 + 1] = (rt.deltaDeg[i] / 3.0 / 180 * math.pi).abs();
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
        // 直接是等比例速度移动到第一帧位置, 过渡时间为3秒
        double progress = (rt.elapsedTime) / 3.0;

        // 最后一帧有溢出的可能性，比如progress = 1.0079999999999987,
        if (progress >= 1.0) {
          for (int j = 0; j < rt.curKeyframe!.positions.length; j++) {
            double deg = rt.deltaDeg[j] * 1 + preparingInitPosition[j];
            jointsCubit.setSingleJoint(
              'joint${j + 1}',
              deg.clamp(-145.0, 145.0),
            );
            // 第二个关节
            if (j == 1) {
              jointsCubit.setSingleJoint(
                'joint${j + 1}',
                deg.clamp(-90.0, 90.0),
              );
            }
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
            // 第二个关节
            if (j == 1) {
              jointsCubit.setSingleJoint(
                'joint${j + 1}',
                deg.clamp(-90.0, 90.0),
              );
            }
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

          void computedPotionsDelta() {
            /// 计算位置差
            for (int i = 0; i < rt.curKeyframe!.positions.length; i++) {
              rt.deltaDeg[i] =
                  rt.curKeyframe!.positions[i] - rt.preKeyframe!.positions[i];

              rt.result[i * 2] = (rt.curKeyframe!.positions[i] / 180 * math.pi);
              rt.result[i * 2 + 1] =
                  (rt.deltaDeg[i] / rt.deltaTime / 180 * math.pi).abs();
            }
            return;
          }

          /// 如果当前的经历时间大于当前关键帧的时间，则需要赋值下一个关键帧
          if (rt.elapsedTime >= rt.curKeyframe!.markerTimeEnd) {
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
            rt.deltaTime = rt.curKeyframe!.time;
            rt.repeatCount = 0;

            computedPotionsDelta();

            bleCubit.sendMsg(rt.result);

            /// 获取控制点
            rt.controlPoints = timingFuncToDoubleList(
              rt.curKeyframe!.timingFunction,
            );

            // 缓存缓存帧
            if (rt.curKeyframe!.repeatCount > 0) {
              rt.cacheKeyframe = Keyframe(
                name: 'cache',
                positions: List.from(
                  rt.keyframeList[rt.keyframeCursor - 1].positions,
                ),
                time: rt.keyframeList[rt.keyframeCursor].time,
                timingFunction:
                    rt.keyframeList[rt.keyframeCursor].timingFunction,
                repeatCount: rt.keyframeList[rt.keyframeCursor].repeatCount,
                markerTimeStart:
                    rt.keyframeList[rt.keyframeCursor].markerTimeStart,
                markerTimeEnd: rt.keyframeList[rt.keyframeCursor].markerTimeEnd,
              );
            } else {
              rt.cacheKeyframe = null;
            }
          }

          /// 新功能： 需要考虑重复次数的问题。A帧-》B帧，如果B帧的重复次数为2（意思是执行b帧的次数），
          /// 第0次： A帧-》B帧， 第1次： B帧-》A帧 =〉B帧  总流程为 A帧-》B帧-》A帧-》B帧
          /// 这其中的间隔时间是按B帧的时间来计算。
          /// 1，2 ； 2，1 ；1，2
          /// 当运行时间大于当前关键的起始时间+运行时间（这是正常运行的）
          /// 大于这个时间的话，就是开始重复运行的阶段
          if (rt.elapsedTime >=
              rt.curKeyframe!.markerTimeStart + rt.curKeyframe!.time) {
            double localElapsedTime =
                rt.elapsedTime -
                rt.curKeyframe!.markerTimeStart -
                rt.curKeyframe!.time;
            //关键： 计算repeatCount和赋值preKeyframe和curKeyframe
            if (localElapsedTime > rt.curKeyframe!.time * 2 * rt.repeatCount) {
              rt.repeatCount += 0.5;

              if (rt.repeatCount % 1 == 0) {
                rt.preKeyframe = rt.cacheKeyframe;
                rt.curKeyframe = rt.keyframeList[rt.keyframeCursor];
              } else {
                rt.preKeyframe = rt.keyframeList[rt.keyframeCursor];
                rt.curKeyframe = rt.cacheKeyframe;
              }

              computedPotionsDelta();
            }
          }

          /// 重复次数时，切换关键帧
          /// 在此虚拟一个关键帧：用来存储前一帧的位置信息和当前帧的其他信息。
          /// 在此做判断，如歌要执行repeatCount时候，在此将preKeyframe切换成cacheKeyframe。

          /// 接下来要计算当前时刻的位置
          /// 第一步： 获取当前时的时间 在 总时间 里的百分几
          /// repeatTime用来计算重复次数耗费的时间
          /// processTime是当前帧已运行的时间。除以运行时间的话，就是时间进度t了
          double repeatTime = 0.0;
          double processTime = rt.elapsedTime - rt.curKeyframe!.markerTimeStart;
          if (rt.repeatCount > 0) {
            rt.curKeyframe;
            repeatTime = rt.repeatCount * rt.curKeyframe!.time * 2;
            processTime -= repeatTime;
          }

          double t = processTime / rt.curKeyframe!.time;
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
            // rt.result[i * 2] = (curDeg / 180 * math.pi).clamp(-145.0/ 180 * math.pi, 145.0/ 180 * math.pi);
            // 尝试：不再计算中间位置（因为运行起来会有卡顿的感觉，就是电机停一下，再运动）
            // 所以，将最终关键帧位置直接赋值
            rt.result[i * 2] = rt.curKeyframe!.positions[i] / 180 * math.pi;

            /// 速度（弧度/s）： delta距离 / delta时间 = 速度 边界值为0.0, 15.0
            rt.result[i * 2 + 1] =
                ((rt.deltaDeg[i] * ratio - rt.deltaDeg[i] * rt.preRatio) /
                        dt /
                        180 *
                        math.pi)
                    .abs();
          }

          // print('位置指令: ${rt.result}');

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

    // // 启用抗锯齿
    // try {
    //   // threeJs.renderer = three.WebGLRenderer({
    //   //   'antialias': true, // 启用抗锯齿
    //   //   'alpha': true, // 可选：启用透明背景
    //   // });
    //   threeJs.renderer = three.WebGLRenderer(
    //     three.WebGLRendererParameters(
    //       width: threeJs.width,
    //       height: threeJs.height,
    //       antialias: true, // 启用抗锯齿
    //       alpha: true, // 可选：启用透明背景
    //       gl: threeJs.gl!,
    //     ),
    //   );

    //   threeJs.renderer?.setSize(threeJs.width, threeJs.height); // 设置渲染器大小
    //   threeJs.renderer?.autoClear = false; // 允许覆盖渲染
    //   print('Renderer initialized successfully with antialiasing');
    // } catch (e) {
    //   print('Error initializing renderer: $e');
    // } finally {
    //   print('Renderer initialization attempt completed.');
    // }

    // 一个小长方体，用来展示逆解姿态
    var ikCuboid = three.BoxGeometry(0.1, 0.05, 0.01);
    var ikMaterial = three.MeshBasicMaterial({
      three.MaterialProperty.color: three.Color.fromHex64(0xff00ff),
      three.MaterialProperty.transparent: true, // 必须开启透明混合
      three.MaterialProperty.opacity: 0.5, // 设置透明度，范围从 0.0 到 1.0
    });
    var ikCube = three.Mesh(ikCuboid, ikMaterial);
    final ikPoseCtrl = three.Object3D();
    ikPoseCtrl.position = three.Vector3(0.2, 0.2, 0.2);
    ikPoseCtrl.add(ikCube);
    ikPoseCtrl.add(AxesHelper(0.2));

    // 移动控制
    final control = TransformControls(threeJs.camera, threeJs.globalKey);
    control.attach(ikPoseCtrl);
    control.mode = ikCubit.state.dragPose.mode;
    control.size = 0.5;

    // threeJs.scene.add(control);
    threeJs.scene.add(control);
    zeroWrapper.add(ikPoseCtrl);

    vector_math.Matrix4 threeMat2mat(three.Matrix4 mat) {
      return vector_math.Matrix4.fromFloat64List(
        Float64List.fromList(ikPoseCtrl.matrix.storage),
      );
    }

    control.addEventListener('change', (event) {
      threeJs.render();

      /// 获取逆解集合
      List<List<double>> allSolutions = RobotKm.ik(
        threeMat2mat(ikPoseCtrl.matrix),
      );

      /// 获取最优解
      List<double> predegs = ikCubit.state.preJointsDeg
          .map((ele) => ele * math.pi / 180)
          .toList();
      List<double> goodOneSol = RobotKm.getBestSolution(allSolutions, predegs);
      if (goodOneSol.isNotEmpty) {
        print('好解：$goodOneSol');
        jointsCubit.setJoints(
          JointsState(
            joint1: goodOneSol[0],
            joint2: -goodOneSol[1],
            joint3: -goodOneSol[2],
            joint4: goodOneSol[3],
            joint5: -goodOneSol[4],
            joint6: goodOneSol[5],
          ),
        );
        ikCubit.setPreJointsDeg(goodOneSol);
      } else {
        ikCubit.setPreJointsDeg([]);
      }
    });
    control.addEventListener('dragging-changed', (event) {
      orbitControle.enabled = !event.value;
    });

    threeJs.renderer?.autoClear = false;

    void render() {
      threeJs.addAnimationEvent((dt) {
        control.mode = ikCubit.state.dragPose.mode;

        zeroWrapper.add(zero?.scene);
        zeroWrapper.add(oneWrapper);

        oneWrapper.add(one?.scene);
        oneWrapper.add(twoWrapper);

        twoWrapper.add(two?.scene);
        twoWrapper.add(threeWrapper);

        threeWrapper.add(threeGltf?.scene);
        threeWrapper.add(fourWrapper);

        fourWrapper.add(four?.scene);
        fourWrapper.add(fiveWrapper);

        fiveWrapper.add(five?.scene);
        fiveWrapper.add(sixWrapper);

        oneWrapper.rotation.z = (jointsCubit.state.joint1 * math.pi) / 180;
        twoWrapper.rotation.z = -(jointsCubit.state.joint2 * math.pi) / 180;
        threeWrapper.rotation.z = -(jointsCubit.state.joint3 * math.pi) / 180;
        fourWrapper.rotation.z = (jointsCubit.state.joint4 * math.pi) / 180;
        fiveWrapper.rotation.z = -(jointsCubit.state.joint5 * math.pi) / 180;
        sixWrapper.rotation.z = (jointsCubit.state.joint6 * math.pi) / 180;

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
    double oneDegree = math.pi / 180;

    if (type == 'zero') {
      gltf.scene.rotateX(math.pi / 2);
    } else if (type == 'one') {
      gltf.scene.rotateX(math.pi / 2);
      gltf.scene.rotateY(math.pi);
    } else if (type == 'two') {
      gltf.scene.translateX(-0.045);
      gltf.scene.translateY(0.123);
      gltf.scene.rotation.set(oneDegree * 0, oneDegree * -90, oneDegree * 90.0);
    } else if (type == 'three') {
      gltf.scene.rotation.set(
        math.pi / 180 * -90,
        math.pi / 180 * 95,
        math.pi / 180 * 0,
      );
    } else if (type == 'four') {
      gltf.scene.translateY(0.07);
      gltf.scene.translateZ(0.25);
      gltf.scene.translateX(0.001);
      gltf.scene.rotateZ(math.pi);
      gltf.scene.rotateY(math.pi / 2);
    } else if (type == 'five') {
      gltf.scene.translateZ(-0.042);
      gltf.scene.rotateX(math.pi / 180 * 90);
      gltf.scene.rotateY(math.pi / 180 * 90);
    } else if (type == "pose_link-5_simple") {
      gltf.scene.translateZ(-0.09);
      gltf.scene.translateY(0.045);
      gltf.scene.rotateX(math.pi);
      gltf.scene.rotateY(math.pi / 2);
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

  /// 重复次数 存在0.5次的计算，所以用double
  double repeatCount;

  /// 缓存帧 用来重复执行帧时用的。存储的是curKeyframe的贝塞尔曲线信息和执行时间。还有是上一帧的位置信息。
  /// 这么做的原因是： 当前帧到上一帧的位置是合理的。
  /// 举个例子：A -> B帧 -> C帧 。A -> B 与 C -> B不同。 但 B->C 和 C->B 理论上不会出现物理问题（比如速度过快，时间不合理等）。
  Keyframe? cacheKeyframe;
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
    this.repeatCount = 0.0,
    this.cacheKeyframe,
    this.result = const [],
    this.preRatio = 0.0,
    this.results = const [],
    this.windowSize = 30,
    this.curSize = 0,
  }) {
    keyframeList = curMotion?.keyframes ?? const [];
    // curKeyframe =
    //     curMotion?.keyframes[1] ??
    //     Keyframe(name: '', timingFunction: '', time: 0, positions: []);
    // preKeyframe =
    //     curMotion?.keyframes[1] ??
    //     Keyframe(name: '', timingFunction: '', time: 0, positions: []);
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
void combinPostion(List<List<double>> positionArr, BleCubit bleCubit) {
  // List<double> result = List.filled(12, 0.0, growable: false);
  // print('combinPostion: ${positionArr.toString()}');

  // /// 位置只取最后一帧
  // for (int i = 0; i < positionArr.length; i++) {
  //   for (int j = 0; j < positionArr[i].length; j++) {
  //     if (j % 2 == 0) {
  //       // i是位置
  //       // 最后一个数组时候，直接将位置赋值给result
  //       if (i == positionArr.length - 1) {
  //         result[j] = positionArr[i][j];
  //       }
  //     } else {
  //       // i + 1是速度
  //       /// 平均速度就是 所有速度的总和 / 个数, 设置最小转动速度，以免指令积压
  //       result[j] += (positionArr[i][j] / positionArr.length);
  //       // result[j] += positionArr[i][j] / positionArr.length;
  //       // result[j] = 2.0;
  //     }
  //   }
  // }
  // print('---合并帧$result');

  // bleCubit.sendMsg(result);

  // /// 返回结果帧
  // // return result;
}
