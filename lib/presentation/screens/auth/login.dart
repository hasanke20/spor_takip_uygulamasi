import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

import '../home/index.dart';

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
        Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (context) => IndexApp()));
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
          return CupertinoPageScaffold(
            backgroundColor: CupertinoColors.black,
            child: Center(child: CupertinoActivityIndicator()),
          );
        } else if (snapshot.hasError) {
          return CupertinoPageScaffold(
            backgroundColor: CupertinoColors.black,
            child: Center(
                child: Text('Hata: Firebase başlatılamadı!',
                    style: TextStyle(color: CupertinoColors.destructiveRed))),
          );
        }

        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black,
          child: SafeArea(
            child: Center(
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
                          _buildTextField(
                              controller: _emailController, label: 'Email'),
                          _buildPasswordField(),
                          _buildActionButton(),
                          SizedBox(height: 20),
                          SignInButtons(
                            rememberMe: _rememberMe,
                            saveUserCredentials: _saveUserCredentials,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoSwitch(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value;
                                  });
                                },
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Beni Hatırla",
                                style: TextStyle(color: CupertinoColors.white),
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

  Widget _buildPasswordField() {
    return SizedBox(
      width: (MediaQuery.of(context).size.width * 3) / 5,
      child: CupertinoTextField(
        controller: _passwordController,
        style: TextStyle(color: CupertinoColors.white),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey,
              width: 1.0,
            ),
          ),
        ),
        placeholder: 'Şifre',
        placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
        suffix: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            _isPasswordVisible ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: CupertinoColors.white,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
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
      child: CupertinoTextField(
        controller: controller,
        style: TextStyle(color: CupertinoColors.white),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey,
              width: 1.0,
            ),
          ),
        ),
        placeholder: label,
        placeholderStyle: TextStyle(color: CupertinoColors.systemGrey),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildActionButton() {
    return Column(
      children: [
        if (_toggleIndex == 1)
          _buildTextField(
            controller: _userNameController,
            label: 'Kullanıcı Adı',
          ),
        SizedBox(height: 8),
        CupertinoButton(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(20.0),
          child: Text(
            _toggleIndex == 1 ? 'Kayıt Ol' : 'Giriş Yap',
            style: TextStyle(color: CupertinoColors.white),
          ),
          onPressed: () async {
            if (_toggleIndex == 1) {
              // Kayıt Ol
              try {
                if (_userNameController.text.isEmpty ||
                    _emailController.text.isEmpty ||
                    _passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }
                await RegisterUser.registerNewUser(
                  context,
                  _userNameController.text,
                  _emailController.text,
                  _passwordController.text,
                );
                Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(builder: (context) => IndexApp()));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Kayıt sırasında bir hata oluştu: ${e.toString()}')),
                );
              }
            } else {
              // Giriş Yap
              try {
                if (_emailController.text.isEmpty ||
                    _passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }
                User? user = await LoginUser.login(
                  context,
                  _emailController.text,
                  _passwordController.text,
                );

                if (user != null) {
                  print('Kullanıcı ID: ${user.uid}');
                  await Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(builder: (context) => IndexApp()));
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
        ),
        SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            _toggleIndex == 0
                ? "Hesabın yok mu? Kayıt Ol"
                : "Zaten hesabın var mı? Giriş Yap",
            style: TextStyle(color: CupertinoColors.activeBlue),
          ),
          onPressed: () {
            setState(() {
              _toggleIndex = _toggleIndex == 0 ? 1 : 0;
            });
          },
        ),
      ],
    );
  }
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
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            bool isSuccess = await SignInWithGoogle.signIn(
              context,
              rememberMe: rememberMe,
            );
            if (isSuccess) {
              if (rememberMe) {
                await saveUserCredentials();
              }
              Navigator.of(context).pushReplacement(
                  CupertinoPageRoute(builder: (context) => IndexApp()));
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
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
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
