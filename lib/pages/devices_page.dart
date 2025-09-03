import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:flutter/services.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  _FlutterGameState createState() => _FlutterGameState();
}

class _FlutterGameState extends State<DevicesPage> {
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

  // void addGLTFModel(modelName, type) {
  //   return three.GLTFLoader().setPath('assets/').load(modelName, (gltf) {
  //     // console.log('模型加载成功: ', gltf);
  //     threeJs.scene.add(gltf.scene);
  //     // initGLTF.bind(this)(gltf, type);
  //   });
  // }

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
    threeJs.camera.position.setValues(4, 3.5, 3.5);
    threeJs.scene = three.Scene();
    // init();

    final gridHelper = GridHelper(5, 10, 0x888888, 0x444444);
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

    // 下臂
    var bottomArmWrapper = three.Object3D();
    bottomArmWrapper.position.x = 0.5;
    bottomArmWrapper.position.y = 0;
    threeJs.scene.add(bottomArmWrapper);
    // bottomArmWrapper.add(AxesHelper(2));
    // let bottom_arm = await this.addGLTFModel('bottom_arm.glb', 'bottom_arm');
    final bottomArm = await addGltfAsset('bottom_arm.glb', 'bottom_arm');

    // 中臂
    var centerArmWrapper = three.Object3D();
    centerArmWrapper.position.x = 0;
    centerArmWrapper.position.y = 0.6;
    threeJs.scene.add(centerArmWrapper);
    // centerArmWrapper.add(new THREE.AxesHelper(2));
    final centerArm = await addGltfAsset('center_arm.glb', 'center_arm');

    // 上臂
    var topArmWrapper = three.Object3D();
    topArmWrapper.position.x = 0;
    topArmWrapper.position.y = 0.8;
    topArmWrapper.position.z = 0.2;
    threeJs.scene.add(topArmWrapper);
    // topArmWrapper.add(new THREE.AxesHelper(2));
    final topArm = await addGltfAsset('top_arm.glb', 'top_arm');

    // 类似web的requestAniamtionFrame
    threeJs.addAnimationEvent((dt) {
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
        bottomArmWrapper.add(bottomArm?.scene);
        bottomArmWrapper.add(centerArmWrapper);

        centerArmWrapper.add(centerArm?.scene);
        centerArmWrapper.add(topArmWrapper);

        topArmWrapper.add(topArm.scene);

        // bottomArmWrapper.rotation.y = this.angle_bottom; // -180 ~ 180;
        // centerArmWrapper.rotation.z = this.angle_center;
        // topArmWrapper.rotation.z = this.angle_top;

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

  addGltfAsset(name, type) async {
    three.GLTFLoader loader = three.GLTFLoader(flipY: true).setPath('assets/');
    final gltf = await loader.fromAsset(name);
    threeJs.scene.add(gltf!.scene);
    initGLTF(gltf, type);
    return gltf;
  }

  void initGLTF(gltf, type) {
    gltf.scene.scale = three.Vector3(5, 5, 5);

    if (type == 'bottom_arm') {
      // 初始化位置等信息
      gltf.scene.scale = three.Vector3(5, 5, 5);
      gltf.scene.rotation.set(math.pi / 2, 0.0, 0.0);
      gltf.scene.translateZ(-0.6);
      gltf.scene.translateY(-0.0);
    } else if (type == 'center_arm') {
      gltf.scene.translateX(-0.0);
      gltf.scene.translateZ(0.1);
      gltf.scene.rotation
          .set(math.pi / 180 * 183.5, math.pi / 180 * 330, math.pi / 180 * 57);
    } else if (type == 'top_arm') {
      gltf.scene.rotation.set(math.pi / 2, 0.0, 0.0);
      gltf.scene.translateY(0.1);
    } else if (type == 'cyber_gear') {
      gltf.scene.rotation.set(math.pi / 2, 0.0, 0.0);
      gltf.scene.translateX(0.03);
      gltf.scene.translateY(-0.4);
      gltf.scene.translateZ(0.05);
    }
  }
}
