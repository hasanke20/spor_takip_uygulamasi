import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

import '../home/assigner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => LoginScreen(),
        ),
      ],
      title: 'Spor Takip Uygulaması',
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  int _toggleIndex = 0;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

// Kullanıcı oturum bilgilerini kaydet
  Future<void> _saveUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.clear(); // "Beni Hatırla" seçili değilse bilgileri temizle
    }
  }

// Login butonuna tıklandığında çağrılacak
  Future<void> _handleLogin() async {
    try {
      User? user = await LoginUser.login(
        context,
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        await _saveUserCredentials(); // Oturum bilgilerini kaydet
        Get.to(Assigner());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapılamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
                child: Text('Hata: Firebase başlatılamadı!',
                    style: TextStyle(color: Colors.red))),
          );
        }

        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black, // Arka plan rengi
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SignInButtons(
                            rememberMe: _rememberMe,
                            saveUserCredentials: _saveUserCredentials,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                              ),
                              Text(
                                "Beni Hatırla",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /*Widget _buildPasswordField() {
    return SizedBox(
      width: (MediaQuery.of(context).size.width * 3) / 5,
      child: TextFormField(
        controller: _passwordController,
        style: TextStyle(color: Colors.white), // Metin rengi
        decoration: InputDecoration(
          labelText: 'Şifre',
          labelStyle: TextStyle(color: Colors.white), // Etiket rengi
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white, // Suffix ikon rengi
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
        obscureText: !_isPasswordVisible,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width * 3) / 5,
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white), // Metin rengi
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white), // Etiket rengi
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Colors.grey), // Aktif olmayan kenar rengi
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Colors.blueAccent), // Aktif kenar rengi
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildActionButton() {
    return TextButton(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent, // Buton rengi
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _toggleIndex == 1 ? 'Kayıt Ol' : 'Giriş Yap',
            style: TextStyle(
              color: Colors.white, // Metin rengi
            ),
          ),
        ),
      ),
      onPressed: () async {
        if (_toggleIndex == 1) {
          try {
            await RegisterUser.registerNewUser(
              context,
              _userNameController.text,
              _emailController.text,
              _passwordController.text,
            );
            await Get.to(Assigner());
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Kayıt sırasında bir hata oluştu: ${e.toString()}')),
            );
          }
        } else {
          try {
            User? user = await LoginUser.login(
              context,
              _emailController.text,
              _passwordController.text,
            );

            if (user != null) {
              print('Kullanıcı ID: ${user.uid}');
              await Get.to(Assigner());
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Üye girişi sırasında bir hata oluştu: ${e.toString()}')),
            );
          }
        }
      },
    );
  }*/
}

class SignInButtons extends StatelessWidget {
  final bool rememberMe;
  final Future<void> Function() saveUserCredentials;

  const SignInButtons({
    Key? key,
    required this.rememberMe,
    required this.saveUserCredentials,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google ile Giriş Yap Butonu
        GestureDetector(
          onTap: () async {
            bool isSuccess = await SignInWithGoogle.signIn(
              context,
              rememberMe: rememberMe,
            );
            if (isSuccess) {
              if (rememberMe) {
                await saveUserCredentials();
              }
              Get.to(Assigner());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Google ile giriş yapılamadı, tekrar deneyin!'),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Google ile Devam Et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16), // Butonlar arasında boşluk
        // Apple ile Giriş Yap Butonu
        GestureDetector(
          onTap: () async {
            bool isSuccess = await AppleSignInService.signIn(context);
            if (isSuccess) {
              // Başarılı giriş sonrası yönlendirme
              print("Apple ile giriş başarılı!");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Apple ile giriş yapılamadı, tekrar deneyin!'),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900], // Siyah arka plan
              borderRadius:
                  BorderRadius.circular(8.0), // Yuvarlatılmış kenarlar
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/apple_logo.png', // Apple logosunun yolu
                  height: 24,
                  width: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Apple ile Devam Et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
