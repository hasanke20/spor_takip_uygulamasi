import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AddProgram {
  static CollectionReference programRef(String uid) {
    return FirebaseFirestore.instance.collection('Users/$uid/Programs');
  }

  static Future<void> addProgram(
    BuildContext context, {
    required String programAdi,
  }) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kullanıcı kimliği alınamadı!'),
      ));
      return;
    }

    if (programAdi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun!'),
      ));
      return;
    }

    CollectionReference ref = programRef(uid);
    try {
      DocumentReference docRef = await ref.add({
        'programAdi': programAdi,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Program başarıyla eklendi: ${docRef.id}");
    } catch (e) {
      print("Program ekleme hatası: $e");
    }
  }
}

class AddExercise {
  static CollectionReference exerciseRef(String uid, String programId) {
    return FirebaseFirestore.instance
        .collection('Users/$uid/Programs/$programId/Exercises');
  }

  static Future<bool> addExercise(
    BuildContext context,
    String uid,
    String programId, {
    required String hareketAdi,
    required String set,
    required String tekrar,
    required String agirlik,
  }) async {
    if (hareketAdi.isEmpty ||
        set.isEmpty ||
        tekrar.isEmpty ||
        agirlik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun!'),
      ));
      return false; // Başarısız olduğu için false döndürüyoruz
    }

    try {
      await exerciseRef(uid, programId).add({
        'hareketAdi': hareketAdi,
        'set': set,
        'tekrar': tekrar,
        'agirlik': agirlik,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true; // Başarılı olduğu için true döndürüyoruz
    } catch (e) {
      print("Egzersiz ekleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Egzersiz ekleme hatası!'),
      ));
      return false; // Başarısız olduğu için false döndürüyoruz
    }
  }

  static Future<void> editExercise(
    BuildContext context,
    DocumentSnapshot exercise, {
    required String hareketAdi,
    required String set,
    required String tekrar,
    required String agirlik,
  }) async {
    if (hareketAdi.isEmpty ||
        set.isEmpty ||
        tekrar.isEmpty ||
        agirlik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun!'),
      ));
      return;
    }

    try {
      await exercise.reference.update({
        'hareketAdi': hareketAdi,
        'set': set,
        'tekrar': tekrar,
        'agirlik': agirlik,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Egzersiz başarıyla güncellendi!'),
      ));
    } catch (e) {
      print("Egzersiz güncelleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Egzersiz güncelleme hatası!'),
      ));
    }
  }

  static Future<void> deleteExercise(
      BuildContext context, DocumentSnapshot exercise) async {
    try {
      await exercise.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Egzersiz başarıyla silindi!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Silme işlemi sırasında hata oluştu: $e'),
      ));
    }
  }
}

class LastProgram {
  final String? uid;

  LastProgram() : uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> lastProgram(String programId) async {
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('Users/$uid/Values')
          .doc('LastProgram')
          .set({
        'programId': programId,
      });
    } else {
      print('Kullanıcı kimliği bulunamadı.');
    }
  }
}

class SignInWithGoogle {
  static CollectionReference usersRef =
      FirebaseFirestore.instance.collection('Users');

  static Future<bool> signIn(BuildContext context) async {
    try {
      // GoogleSignIn nesnesini oluştur
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Google ile oturum açmayı başlat
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Kullanıcı oturum açmayı iptal ettiyse
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Oturum açma iptal edildi.'),
        ));
        return false;
      }

      // Google kimlik doğrulaması
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase kimlik bilgileri oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile oturum aç
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Kullanıcı bilgilerini Firestore'a kaydet
      await usersRef.doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName,
        'email': userCredential
            .user!.email, // Kullanıcının Google hesabındaki e-posta
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
