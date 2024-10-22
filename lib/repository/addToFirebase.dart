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
        'timestamp': FieldValue.serverTimestamp(), // Zaman damgası ekliyoruz
      });
      print("Program başarıyla eklendi: ${docRef.id}");
    } catch (e) {
      print("Program ekleme hatası: $e");
    }
  }

  static Future<void> editProgram(BuildContext context, DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    String programAdi = doc['programAdi'];

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Programı Düzenle'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Program Adı'),
              initialValue: programAdi,
              onChanged: (value) => programAdi = value,
              validator: (value) =>
                  value!.isEmpty ? 'Bu alan boş olamaz.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  FirebaseFirestore.instance
                      .collection(
                          'Users/${FirebaseAuth.instance.currentUser?.uid}/Programs')
                      .doc(doc.id)
                      .update({'programAdi': programAdi}).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Program başarıyla güncellendi!'),
                    ));
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Güncelleme hatası: $error'),
                    ));
                  });
                }
              },
              child: Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> deleteProgram(String programId) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance
          .collection('Users/$uid/Programs')
          .doc(programId)
          .delete();
      // Başarılı silme bildirimi
      print('Program başarıyla silindi.');
    } catch (e) {
      // Hata durumunda bildirim
      print('Silme hatası: $e');
    }
  }
}

class AddExercise {
  static CollectionReference exerciseRef(String uid) {
    return FirebaseFirestore.instance.collection('Users/$uid/Programs');
  }

  static Future<void> addExercise(
    BuildContext context, {
    required String hareketAdi,
    required String set,
    required String tekrar,
    required String agirlik,
  }) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kullanıcı kimliği alınamadı!'),
      ));
      return;
    }

    if (hareketAdi.isEmpty ||
        set.isEmpty ||
        tekrar.isEmpty ||
        agirlik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun!'),
      ));
      return;
    }

    CollectionReference ref = exerciseRef(uid);
    try {
      DocumentReference docRef = await ref.add({
        'hareketAdi': hareketAdi,
        'set': set,
        'tekrar': tekrar,
        'agirlik': agirlik,
      });
      print("Egzersiz başarıyla eklendi: ${docRef.id}");
    } catch (e) {
      print("Egzersiz ekleme hatası: $e");
    }
  }

  static Future<void> editExercise(
    String docId,
    String hareketAdi,
    String set,
    String tekrar,
    String agirlik,
  ) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    CollectionReference ref = exerciseRef(uid);
    try {
      await ref.doc(docId).update({
        'hareketAdi': hareketAdi,
        'set': set,
        'tekrar': tekrar,
        'agirlik': agirlik,
      });
      print("Program başarıyla güncellendi: $docId");
    } catch (e) {
      print("Program güncelleme hatası: $e");
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

/*class AddNewUser {
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
}*/
