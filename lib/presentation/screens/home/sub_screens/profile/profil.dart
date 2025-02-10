import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              if (isLoading) CupertinoActivityIndicator(),
              if (!isLoading) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.darkBackgroundGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.black,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      CupertinoButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '$uid'))
                              .then((_) {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) =>
                                  CupertinoActionSheet(
                                message:
                                    Text('Kullanıcı ID\'si panoya kopyalandı!'),
                                actions: [
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Tamam'),
                                  ),
                                ],
                              ),
                            );
                          });
                        },
                        child: Text(
                          'Username: ${username ?? 'Bilinmiyor'}',
                          style: TextStyle(
                              color: CupertinoColors.white, fontSize: 18),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        'Email: ${email ?? 'Bilinmiyor'}',
                        style: TextStyle(
                            color: CupertinoColors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
              Spacer(),
              CupertinoButton(
                onPressed: () {
                  accountDeletionManager.deleteUserAccount(context);
                },
                color: CupertinoColors.destructiveRed,
                child: Text(
                  'Hesabı Sil',
                  style: TextStyle(color: CupertinoColors.white, fontSize: 16),
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
