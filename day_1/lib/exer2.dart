import 'dart:async';
import 'dart:io';
import 'package:day_1/exer3.dart';
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

  final FlutterSoundPlayer flutterSoundPlayer = FlutterSoundPlayer();
  StreamSubscription? streamSubscription;
  String? currentPath;
  Duration currentPosition = Duration.zero;
  Duration fullDuration = Duration.zero;

  RecordingState recordingState = RecordingState.stopped;
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();

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

      await recorder.closeRecorder();
      await recorder.openRecorder();

      documents ??= await getApplicationDocumentsDirectory();
      final path =
          "${documents!.path}/audio${DateTime.now().millisecondsSinceEpoch}.aac";

      await recorder.openRecorder();
      await recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 16000, // ← emuladores funcionam bem com 16k
        numChannels: 1,
        bitRate: 64000, // ← ajusta o bitrate proporcional
      );
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

  Future<void> initPlayer() async {
    await flutterSoundPlayer.openPlayer();
    await flutterSoundPlayer.setSubscriptionDuration(
      Duration(milliseconds: 100),
    );
  }

  @override
  void initState() {
    super.initState();
    loadRecordings();
    initPlayer();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    timer?.cancel();
    flutterSoundPlayer.closePlayer();
    streamSubscription?.cancel();
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formattedElapsed,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              recordingState == RecordingState.recording
                              ? pauseRecording()
                              : resumeRecording(),
                          child: Icon(
                            recordingState == RecordingState.recording
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: recordingState == RecordingState.recording
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          recordingState == RecordingState.recording
                              ? "Recording"
                              : "Stopped",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: recordingState == RecordingState.recording
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
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
                        final isActive = currentPath == file.path;

                        return Container(
                          padding: EdgeInsets.all(10),
                          width: w,
                          height: 100,

                          child: Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              Column(
                                spacing: 10,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text("$size bytes"),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    if (isActive &&
                                        fullDuration.inMilliseconds > 0)
                                      LinearProgressIndicator(
                                        value:
                                            currentPosition.inMilliseconds /
                                            fullDuration.inMilliseconds,
                                      )
                                    else
                                      LinearProgressIndicator(value: 0),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            try {
                                              await flutterSoundPlayer
                                                  .stopPlayer();

                                              await streamSubscription
                                                  ?.cancel();
                                              streamSubscription = null;

                                              setState(() {
                                                currentPath = file.path;
                                                currentPosition = Duration.zero;
                                                fullDuration = Duration.zero;
                                              });

                                              await flutterSoundPlayer
                                                  .startPlayer(
                                                    fromURI: file.path,
                                                    codec: Codec.aacADTS,
                                                    sampleRate: 16000,
                                                    whenFinished: () {
                                                      setState(() {
                                                        currentPosition =
                                                            Duration.zero;
                                                        currentPath = null;
                                                      });
                                                    },
                                                  );

                                              setState(() {
                                                currentPath = file.path;
                                              });

                                              streamSubscription =
                                                  flutterSoundPlayer.onProgress
                                                      ?.listen((event) {
                                                        if (mounted &&
                                                            event
                                                                    .duration
                                                                    .inMilliseconds >
                                                                0) {
                                                          setState(() {
                                                            fullDuration =
                                                                event.duration;
                                                            currentPosition =
                                                                event.position;
                                                          });
                                                        }
                                                      });
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              toastError(
                                                'Erro ao tocar: $e',
                                                context,
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.play_arrow),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            try {
                                              await flutterSoundPlayer
                                                  .pausePlayer();
                                              setState(() {});
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              toastError(
                                                'Erro ao pausar: $e',
                                                context,
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.pause),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            try {
                                              await flutterSoundPlayer
                                                  .stopPlayer();
                                              streamSubscription?.cancel();
                                              setState(() {
                                                currentPosition = Duration.zero;
                                                currentPath = null;
                                              });
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              toastError(
                                                'Erro ao parar: $e',
                                                context,
                                              );
                                            }
                                          },
                                          icon: Icon(Icons.stop),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                      MaterialPageRoute(builder: (context) => Exer3()),
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
