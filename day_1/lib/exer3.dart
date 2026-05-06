import 'dart:io';

import 'package:camera/camera.dart';
import 'package:day_1/exer4.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  bool saveOnDoc = false;
  bool maxRes = true;

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
      maxRes ? ResolutionPreset.max : ResolutionPreset.low,
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
                          final dir = await getApplicationDocumentsDirectory();
                          final String path =
                              '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png';

                          file = await cameraController.takePicture();
                          if (saveOnDoc) {
                            final copied = await File(file!.path).copy(path);
                            print('Arquivo salvo em: $path');
                            if (!context.mounted) return;
                            if (copied.existsSync()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.file(
                                          fit: BoxFit.contain,
                                          File(path),
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
                            }
                          }

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
                  spacing: 20,
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
                              saveOnDoc = false;
                              maxRes = true;
                            });
                          }
                        } catch (e) {
                          context.mounted
                              ? toastError("Erro ao tirar foto: $e", context)
                              : null;
                        }
                      },
                    ),
                    Exercise(
                      name:
                          '3.2 - Open gallery and display image, error handling',
                      function: () async {
                        try {
                          final ImagePicker imagePicker = ImagePicker();
                          final imageFile = await imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (!context.mounted) return;
                          imageFile != null
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.file(
                                            fit: BoxFit.contain,
                                            File(imageFile.path),
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
                                )
                              : toastError("Imagem não selecionada", context);
                        } catch (e) {
                          print(e);
                          context.mounted
                              ? toastError("Erro ao escolher foto: $e", context)
                              : null;
                        }
                      },
                    ),
                    Exercise(
                      name: '3.3 - Open camera, take and save picture',
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
                              saveOnDoc = true;
                              maxRes = true;
                            });
                          }
                        } catch (e) {
                          context.mounted
                              ? toastError("Erro ao tirar foto: $e", context)
                              : null;
                        }
                      },
                    ),
                    Exercise(
                      name:
                          '3.4 - Open camera, take and save picture with low resolution',
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
                              saveOnDoc = true;
                              maxRes = false;
                            });
                          }
                        } catch (e) {
                          context.mounted
                              ? toastError("Erro ao tirar foto: $e", context)
                              : null;
                        }
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.indigo,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Exer4()),
                          );
                        },
                        child: Center(
                          child: Text(
                            "Next exercise",
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
