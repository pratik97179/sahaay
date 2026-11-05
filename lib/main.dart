import 'package:flutter/material.dart';

void main() {
  runApp(SahaayApp());
}

class SahaayApp extends StatelessWidget {
  const SahaayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahhay',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Column(children: [
            ],
          )),
      ),
    );
  }
}
