import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AddProgram {
  static CollectionReference programRef(String uid) {
    return FirebaseFirestore.instance.collection('Users/$uid/Programs');
  }

  static Future<void> addProgram(
    BuildContext context, {
    required String programAdi,
    required int targetCycle,
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
      print('$targetCycle');
      await docRef.collection('Dongu').doc('cycle').set({
        'targetCycle': targetCycle,
      });

      print("Alt koleksiyon başarıyla eklendi.");
    } catch (e) {
      print("Hata oluştu: $e");
    }
  }
}

class ShareProgram {
  static Future<void> shareProgram(BuildContext context,
      {required String programId,
      required String senderId,
      required String receiverId}) async {
    try {
      // Program verisini göndericiden al
      DocumentSnapshot programSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(senderId)
          .collection('Programs')
          .doc(programId)
          .get();

      if (programSnapshot.exists) {
        Map<String, dynamic> programData =
            programSnapshot.data() as Map<String, dynamic>;

        // Egzersiz koleksiyonunu al
        QuerySnapshot exercisesSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(senderId)
            .collection('Programs')
            .doc(programId)
            .collection('Exercises')
            .get();

        // Döngü koleksiyonunu al
        QuerySnapshot cyclesSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(senderId)
            .collection('Programs')
            .doc(programId)
            .collection('Dongu')
            .get();

        // Yeni program ID'si oluştur ve alıcıya gönder
        String receiverIdString = receiverId;
        String newProgramId = FirebaseFirestore.instance
            .collection('Users')
            .doc(receiverIdString)
            .collection('Programs')
            .doc()
            .id;

        // Program verisini alıcıya kopyala
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(receiverIdString)
            .collection('Programs')
            .doc(newProgramId)
            .set(programData);

        // Egzersiz koleksiyonunu alıcıya kopyala
        for (var exerciseDoc in exercisesSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(receiverIdString)
              .collection('Programs')
              .doc(newProgramId)
              .collection('Exercises')
              .doc(exerciseDoc.id)
              .set(exerciseDoc.data() as Map<String, dynamic>);
        }

        // Döngü koleksiyonunu alıcıya kopyala
        for (var cycleDoc in cyclesSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(receiverIdString)
              .collection('Programs')
              .doc(newProgramId)
              .collection('Dongu')
              .doc(cycleDoc.id)
              .set(cycleDoc.data() as Map<String, dynamic>);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Program başarıyla paylaşıldı!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Program bulunamadı!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: $e'),
      ));
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
      return false;
    }

    try {
      await exerciseRef(uid, programId).add({
        'hareketAdi': hareketAdi,
        'set': set,
        'tekrar': tekrar,
        'agirlik': agirlik,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print("Egzersiz ekleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Egzersiz ekleme hatası!'),
      ));
      return false;
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

class AddWeight {
  static Future<bool> addWeight(BuildContext context, double weight) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen giriş yapın.'),
        backgroundColor: Colors.red,
      ));
      return false;
    }

    try {
      await FirebaseFirestore.instance.collection('Users/$uid/Weight').add({
        'weight': weight,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kilo başarıyla eklendi!'),
      ));

      return true;
    } catch (e) {
      print('Kilo eklenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kilo ekleme hatası!'),
      ));
      return false;
    }
  }

  static Future<bool> editWeight(
      BuildContext context, String id, double weight) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen giriş yapın.'),
        backgroundColor: Colors.red,
      ));
      return false; // Kullanıcı girişi yok
    }

    try {
      await FirebaseFirestore.instance
          .collection('Users/$uid/Weight')
          .doc(id)
          .update({
        'weight': weight,
        'timestamp': FieldValue.serverTimestamp(), // Güncelleme zamanı
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kilo başarıyla güncellendi!'),
      ));

      return true;
    } catch (e) {
      print('Kilo güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kilo güncelleme hatası!'),
      ));
      return false;
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

  static Future<bool> signIn(BuildContext context,
      {bool rememberMe = false}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Kullanıcı oturum açmayı başlatıyor
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Kullanıcı oturum açmayı iptal ettiyse
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Oturum açma iptal edildi.'),
        ));
        return false;
      }

      // Google kimlik doğrulama bilgileri
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase kimlik bilgileri oluşturuluyor
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase ile oturum açma işlemi
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Kullanıcı bilgilerini Firestore'a kaydetme
      await usersRef.doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName,
        'email': userCredential.user!.email,
        'username': userCredential.user!.displayName ?? 'Kullanıcı Adı Yok',
      });

      // "Beni Hatırla" özelliği etkinse oturum bilgilerini kaydet
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);
        await prefs.setString('email', userCredential.user!.email ?? '');
        // Şifre Google ile girişte gerekmediği için saklanmaz
      }

      // Başarılı giriş mesajı
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oturum açıldı: ${userCredential.user!.displayName}'),
      ));
      return true;
    } catch (e) {
      // Hata mesajı gösterme
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oturum açarken hata oluştu: $e'),
      ));
      return false;
    }
  }

  static Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      // SharedPreferences'taki bilgileri temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Başarılı çıkış mesajı
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Başarıyla çıkış yapıldı.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Çıkış sırasında bir hata oluştu: $e'),
      ));
    }
  }
}

