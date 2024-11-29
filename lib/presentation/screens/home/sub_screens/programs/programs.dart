import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              Text('Yeni Program Ekle', style: TextStyle(color: Colors.white)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'Program Adı',
                      labelStyle: TextStyle(color: Colors.white)),
                  onChanged: (value) => programAdi = value,
                  validator: (value) =>
                      value!.isEmpty ? 'Bu alan boş olamaz.' : null,
                  style: TextStyle(color: Colors.white),
                ),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'Döngü',
                      labelStyle: TextStyle(color: Colors.white)),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      targetCycle = int.tryParse(value) ?? 3;
                    }
                  },
                  validator: (value) =>
                      value!.isEmpty ? 'Bu alan boş olamaz.' : null,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  AddProgram.addProgram(context,
                      programAdi: programAdi, targetCycle: targetCycle);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Ekle',
                  style: TextStyle(color: Colors.blue)), // Metin rengi
            ),
          ],
        );
      },
    );
  }

  void _editProgram(BuildContext context, DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    String programAdi = doc['programAdi'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              Text('Programı Düzenle', style: TextStyle(color: Colors.white)),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(
                  labelText: 'Program Adı',
                  labelStyle: TextStyle(color: Colors.white)),
              initialValue: programAdi,
              onChanged: (value) => programAdi = value,
              validator: (value) =>
                  value!.isEmpty ? 'Bu alan boş olamaz.' : null,
              style: TextStyle(color: Colors.white),
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
              child: Text('Güncelle', style: TextStyle(color: Colors.blue)),
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Programı Paylaş', style: TextStyle(color: Colors.white)),
          content: Form(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: "Alıcının Kullanıcı ID'si",
                labelStyle: TextStyle(color: Colors.white),
              ),
              initialValue: receiverId?.toString(),
              onChanged: (value) {
                receiverId = value;
              },
              validator: (value) =>
                  value!.isEmpty ? 'Bu alan boş olamaz.' : null,
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (receiverId != null &&
                    await isUserExists(receiverId.toString()) == true) {
                  ShareProgram.shareProgram(
                    context,
                    programId: doc.id,
                    senderId: uid.toString(),
                    receiverId: receiverId!.toString(),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Geçerli bir Kullanıcı ID girin!'),
                  ));
                }
              },
              child: Text('Paylaş', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String programId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Dialog arka plan rengi
          title: Text('Bu programı silmek istediğinize emin misiniz?',
              style: TextStyle(color: Colors.white)), // Metin rengi
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // İptal et
              },
              child: Text(
                'Hayır',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // Metin rengi
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _deleteProgram(programId);
                Navigator.of(context).pop();
              },
              child: Text(
                'Evet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red, // Metin rengi
                ),
              ),
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
