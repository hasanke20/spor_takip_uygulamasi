import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String? username;
  String? email;
  bool isLoading = true; // Yükleme durumu için bir değişken ekle

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Kullanıcı verilerini almak için çağır
  }

  Future<void> _fetchUserData() async {
    User? currentUser =
        FirebaseAuth.instance.currentUser; // Şu anki kullanıcıyı al

    if (currentUser != null) {
      try {
        // Firestore'dan kullanıcı adını al
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // Belgenin varlığını kontrol et
          setState(() {
            username =
                userDoc['username']; // Firestore'dan alınan kullanıcı adı
            email = currentUser.email; // Firebase Auth'dan alınan email
            isLoading = false; // Yükleme tamamlandı
          });
        } else {
          // Eğer belge yoksa
          setState(() {
            username = 'Kullanıcı adı bulunamadı';
            email = currentUser.email; // Email yine de gösterilebilir
            isLoading = false; // Yükleme tamamlandı
          });
        }
      } catch (error) {
        // Hata yakala ve kullanıcıya bildir
        setState(() {
          username = 'Veri alınırken hata oluştu: $error'; // Hata mesajı göster
          email = currentUser.email; // Email yine de gösterilebilir
          isLoading = false; // Yükleme tamamlandı
        });
      }
    } else {
      setState(() {
        email = 'Kullanıcı oturumu açmamış'; // Kullanıcı yoksa mesaj göster
        isLoading = false; // Yükleme tamamlandı
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(child: Text('Profile Screen')),
              if (isLoading) // Yükleniyor durumu kontrolü
                CircularProgressIndicator(), // Yükleniyor göstergesi
              if (!isLoading) ...[
                SizedBox(
                  height: 80,
                ),
                Container(
                  padding: EdgeInsets.all(16), // İçerik için boşluk ekleyin
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black, // Kenarlık rengi
                      width: 2, // Kenarlık kalınlığı
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Username: ${username ?? 'Bilinmiyor'}',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text(
                        'Email: ${email ?? 'Bilinmiyor'}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
