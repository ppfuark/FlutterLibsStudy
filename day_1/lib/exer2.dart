import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecordingState { stopped, recording, paused }

class Exer2 extends StatefulWidget {
  const Exer2({super.key});

  @override
  State<Exer2> createState() => _Exer2State();
}

class _Exer2State extends State<Exer2> {
  Directory? documents;
  final Stopwatch stopwatch = Stopwatch();
  Timer? timer;
  Duration elapsed = Duration.zero;
  List<FileSystemEntity> recordings = [];

  RecordingState recordingState = RecordingState.stopped;

  final FlutterSoundRecorder recorder = FlutterSoundRecorder();

  void startTimer() {
    stopwatch.start();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          elapsed = stopwatch.elapsed;
        });
      }
    });
  }

  Future<void> loadRecordings() async {
    documents ??= await getApplicationDocumentsDirectory();

    final files = documents!
        .listSync()
        .where((f) => f.path.endsWith('.aac'))
        .toList();

    setState(() {
      recordings = files;
    });
  }

  void pauseTimer() {
    stopwatch.stop();
    timer?.cancel();
  }

  void resetTimer() {
    stopwatch
      ..stop()
      ..reset();
    timer?.cancel();
    setState(() {
      elapsed = Duration.zero;
    });
  }

  Future<void> startRecording() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception("Permissão de microfone negada");
      }

      documents ??= await getApplicationDocumentsDirectory();
      final path =
          "${documents!.path}/audio${DateTime.now().millisecondsSinceEpoch}.aac";

      await recorder.openRecorder();
      await recorder.startRecorder(toFile: path, codec: Codec.aacADTS);

      setState(() => recordingState = RecordingState.recording);
      resetTimer();
      startTimer();
    } catch (e) {
      if (mounted) toastError('Erro ao iniciar: $e', context);
    }
  }

  Future<void> pauseRecording() async {
    await recorder.pauseRecorder();
    pauseTimer();
    setState(() => recordingState = RecordingState.paused);
  }

  Future<void> resumeRecording() async {
    await recorder.resumeRecorder();
    startTimer();
    setState(() => recordingState = RecordingState.recording);
  }

  Future<void> stopRecording() async {
    final path = await recorder.stopRecorder();
    resetTimer();
    setState(() => recordingState = RecordingState.stopped);

    if (path != null && mounted) {
      final size = File(path).lengthSync();
      toast("Salvo! Tamanho: $size bytes", context);
    }
  }

  @override
  void initState() {
    super.initState();
    loadRecordings();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    timer?.cancel();
    super.dispose();
  }

  String get formattedElapsed {
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
        child: SingleChildScrollView(
          child: Column(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Exercise(
                name: "2.1 - Configure AndroidManifest.xml",
                function: () async {
                  toast(
                    '<uses-permission android:name="android.persmission.INTERNET"/>',
                    context,
                  );
                  toast(
                    '<uses-permission android:name="android.persmission.RECORD_AUDIO"/>',
                    context,
                  );
                  toast(
                    '<uses-permission android:name="android.persmission.WRITE_EXTERNAL_STORAGE"/>',
                    context,
                  );
                  toast(
                    '<uses-permission android:name="android.persmission.READ_EXTERNAL_STORAGE"/>',
                    context,
                  );
                  toast(
                    '<uses-permission android:name="android.persmission.READ_MEDIA_AUDIO"/>',
                    context,
                  );
                },
                disable: false,
              ),
              Column(
                children: [
                  Exercise(
                    name: "2.2 - Record 5s, save on Documents",
                    function: () async {
                      if (recordingState == RecordingState.stopped) {
                        await startRecording();
                      } else {
                        await stopRecording();
                        await loadRecordings();
                      }
                    },
                    disable: false,
                  ),
                  if (recordingState != RecordingState.stopped)
                    Text(
                      formattedElapsed,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Histórico (.aac)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...recordings.map((file) {
                        final name = file.path.split('/').last;
                        final size = File(file.path).lengthSync();

                        return ListTile(
                          title: Text(name),
                          subtitle: Text("$size bytes"),
                        );
                      }),
                    ],
                  ),
                ],
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
                      MaterialPageRoute(builder: (context) => Exer2()),
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
  final bool disable;
  const Exercise({
    super.key,
    required this.name,
    required this.function,
    required this.disable,
  });

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
            color: disable ? Colors.grey : Colors.blue,
            borderRadius: BorderRadius.circular(99),
          ),
          child: GestureDetector(
            onTap: () {
              disable ? null : function();
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
