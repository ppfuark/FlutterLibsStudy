import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Exer4 extends StatefulWidget {
  const Exer4({super.key});

  @override
  State<Exer4> createState() => _Exer4State();
}

class _Exer4State extends State<Exer4> {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: w,
        height: h,
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            spacing: 20,
            children: [
              Exercise(
                name: "4.1 - File picker only for audios",
                function: () async {
                  try {
                    FilePickerResult? result = await FilePicker.pickFiles(
                      type: FileType.audio,
                    );
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      if (context.mounted) {
                        toast("Arquivo selecionado: ${file.name}", context);
                        toast(
                          "Arquivo selecionado: ${file.size.toString()}",
                          context,
                        );
                        toast("Arquivo selecionado: ${file.path}", context);
                      }
                    } else {
                      context.mounted
                          ? toastError("Seleção de arquivo cancelada", context)
                          : null;
                    }
                  } catch (e) {
                    context.mounted
                        ? toastError("Erro na seleção de arquivo: $e", context)
                        : null;
                  }
                },
              ),
              Exercise(
                name: "4.2 - File picker, custom type",
                function: () async {
                  try {
                    FilePickerResult? result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['mp3', 'aac', 'm4a'],
                    );
                    if (result != null) {
                      PlatformFile file = result.files.first;
                      if (context.mounted) {
                        toast("Arquivo selecionado: ${file.name}", context);
                        toast(
                          "Arquivo selecionado: ${file.size.toString()}",
                          context,
                        );
                        toast("Arquivo selecionado: ${file.path}", context);
                      }
                    } else {
                      context.mounted
                          ? toastError("Seleção de arquivo cancelada", context)
                          : null;
                    }
                  } catch (e) {
                    context.mounted
                        ? toastError("Erro na seleção de arquivo: $e", context)
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
