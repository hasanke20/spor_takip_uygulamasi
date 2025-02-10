import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/splash_screen/splash.dart';
import 'package:spor_takip_uygulamasi/logic/providers/user_data_provider.dart';

void main() async {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserDataProvider>(
            create: (context) => UserDataProvider()),
      ],
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Ronin',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          barBackgroundColor: CupertinoColors.systemBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: GoogleFonts.agdasima(
              fontSize: 16,
              color: CupertinoColors.black,
            ),
            navTitleTextStyle: GoogleFonts.agdasima(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
        ),
        // initialRoute: '/splash',
        home: SplashScreen(),
        // getPages: [
        //   GetPage(
        //     name: '/splash',
        //     page: () => SplashScreen(isLoggedIn: isLoggedIn),
        //   ),
        //   GetPage(
        //     name: '/',
        //     page: () => LoginScreen(),
        //   ),
        //   GetPage(
        //     name: '/assigner',
        //     page: () => Assigner(),
        //   ),
        // ],
      ),
    );
  }
}

FirebaseFirestore firestore = FirebaseFirestore.instance;
