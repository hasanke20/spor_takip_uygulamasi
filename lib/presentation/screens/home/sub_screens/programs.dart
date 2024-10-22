import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

import 'exercise.dart';

class ProgramsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users/$uid/Programs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Program yok.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Başlık ve butonları hizala
                    children: [
                      Expanded(
                        child: Text(doc['programAdi'],
                            overflow: TextOverflow.ellipsis), // Program adı
                      ),
                      Row(
                        children: [
                          // Düzenleme Butonu
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editProgram(context, doc);
                            },
                          ),
                          // Silme Butonu
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await _deleteProgram(doc.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseScreen(
                            programId:
                                doc.id), // doc.id ile programId'yi gönderiyoruz
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Yeni Program Ekle'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(labelText: 'Program Adı'),
              onChanged: (value) => programAdi = value,
              validator: (value) =>
                  value!.isEmpty ? 'Bu alan boş olamaz.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  AddProgram.addProgram(context, programAdi: programAdi);
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

    showDialog(
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
                  // Firestore'da güncelleme yapma
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

  Future<void> _deleteProgram(String programId) async {
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
