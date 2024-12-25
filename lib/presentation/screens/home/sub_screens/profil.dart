import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String? username;
  String? email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['username'];
            email = currentUser.email;
            isLoading = false;
          });
        } else {
          setState(() {
            username = 'Kullanıcı adı bulunamadı';
            email = currentUser.email;
            isLoading = false;
          });
        }
      } catch (error) {
        setState(() {
          username = 'Veri alınırken hata oluştu: $error';
          email = currentUser.email;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        email = 'Kullanıcı oturumu açmamış';
        isLoading = false;
      });
    }
  }

  String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final accountDeletionManager = AccountDeletionManager();
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              if (isLoading) CircularProgressIndicator(),
              if (!isLoading) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '$uid'))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Kullanıcı ID\'si panoya kopyalandı!')),
                            );
                          });
                        },
                        child: Text(
                          'Username: ${username ?? 'Bilinmiyor'}',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Email: ${email ?? 'Bilinmiyor'}',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
              Spacer(),
              TextButton(
                onPressed: () {
                  accountDeletionManager.deleteUserAccount(context);
                },
                style: TextButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  'Hesabı Sil',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
