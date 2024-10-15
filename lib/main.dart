import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/auth/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey:
          "AIzaSyC5l_y6CU2G4bLIUXgE4QwW6l71CtmsOVc", // paste your api key here
      appId:
          "1:773843122627:android:1e70f11942671cc48be576", //paste your app id here
      messagingSenderId: "773843122627", //paste your messagingSenderId here
      projectId: "hcode-spor-takip-programi", //paste your project id here
    ),
  );
  runApp(
    GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => LoginScreen(), // Ana sayfanızı başlangıç rotası yapın
        ),
        // Diğer rotaları buraya ekleyin
      ],
      title: 'Weight Tracker',
    ),
  );
}

FirebaseFirestore firestore = FirebaseFirestore.instance;
