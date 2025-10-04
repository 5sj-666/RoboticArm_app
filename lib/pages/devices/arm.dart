import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
// import 'package:three_js_core/three_js_core.dart' as three_core;
// import 'package:three_js_core/geometries/plane_geometry.dart'
// import 'package:three_js_core/materials/mesh_basic_material.dart';
// import 'package:three_js_core/objects/mesh.dart';
import 'package:flutter/services.dart';

class ArmPage extends StatefulWidget {
  const ArmPage({super.key});

  @override
  FlutterGameState createState() => FlutterGameState();
}

class FlutterGameState extends State<ArmPage> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: () {
        setState(() {});
      },
      setup: setup,
    );
    super.initState();
  }

  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    joystick?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return threeJs.build();
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Flutter Game'),
      // ),
      body: threeJs.build(),
      // backgroundColor: Color.fromRGBO(33, 33, 33, 0.3),
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

    threeJs.camera =
        three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
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

    final orbitControle =
        three.OrbitControls(threeJs.camera, threeJs.globalKey);
    orbitControle.update();

    addGltfAsset('cybergearmotor.stp.glb', 'cyber_gear');

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

    // 类似web的requestAniamtionFrame
    threeJs.addAnimationEvent((dt) {
      // oneWrapper.rotation.y += 0.1;
      threeJs.renderer?.render(threeJs.scene, threeJs.camera);
      // 渲染场景
      // threeJs.renderer!.render(threeJs.scene, threeJs.camera);
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

        twoWrapper.rotation.z = math.pi / 180 * 10.0;
        // oneWrapper.rotation.y = this.joint1;
        // twoWrapper.rotation.z = this.joint2;
        // threeWrapper.rotation.z = this.joint3;

        // fourWrapper.rotation.y = this.joint4;
        // fiveWrapper.rotation.z = this.joint5;

        threeJs.renderer?.render(threeJs.scene, threeJs.camera);
      });
    }

    render();
  }

  // init() {
  //   void initScene() {
  //     threeJs.scene = three.Scene();
  //     // this.scene.background = new THREE.Color(0xa0a0a0);
  //     threeJs.scene.add(GridHelper(5.0, 10, 0x888888, 0x444444));
  //     // this.scene.fog = new THREE.Fog(0x000000, 0, 10000) // 添加雾的效果
  //   }

  //   void initAxesHelper() {
  //     final gridHelper = GridHelper(5, 10, 0x888888, 0x444444);
  //     threeJs.scene.add(gridHelper);
  //   }

  //   void initLight() {
  //     final hesLight = three.HemisphereLight(0xffffff, 0x444444);
  //     hesLight.intensity = 0.6;
  //     threeJs.scene.add(hesLight);

  //     final dirLight = three.DirectionalLight();
  //     dirLight.position = three.Vector3(5.0, 5.0, 5.0);
  //     threeJs.scene.add(dirLight);
  //   }

  //   void initCamera() {
  //     threeJs.camera =
  //         three.PerspectiveCamera(75, threeJs.width / threeJs.height, 1, 2200);
  //     threeJs.camera.position = three.Vector3(1.5, 2, 3.0);
  //   }

  //   // 初始化场景
  //   initScene();
  //   // 初始化坐标轴辅助线
  //   initAxesHelper();
  //   // 初始化光源
  //   initLight();
  //   // 初始化相机
  //   initCamera();
  // }

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
      gltf.scene.rotation
          .set(math.pi / 180 * 0.0, math.pi / 180 * 270, math.pi / 180 * 90);
      // let oneDegree = math.pi / 180;
      // gltf.scene.rotation(oneDegree * 0, oneDegree * 90, oneDegree * 270);
    }
  }
}
