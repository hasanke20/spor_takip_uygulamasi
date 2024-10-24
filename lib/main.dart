import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/auth/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC5l_y6CU2G4bLIUXgE4QwW6l71CtmsOVc",
      appId: "1:773843122627:android:1e70f11942671cc48be576",
      messagingSenderId: "773843122627",
      projectId: "hcode-spor-takip-programi",
    ),
  );
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.agdasimaTextTheme()),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => LoginScreen(),
        ),
      ],
      title: 'Weight Tracker',
    ),
  );
}

FirebaseFirestore firestore = FirebaseFirestore.instance;
