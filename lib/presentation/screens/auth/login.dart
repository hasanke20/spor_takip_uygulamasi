import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';
import 'package:toggle_switch/toggle_switch.dart';

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

  int _toggleIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Hata: Firebase başlatılamadı!')),
          );
        }

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_toggleIndex == 1) ...[
                    _buildTextField(
                      controller: _userNameController,
                      label: 'Kullanıcı Adı',
                    ),
                  ],
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                  ),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Şifre',
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  _buildActionButton(),
                  ElevatedButton(
                    onPressed: () async {
                      bool isSuccess = await SignInWithGoogle.signIn(context);
                      if (isSuccess) {
                        Get.to(Assigner());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Giriş yapılamadı, lütfen tekrar deneyin.')),
                        );
                      }
                    },
                    child: Text('Login with Google'),
                  ),
                  SizedBox(height: 20),
                  _buildToggleSwitch(),
                ],
              ),
            ),
          ),
        );
      },
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
        decoration: InputDecoration(labelText: label),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildActionButton() {
    return TextButton(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _toggleIndex == 1 ? 'Sign in' : 'Login',
            style: TextStyle(
              backgroundColor: Colors.black,
              color: Colors.white,
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
  }

  Widget _buildToggleSwitch() {
    return ToggleSwitch(
      minWidth: 90.0,
      initialLabelIndex: _toggleIndex,
      cornerRadius: 20.0,
      activeFgColor: Colors.white,
      inactiveBgColor: Colors.white,
      inactiveFgColor: Colors.black,
      totalSwitches: 2,
      labels: ['Login', 'Sign in'],
      activeBgColors: [
        [Colors.black],
        [Colors.black]
      ],
      onToggle: (index) {
        print('switched to: $index');
        setState(() {
          _toggleIndex = index ?? 0;
        });
      },
    );
  }
}
