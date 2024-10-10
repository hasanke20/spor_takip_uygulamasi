import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/presentation/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
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
