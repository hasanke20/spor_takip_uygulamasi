import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AddProgram {
  static CollectionReference programRef =
      FirebaseFirestore.instance.collection('Users/User.1/Program');

  static Future<void> addProgram(BuildContext context) async {
    try {
      await programRef.add({
        'Agirlik': 72,
        'Tarih': DateTime.now(),
        // Diğer verileri buraya ekleyebilirsiniz
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Program başarıyla eklendi!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veri eklerken hata oluştu: $e'),
      ));
    }
  }
}

class AddNewUser {
  static CollectionReference usersRef =
      FirebaseFirestore.instance.collection('Users');

  static Future<void> addNewUser(BuildContext context) async {
    try {
      await usersRef.add({
        'name': 'Ilk Uye',
        // Diğer verileri buraya ekleyebilirsiniz
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kullanıcı başarıyla eklendi!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veri eklerken hata oluştu: $e'),
      ));
    }
  }
}

class SignInWithGoogle {
  static CollectionReference usersRef =
      FirebaseFirestore.instance.collection('Users');

  // E-posta adresi için controller
  static TextEditingController emailController = TextEditingController();

  static Future<bool> signIn(BuildContext context) async {
    try {
      String? email = await _showEmailDialog(context);
      if (email == null || email.isEmpty) {
        return false;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Oturum açma iptal edildi.'),
        ));
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await usersRef.doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName,
        'email': email, // Kullanıcıdan alınan e-posta
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oturum açıldı: ${userCredential.user!.displayName}'),
      ));
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oturum açarken hata oluştu: $e'),
      ));
      return false;
    }
  }

  static Future<String?> _showEmailDialog(BuildContext context) async {
    String? email;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('E-posta Adresi'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(hintText: 'E-posta adresinizi girin'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                email = emailController.text;
                emailController.clear(); // Controller'ı temizle
                Navigator.of(context).pop(email); // E-posta adresini döndür
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  static void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Başarıyla çıkış yapıldı.'),
    ));
  }
}

class RegisterUser {
  static CollectionReference usersRef =
      FirebaseFirestore.instance.collection('Users');

  static Future<void> registerNewUser(BuildContext context, String username,
      String email, String password) async {
    try {
      UserCredential userBilgileri = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await usersRef.doc(userBilgileri.user!.uid).set({
        'username': username,
        'email': email,
        'password': password,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kullanıcı başarıyla kaydedildi!'),
      ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Girilen şifre çok zayıf.'),
        ));
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bu email ile kayıtlı bir kullanıcı zaten var.'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kayıt sırasında bir hata oluştu: ${e.message}'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: $e'),
      ));
    }
  }
}

class LoginUser {
  static Future<User?> login(
      BuildContext context, String email, String password) async {
    try {
      UserCredential userBilgisi = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userBilgisi.user;
    } on FirebaseAuthException catch (e) {
      // Hata oluşursa, hata mesajını döndürün.
      String errorMessage;

      if (e.code == 'user-not-found') {
        errorMessage = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Şifre hatalı.';
      } else {
        errorMessage = 'Giriş yapılamadı: ${e.message}';
      }

      throw Exception(errorMessage);
    }
  }
}
