import 'dart:io';
import 'dart:io' as io;

import 'package:day_1/exer2.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Exer1 extends StatefulWidget {
  const Exer1({super.key});

  @override
  State<Exer1> createState() => _Exer1State();
}

class _Exer1State extends State<Exer1> {
  Directory? documents;
  Directory? cache;
  Directory? temp;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Exercise(
                name: "1.1 - Documents, Cache and Temp",
                function: () async {
                  try {
                    if (Platform.isAndroid || Platform.isIOS) {
                      documents = await getApplicationDocumentsDirectory();
                      cache = await getApplicationCacheDirectory();
                      temp = await getTemporaryDirectory();

                      context.mounted ? toast(documents!.path, context) : null;
                      context.mounted ? toast(cache!.path, context) : null;
                      context.mounted ? toast(temp!.path, context) : null;
                    } else {
                      throw Exception("Platform not supported");
                    }
                  } catch (e) {
                    context.mounted
                        ? toastError(
                            'Cannot get download folder path: $e',
                            context,
                          )
                        : null;
                  }
                },
              ),
              Exercise(
                name: "1.2 - New file on Documents folder",
                function: () async {
                  try {
                    if (Platform.isAndroid || Platform.isIOS) {
                      documents =
                          documents ??
                          (documents =
                              await getApplicationDocumentsDirectory());

                      final myFile = File("${documents!.path}/notas.txt");

                      await myFile.writeAsString('Linha 1\nLinha 2\nLinha 3');

                      final contents = await myFile.readAsString();

                      if (!context.mounted) return;
                      toast('File contents:\n$contents', context);
                      toast('File path: ${myFile.path}', context);
                    } else {
                      throw Exception("Platform not supported");
                    }
                  } catch (e) {
                    context.mounted
                        ? toastError('Cannot create or read file: $e', context)
                        : null;
                  }
                },
              ),
              Exercise(
                name: "1.3 - Split file diretory",
                function: () async {
                  try {
                    if (Platform.isAndroid || Platform.isIOS) {
                      documents =
                          documents ?? await getApplicationDocumentsDirectory();
                      var myFile = File(
                        "${documents!.path}/audio_snap/recordings/teste.aac",
                      );

                      final dirname = p.dirname(myFile.path);
                      final basename = p.basename(myFile.path);
                      final extens = p.extension(myFile.path);

                      context.mounted ? toast(dirname, context) : null;
                      context.mounted ? toast(basename, context) : null;
                      context.mounted ? toast(extens, context) : null;
                    } else {
                      throw Exception("Platform not supported");
                    }
                  } catch (e) {
                    context.mounted
                        ? toastError('Cannot create or read file: $e', context)
                        : null;
                  }
                },
              ),
              Exercise(
                name: "1.4 - If diretory exist, do not create",
                function: () async {
                  try {
                    if (Platform.isAndroid || Platform.isIOS) {
                      documents =
                          documents ?? await getApplicationDocumentsDirectory();

                      var myFile = File(
                        "${documents!.path}/audio_snap/recordings/teste.aac",
                      );

                      final check = await myFile.exists();

                      if (!context.mounted) return;

                      if (check) {
                        toast(
                          "File already exists at:\n${documents!.path}/audio_snap/recordings/teste.aac",
                          context,
                        );
                      } else {
                        await myFile.parent.create(recursive: true);
                        await myFile.create(recursive: true);
                        context.mounted
                            ? toast("New file:  ${myFile.path}", context)
                            : null;
                      }
                    } else {
                      throw Exception();
                    }
                  } catch (e) {
                    context.mounted
                        ? toastError('Cannot create or read file: $e', context)
                        : null;
                  }
                },
              ),
              Exercise(
                name: "1.5 - List all files and size in Documents",
                function: () async {
                  documents =
                      documents ?? await getApplicationDocumentsDirectory();

                  final files = io.Directory(documents!.path).listSync();

                  if (!context.mounted) return;

                  for (var file in files) {
                    file is File
                        ? toast(
                            "$file | ${file.lengthSync().toString()}",
                            context,
                          )
                        : null;
                  }
                },
              ),
              SizedBox(),
              Container(
                width: w,
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
