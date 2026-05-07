import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
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
    cameraController = CameraController(cameras[0], ResolutionPreset.max);
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

  Future<void> chosePhoto() async {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(onPressed: () {}, child: Text("Camera")),
          CupertinoActionSheetAction(onPressed: () {}, child: Text("Gallery")),
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

    chosePhoto();
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
                        onPressed: () async {},
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
