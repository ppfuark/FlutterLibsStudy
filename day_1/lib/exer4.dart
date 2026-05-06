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
        child: SingleChildScrollView(child: Column(children: [])),
      ),
    );
  }
}
