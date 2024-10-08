import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/interfaces/assigner.dart';

void main() => runApp(GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(
            name: '/',
            page: () => Assigner()), // Ana sayfanızı başlangıç rotası yapın
        // Diğer rotaları buraya ekleyin
      ],
      title: 'Weight Tracker',
    ));
