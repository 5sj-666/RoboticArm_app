/// 设计机械臂的末端移动路径
// import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
// ignore: library_prefixes
import 'package:three_js/three_js.dart' as THREE;
import 'package:three_js_helpers/three_js_helpers.dart';
// import 'package:three_js_objects/three_js_objects.dart';

@RoutePage()
class DesignToolPathPage extends StatefulWidget {
  const DesignToolPathPage({super.key});

  @override
  DesignToolPath createState() => DesignToolPath();
}

class DesignToolPath extends State<DesignToolPathPage> {
  late THREE.ThreeJS threeContext;
  // late THREE.Camera

  @override
  void initState() {
    super.initState();
    print('---重新刷新1---');

    threeContext = THREE.ThreeJS(
      onSetupComplete: () {
        // setState(() {});
        print('---重新刷新---');
      },
      setup: setup,
    );
  }

  @override
  void didChangeDependencies() {
    print('111');
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('路径设计')),
      body: threeContext.build(),
      // body: Stack(
      //   children: [
      //     // 使用 Container 配合 BoxBorder 的正确写法
      //     // Container(
      //     //   // decoration: BoxDecoration(
      //     //   // border: Border.all(color: Colors.blue.withOpacity(0.5)),
      //     //   // ),
      //     //   child: threeContext.build(),
      //     // ),
      //     // Expanded(child: threeContext.build()),
      //     threeContext.build(),

      //     // 底部按钮
      //     // Positioned(
      //     //   left: 0,
      //     //   bottom: 20,
      //     //   child: SizedBox(
      //     //     width: MediaQuery.of(context).size.width,
      //     //     child: Center(
      //     //       child: ElevatedButton(
      //     //         style: ElevatedButton.styleFrom(
      //     //           minimumSize: const Size(200, 50),
      //     //         ),
      //     //         onPressed: () {},
      //     //         child: const Text("添加/保存"),
      //     //       ),
      //     //     ),
      //     //   ),
      //     // ),
      //   ],
      // ),
    );
  }

  @override
  void dispose() {
    threeContext.dispose();
    super.dispose();
  }

  Future<void> setup() async {
    threeContext.scene = THREE.Scene();
    final scene = threeContext.scene;
    scene.background = THREE.Color.fromHex64(0xf0f0f0);

    threeContext.camera = THREE.PerspectiveCamera(
      70,
      threeContext.width / threeContext.height,
      1,
      100,
    );
    threeContext.camera.position.setValues(2.5, 0.6, 0);
    threeContext.camera.lookAt(THREE.Vector3(0, 0, 0));
    final camera = threeContext.camera;
    // 初始化轨道控制器
    final controls = THREE.OrbitControls(camera, threeContext.globalKey);

    controls.update();

    // // 创建 Sky 对象
    // final sky = Sky.create();
    // // 设置天空的缩放比例
    // sky.scale.setScalar(450);
    // // 将 Sky 添加到场景中
    // threeContext.scene.add(sky);
    // // 配置天空的属性
    // final uniforms = sky.material!.uniforms;

    // // 设置大气参数
    // uniforms['turbidity']['value'] = 10.0; // 浑浊度
    // uniforms['rayleigh']['value'] = 2.0; // 瑞利散射系数
    // uniforms['mieCoefficient']['value'] = 0.005; // 米散射系数
    // uniforms['mieDirectionalG']['value'] = 0.8; // 米散射方向性

    // // 设置太阳的位置
    // final sunPosition = THREE.Vector3(100, 10, -50);
    // uniforms['sunPosition']['value'] = sunPosition;

    // 灯光优化
    scene.add(THREE.AmbientLight(0xffffff, 0.8));

    // final light = THREE.SpotLight(0xffffff, 5.0);
    // light.position.setValues(5, 10, 5);
    // light.castShadow = true;
    // // 阴影相机适配机械臂范围
    // light.shadow?.camera?.near = 0.1;
    // light.shadow?.camera?.far = 50;
    // scene.add(light);

    scene.add(AxesHelper(2));
    // scene.add(GridHelper(10, 10));
    final polarGrid = PolarGridHelper(
      0.8,
      18,
      36,
      64,
      THREE.Color.fromHex64(0x444444),
      THREE.Color.fromHex64(0x888888),
    );
    polarGrid.position.y = -0.1 + 0.000001;
    polarGrid.rotation.x = 0;
    threeContext.scene.add(polarGrid);

    threeContext.addAnimationEvent((dt) {});
  }
}
