import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/presentation/assigner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Get.to(Assigner());
              },
              child: Text('Login',
                  style: TextStyle(
                      backgroundColor: Colors.black, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
