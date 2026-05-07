import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FinalProject extends StatefulWidget {
  const FinalProject({super.key});

  @override
  State<FinalProject> createState() => _FinalProjectState();
}

enum RecordingState { recording, paused, stopped }

class _FinalProjectState extends State<FinalProject> {
  final FlutterSoundRecorder flutterSoundRecorder = FlutterSoundRecorder();
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  Directory? documents;
  RecordingState recordingState = RecordingState.stopped;
  String? time;
  Timer? timer;
  Stopwatch stopwatch = Stopwatch();
  Duration elapsed = Duration.zero;

  Future<void> startApp() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras[1], ResolutionPreset.max);
    cameraController.initialize();
  }

  Future<void> startRecording() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception("Permissão de microfone negada.");
      }

      await flutterSoundRecorder.closeRecorder();
      await flutterSoundRecorder.openRecorder();

      documents = await getApplicationDocumentsDirectory();
      time = DateTime.now().millisecondsSinceEpoch.toString();
      final dir = Directory("${documents!.path}/audio");
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final path = "${documents!.path}/audio/$time.aac";

      await flutterSoundRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      stopwatch.stop();
      stopwatch.reset();
      timer?.cancel();
      setState(() {
        elapsed = Duration.zero;
      });

      setState(() {
        recordingState = RecordingState.recording;
      });

      stopwatch.start();
      timer = Timer.periodic(Durations.medium1, (_) {
        setState(() {
          elapsed = stopwatch.elapsed;
        });
      });
    } catch (e) {
      mounted ? toastError("Erro ao iniciar: $e", context) : null;
    }
  }

  Future<void> chosePhoto(String time) async {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    final w = MediaQuery.of(context).size.width;
                    final h = MediaQuery.of(context).size.height;
                    return Scaffold(
                      body: Container(
                        padding: EdgeInsets.all(30),
                        width: w,
                        height: h,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: w,
                              height: h * .8,
                              child: CameraPreview(cameraController),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(Icons.close, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final dir =
                                        await getApplicationDocumentsDirectory();
                                    final Directory dirPath = Directory(
                                      "${dir.path}/image",
                                    );

                                    if (!dirPath.existsSync()) {
                                      await dirPath.create(recursive: true);
                                    }

                                    final file = await cameraController
                                        .takePicture();
                                    await File(
                                      file.path,
                                    ).copy("${dirPath.path}/$time.png");
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    toast("Criado com sucesso.", context);
                                  },
                                  icon: Icon(Icons.camera, size: 60),
                                ),

                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(Icons.close),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            child: Text("Camera"),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                FilePickerResult? result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpeg', 'png', 'jpg'],
                );
                if (result != null) {
                  PlatformFile file = result.files.first;
                  final dir = await getApplicationDocumentsDirectory();
                  final path = "${dir.path}/images";
                  await File(file.path!).copy(path);
                  if (!context.mounted) return;
                  toast("Arquivos salvos com sucesso!", context);
                } else {
                  if (!context.mounted) return;
                  toastError("Cancelado pelo o usuário.", context);
                }
              } catch (e) {
                if (!context.mounted) return;
                toastError("Erro na escolha de capa: $e", context);
                await Future.delayed(Duration(seconds: 2));
                chosePhoto(time);
              }
            },
            child: Text("Gallery"),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Cancel"),
        ),
      ),
    );
  }

  Future<void> pauseRecording() async {
    await flutterSoundRecorder.pauseRecorder();
    setState(() {
      recordingState = RecordingState.paused;
    });
    stopwatch.stop();
    timer?.cancel();
  }

  Future<void> resumeRecording() async {
    await flutterSoundRecorder.resumeRecorder();
    setState(() {
      recordingState = RecordingState.recording;
    });
    stopwatch.start();
    timer = Timer.periodic(Durations.medium1, (_) {
      setState(() {
        elapsed = stopwatch.elapsed;
      });
    });
  }

  Future<void> stopRecording() async {
    await flutterSoundRecorder.stopRecorder();
    setState(() {
      recordingState = RecordingState.stopped;
    });
    stopwatch.stop();
    stopwatch.reset();
    timer?.cancel();
    setState(() {
      elapsed = Duration.zero;
    });

    chosePhoto(time ?? DateTime.now().millisecondsSinceEpoch.toString());
  }

  @override
  void initState() {
    super.initState();
    startApp();
  }

  @override
  void dispose() {
    super.dispose();
    flutterSoundRecorder.closeRecorder();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: w,
        height: h,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.grey.shade200,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          recordingState == RecordingState.recording
                              ? stopRecording()
                              : recordingState == RecordingState.paused
                              ? stopRecording()
                              : null;
                        },
                        icon: Icon(Icons.stop, size: 30, color: Colors.red),
                      ),
                    ),
                    Text("End"),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.grey.shade200,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          recordingState == RecordingState.recording
                              ? pauseRecording()
                              : startRecording();
                        },
                        icon: Icon(
                          recordingState == RecordingState.paused
                              ? Icons.pause
                              : Icons.mic_sharp,
                          size: 50,
                        ),
                      ),
                    ),
                    Text(
                      recordingState == RecordingState.paused
                          ? "Paused"
                          : "Recording",
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.grey.shade200,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Records()),
                          );
                        },
                        icon: Icon(Icons.list, size: 30),
                      ),
                    ),
                    Text("Records"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
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

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  List<dynamic> images = [];
  List<dynamic> audios = [];
  late Directory directory;

  final FlutterSoundPlayer soundRecorder = FlutterSoundPlayer();
  String? elapsed;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration durantion = Duration.zero;
  StreamSubscription? plauSub;

  dynamic audioForImage(FileSystemEntity image) {
    final time = image.path.split("/").last.split(".").first;
    try {
      return audios
          .firstWhere((a) => a.path.split("/").last.split(".").first == time)
          .path;
    } catch (e) {
      return null;
    }
  }

  Future<void> startApp() async {
    directory = await getApplicationDocumentsDirectory();
    images = io.Directory("${directory.path}/image").listSync();
    audios = io.Directory("${directory.path}/audio").listSync();

    if (!context.mounted) return;

    await soundRecorder.openPlayer();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    startApp();
  }

  @override
  void dispose() {
    super.dispose();

    plauSub?.cancel();
    soundRecorder.closePlayer();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text("Records")),
      body: Container(
        width: w,
        height: h,
        padding: EdgeInsets.all(30),
        child: images.isEmpty
            ? const Center(child: Text("Nenhum registro encontrado."))
            : ListView.builder(
                itemBuilder: (context, index) {
                  final image = images[index];
                  final time = image.path.split("/").last.split(".").first;
                  final audioPath = audioForImage(image);
                  final isThisPlaying = isPlaying && elapsed == time;
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsetsGeometry.all(10),
                      child: Row(
                        spacing: 10,
                        children: [
                          Image.file(
                            File(image.path),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Gravação $time",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (audioPath != null) ...[
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          if (isPlaying && elapsed == time) {
                                            await soundRecorder.pausePlayer();
                                            setState(() => isPlaying = false);
                                            return;
                                          }

                                          if (!isPlaying &&
                                              elapsed == time &&
                                              soundRecorder.isPaused) {
                                            await soundRecorder.resumePlayer();
                                            setState(() => isPlaying = true);
                                            return;
                                          }

                                          if (elapsed != null &&
                                              elapsed != time) {
                                            await soundRecorder.stopPlayer();
                                            setState(
                                              () => position = Duration.zero,
                                            );
                                          }

                                          plauSub?.cancel();

                                          await soundRecorder.startPlayer(
                                            fromURI: audioPath,
                                            codec: Codec.aacADTS,
                                            whenFinished: () => setState(() {
                                              isPlaying = false;
                                              position = Duration.zero;
                                            }),
                                          );

                                          plauSub = soundRecorder.onProgress!
                                              .listen(
                                                (e) => setState(() {
                                                  position = e.position;
                                                  durantion = e.duration;
                                                }),
                                              );

                                          await soundRecorder
                                              .setSubscriptionDuration(
                                                Durations.medium1,
                                              );

                                          setState(() {
                                            elapsed = time;
                                            isPlaying = true;
                                          });
                                        },
                                        icon: Icon(
                                          isThisPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          min: 0,
                                          max:
                                              elapsed == time &&
                                                  durantion.inMilliseconds > 0
                                              ? durantion.inMilliseconds
                                                    .toDouble()
                                              : 1,
                                          value:
                                              elapsed == time &&
                                                  durantion.inMilliseconds > 0
                                              ? position.inMilliseconds
                                                    .toDouble()
                                                    .clamp(
                                                      0.0,
                                                      durantion.inMilliseconds
                                                          .toDouble(),
                                                    )
                                              : 0,
                                          onChanged: (v) async {
                                            await soundRecorder.seekToPlayer(
                                              Duration(milliseconds: v.toInt()),
                                            );
                                          },
                                        ),
                                      ),
                                      Text(
                                        elapsed == time &&
                                                durantion.inMilliseconds > 0
                                            ? "${(position.inMinutes % 60).toString().padLeft(2, '0')} : ${(position.inSeconds % 60).toString().padLeft(2, '0')} / ${(durantion.inMinutes % 60).toString().padLeft(2, '0')} : ${(durantion.inSeconds % 60).toString().padLeft(2, '0')}"
                                            : "00:00",
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: images.length,
              ),
      ),
    );
  }
}