class AppleSignInService {
  static CollectionReference usersRef =
      FirebaseFirestore.instance.collection('Users');

  static Future<bool> signIn(BuildContext context,
      {bool rememberMe = false}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await usersRef.doc(userCredential.user!.uid).set({
        'name': appleCredential.givenName ?? 'Kullanıcı Adı Yok',
        'email': userCredential.user!.email ?? 'Email Yok',
        'username': appleCredential.givenName ?? 'Kullanıcı Adı Yok',
      });

      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);
        await prefs.setString(
            'email', userCredential.user!.email ?? 'Email Yok');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Oturum açıldı: ${userCredential.user!.email ?? 'Apple Kullanıcısı'}'),
      ));
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Apple ile giriş yaparken hata oluştu: $e'),
      ));
      return false;
    }
  }
}

class RegisterUser {
  static CollectionReference usersRef =
      FirebaseFirestore.instance.collection('Users');

  static Future<void> registerNewUser(
      BuildContext context, String username, String email, String password,
      {bool rememberMe = false}) async {
    try {
      // Firebase ile kullanıcı kaydı oluştur
      UserCredential userBilgileri = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Kullanıcı bilgilerini Firestore'a kaydet
      await usersRef.doc(userBilgileri.user!.uid).set({
        'username': username,
        'email': email,
        'password': password,
      });

      // Eğer "Beni Hatırla" seçiliyse bilgileri kaydet
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      }

      // Başarılı kayıt mesajı
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kullanıcı başarıyla kaydedildi!'),
      ));
    } on FirebaseAuthException catch (e) {
      // Firebase özel hatalarını yönet
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
      // Genel hataları yönet
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: $e'),
      ));
    }
  }

  // Kaydedilmiş oturum bilgilerini temizleme
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class LoginUser {
  static Future<User?> login(
      BuildContext context, String email, String password,
      {bool rememberMe = false}) async {
    try {
      // Firebase ile giriş
      UserCredential userBilgisi = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Eğer "Beni Hatırla" işaretliyse, bilgileri kaydet
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', true);
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      } else {
        // "Beni Hatırla" seçili değilse bilgileri temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }

      return userBilgisi.user;
    } on FirebaseAuthException catch (e) {
      // Firebase hatalarını yönet
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

  // Kaydedilmiş kullanıcı bilgilerini yüklemek için yardımcı fonksiyon
  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      return {
        'email': prefs.getString('email'),
        'password': prefs.getString('password'),
      };
    }
    return {'email': null, 'password': null};
  }

  // Kullanıcının oturum bilgilerini temizle
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class EditWeight {}

Future<void> incrementCompletedCycles(String programId) async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    print("Kullanıcı kimliği bulunamadı.");
    return;
  }

  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs/$programId/Dongu')
        .doc('cycle')
        .get();

    int completedCycle =
        (snapshot.data() as Map<String, dynamic>?)?['completedCycle'] ?? 0;

    int targetCycle =
        (snapshot.data() as Map<String, dynamic>?)?['targetCycle'] ?? 0;

    completedCycle++;
    if (completedCycle >= targetCycle) {
      print('$completedCycle');
      completedCycle = 0;
      print('$completedCycle');

      QuerySnapshot exercisesSnapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs/$programId/Exercises')
          .get();
      print('Ref alindi');

      for (var exercise in exercisesSnapshot.docs) {
        double currentWeight =
            (exercise.data() as Map<String, dynamic>)['agirlik'].toDouble() ??
                0.0;
        print('currentWeight: $currentWeight');

        double donguKilo =
            (exercise.data() as Map<String, dynamic>)['donguKilo'].toDouble() ??
                0.0;
        print('donguKilo: $currentWeight');

        await FirebaseFirestore.instance
            .collection('Users/$uid/Programs/$programId/Exercises')
            .doc(exercise.id)
            .update({'agirlik': (currentWeight + donguKilo).toDouble()});
        print('Kilolar toplandi');
      }
    }

    await FirebaseFirestore.instance
        .collection('Users/$uid/Programs/$programId/Dongu')
        .doc('cycle')
        .set({
      'targetCycle': targetCycle,
      'completedCycle': completedCycle,
    });

    print("completedCycle değeri başarıyla artırıldı.");
  } catch (error) {
    print("completedCycle değeri artırıl: $error");
  }
}
