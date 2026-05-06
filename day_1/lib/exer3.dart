import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Exer3 extends StatefulWidget {
  const Exer3({super.key});

  @override
  State<Exer3> createState() => _Exer3State();
}

class _Exer3State extends State<Exer3> {
  late List<CameraDescription> cameras;
  XFile? file;
  late CameraController cameraController;
  bool showCamera = false;
  int camera = 0;

  Future<void> startApp() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras[camera], ResolutionPreset.max);
    await cameraController.initialize();
  }

  void changeCamera() async {
    final newIndex = camera == 0 ? 1 : 0;
    await cameraController.dispose();
    cameraController = CameraController(
      cameras[newIndex],
      ResolutionPreset.max,
    );
    await cameraController.initialize();

    setState(() {
      camera = newIndex;
    });
  }

  @override
  void initState() {
    super.initState();
    startApp();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(),
        padding: EdgeInsets.all(30),
        child: showCamera
            ? Column(
                spacing: 10,
                children: [
                  SizedBox(
                    width: w,
                    height: h * .8,
                    child: Stack(
                      children: [
                        Positioned.fill(child: CameraPreview(cameraController)),
                        Align(
                          alignment: AlignmentGeometry.topRight,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                showCamera = false;
                              });
                            },
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: () {
                          changeCamera();
                        },
                        icon: Icon(Icons.change_circle, size: 40),
                      ),
                      IconButton(
                        onPressed: () async {
                          file = await cameraController.takePicture();
                          setState(() {});
                        },
                        icon: Icon(Icons.camera, size: 80),
                      ),
                      file != null
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.file(
                                            fit: BoxFit.contain,
                                            File(file!.path),
                                          ),
                                        ),
                                        Align(
                                          alignment: AlignmentGeometry.topRight,
                                          child: IconButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: Image.file(
                                  fit: BoxFit.cover,
                                  File(file!.path),
                                ),
                              ),
                            )
                          : Icon(Icons.image),
                    ],
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Exercise(
                      name: '3.1 - Open camera, take and show picture',
                      function: () async {
                        try {
                          final permission = await Permission.camera.request();
                          if (!permission.isGranted) {
                            context.mounted
                                ? toastError(
                                    "Permissão de camera não garantida.",
                                    context,
                                  )
                                : null;
                          } else {
                            setState(() {
                              showCamera = true;
                            });
                          }
                        } catch (e) {
                          context.mounted
                              ? toastError("Erro ao tirar foto: $e", context)
                              : null;
                        }
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class Exercise extends StatelessWidget {
  final String name;
  final Function function;
  const Exercise({super.key, required this.name, required this.function});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(99),
          ),
          child: GestureDetector(
            onTap: () {
              function();
            },
            child: Center(
              child: Text(
                "Tap",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void toast(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.green,
    ),
  );
}

void toastError(String text, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.red,
    ),
  );
}
