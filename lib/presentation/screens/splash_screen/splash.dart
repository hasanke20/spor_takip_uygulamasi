import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:spor_takip_uygulamasi/logic/providers/user_data_provider.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/auth/login.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/index.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String quote = "Loading...";
  String author = "";
  bool isLoading = true;
  int remainingTime = 4;
  late UserDataProvider _userDataProvider;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
    _startCountdown();
    _userDataProvider = Provider.of<UserDataProvider>(context, listen: false);
  }

  /// Splash Screen işlemleri
  Future<void> _startSplashSequence() async {
    await fetchQuote(); // Alıntıyı yükle
  }

  /// Sayaç işlemi: Her saniye kalan süreyi azalt
  void _startCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 1) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel(); // Sayaç durdur
        _navigateAfterSplash(); // Yönlendirme yap
      }
    });
  }

  Future<void> _navigateAfterSplash() async {
    // Using the provider's observable values
    if (_userDataProvider.isLoggedIn) {
      Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => IndexApp()));
    } else {
      Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => LoginScreen()));
    }
  }

  /// Alıntı (quote) verilerini API'den yükle
  Future<void> fetchQuote() async {
    try {
      // "https://trainingapp.coalescestudio.solace.com.tr/getQuote"
      final response = await http.get(Uri.parse(
          "https://api.trainingapp.kansostudio.solace.com.tr/getQuote"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          quote = data['Data']['Quote'];
          author = data['Data']['Author'];
          isLoading = false;
        });
      } else {
        setState(() {
          quote = "Failed to load quote.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        quote = "Error fetching data.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Alıntı Gösterimi
            if (isLoading)
              CircularProgressIndicator(color: Colors.white)
            else
              Column(
                children: [
                  Text(
                    quote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "- $author",
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 50),
            // Yükleme Durumu Mesajı
            Text(
              "$remainingTime saniye sonra yönlendirileceksiniz...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
