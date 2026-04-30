import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Exer2 extends StatefulWidget {
  const Exer2({super.key});

  @override
  State<Exer2> createState() => _Exer2State();
}

class _Exer2State extends State<Exer2> {
  Directory? documents;
  Directory? cache;
  Directory? temp;

  FlutterSoundRecorder flutterSoundRecorder = FlutterSoundRecorder();
  bool recording = false;

  void startRec() async {
    setState(() {
      recording = true;
    });

    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) throw Exception("Mic permission denied");
      documents = documents ?? await getApplicationDocumentsDirectory();
      final path =
          "${documents!.path}/audio${DateTime.now().millisecondsSinceEpoch.toString()}.aac";
      setState(() {
        recording = true;
      });

      await flutterSoundRecorder.openRecorder();
      await flutterSoundRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      await Future.delayed(Duration(seconds: 5));
      final stop = await flutterSoundRecorder.stopRecorder();

      if (!mounted) return;

      setState(() {
        recording = false;
      });
      final exist = await File(stop!).exists();
      mounted
          ? toast("$exist | ${File(stop).lengthSync().toString()}", context)
          : null;
    } catch (e) {
      setState(() {
        recording = false;
      });
      throw Exception(e);
    }
  }

  @override
  void dispose() {
    flutterSoundRecorder.closeRecorder();
    super.dispose();
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
              Exercise(
                name: "2.2 - Record 5s, save on Documents",
                function: () async {
                  try {
                    startRec();
                  } catch (e) {
                    context.mounted
                        ? toastError('Cannot record: $e', context)
                        : null;
                  }
                },
                disable: recording,
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
