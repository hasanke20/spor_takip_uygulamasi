import 'package:flutter/material.dart';

class IstatisticScreen extends StatefulWidget {
  const IstatisticScreen({super.key});

  @override
  State<IstatisticScreen> createState() => _IstatisticScreenState();
}

class _IstatisticScreenState extends State<IstatisticScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Istatistic Screen'),
            ],
          ),
        ),
      ),
    );
  }
}
