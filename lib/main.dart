import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/auth/login.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/assigner.dart';
import 'package:spor_takip_uygulamasi/presentation/splash/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Kullanıcı oturum bilgilerini kontrol et
  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('rememberMe') ?? false;
  final bool isLoggedIn = rememberMe && prefs.getString('email') != null;

  // Uygulama başlatılıyor
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ronin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.agdasimaTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          titleTextStyle: GoogleFonts.agdasima(
            textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => SplashScreen(isLoggedIn: isLoggedIn),
        ),
        GetPage(
          name: '/',
          page: () => LoginScreen(),
        ),
        GetPage(
          name: '/assigner',
          page: () => Assigner(),
        ),
      ],
    );
  }
}

FirebaseFirestore firestore = FirebaseFirestore.instance;
