import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

import 'exercises/exercise.dart';

class ProgramsScreen extends StatefulWidget {
  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  @override
  Widget build(BuildContext context) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users/$uid/Programs')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('Program yok.',
                    style: TextStyle(color: Colors.white)));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: EdgeInsets.all(8.0),
                color: Colors.grey[900],
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc['programAdi'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 25, color: Colors.white),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.share, color: Colors.white),
                            onPressed: () {
                              _shareProgram(context, doc);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              _editProgram(context, doc);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () async {
                              _confirmDelete(context, doc.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Oluşturulma Tarihi: ${DateFormat('dd/MM/yyyy').format(doc['timestamp']?.toDate().toLocal() ?? DateTime.now())}',
                    style: TextStyle(color: Colors.grey), // Metin rengi
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseScreen(programId: doc.id),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          _addProgram(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _addProgram(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String programAdi = '';
    int targetCycle = 3;

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Yeni Program Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CupertinoTextField(
                  placeholder: 'Program Adı',
                  onChanged: (value) => programAdi = value,
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CupertinoTextField(
                  placeholder: 'Döngü',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      targetCycle = int.tryParse(value) ?? 3;
                    }
                  },
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
              isDefaultAction: true,
            ),
            CupertinoDialogAction(
              onPressed: () {
                if (programAdi.isNotEmpty) {
                  AddProgram.addProgram(context,
                      programAdi: programAdi, targetCycle: targetCycle);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _editProgram(BuildContext context, DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    String programAdi = doc['programAdi'];

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Programı Düzenle'),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CupertinoTextField(
              placeholder: 'Program Adı',
              onChanged: (value) => programAdi = value,
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
              isDefaultAction: true,
            ),
            CupertinoDialogAction(
              onPressed: () {
                if (programAdi.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection(
                          'Users/${FirebaseAuth.instance.currentUser?.uid}/Programs')
                      .doc(doc.id)
                      .update({'programAdi': programAdi}).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Program başarıyla güncellendi!',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green,
                    ));
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Güncelleme hatası: $error',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
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

  bool _isElevenDigits(int number) {
    if (number >= 10000000000 && number < 100000000000) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> isUserExists(String receiverId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(receiverId)
          .get();
      return true;
    } catch (e) {
      print('Hata: $e');
      return false;
    }
  }

  void _shareProgram(BuildContext context, DocumentSnapshot doc) {
    String? receiverId;
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Programı Paylaş'),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CupertinoTextField(
              placeholder: "Alıcının Kullanıcı ID'si",
              onChanged: (value) {
                receiverId = value;
              },
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
              isDefaultAction: true,
            ),
            CupertinoDialogAction(
              onPressed: () async {
                if (receiverId != null &&
                    await isUserExists(receiverId.toString()) == true) {
                  ShareProgram.shareProgram(
                    context,
                    programId: doc.id,
                    senderId: uid.toString(),
                    receiverId: receiverId!.toString(),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Geçerli bir Kullanıcı ID girin!'),
                  ));
                }
              },
              child: Text('Paylaş'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String programId) async {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Bu programı silmek istediğinize emin misiniz?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hayır'),
              isDefaultAction: true,
            ),
            CupertinoDialogAction(
              onPressed: () async {
                await _deleteProgram(programId);
                Navigator.of(context).pop();
              },
              child: Text('Evet'),
              isDestructiveAction: true,
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProgram(String programId) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance
          .collection('Users/$uid/Programs')
          .doc(programId)
          .delete();
      print('Program başarıyla silindi.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Program başarıyla silindi.',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Silme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Silme hatası: $e', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    }
  }
}
