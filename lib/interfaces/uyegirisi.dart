import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/interfaces/home.dart';

class UyeGirisi extends StatefulWidget {
  const UyeGirisi({super.key});

  @override
  State<UyeGirisi> createState() => _UyeGirisiState();
}

class _UyeGirisiState extends State<UyeGirisi> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Uye Girisi'),
          TextButton(
            onPressed: () {
              Get.to(() => Home());
            },
            child: Text(
              'Ana Sayfa',
            ),
          ),
        ],
      ),
    );
  }
}
