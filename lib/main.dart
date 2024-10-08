import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/interfaces/assigner.dart';

void main() async {
  // Uygulama başlangıcında Flutter motorunu başlatın.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatın.
  await Firebase.initializeApp();

  // Uygulamayı çalıştırın.
  runApp(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => Assigner(), // Ana sayfanızı başlangıç rotası yapın
        ),
        // Diğer rotaları buraya ekleyin
      ],
      title: 'Weight Tracker',
    ),
  );
}

FirebaseFirestore firestore = FirebaseFirestore.instance;
