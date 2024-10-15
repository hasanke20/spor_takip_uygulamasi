// lib/program_screen.dart

import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Program Screen'),
              TextButton(
                  onPressed: () {
                    AddProgram.addProgram(context); // Fonksiyonu çağırıyoruz
                  },
                  child: Text('Program Ekle+')),
            ],
          ),
        ),
      ),
    );
  }
}
