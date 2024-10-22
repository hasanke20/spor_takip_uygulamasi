import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExerciseScreen extends StatefulWidget {
  final String programId; // programId parametresi

  const ExerciseScreen(
      {super.key, required this.programId}); // Yapıcıda programId'yi al

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final TextEditingController _hareketController = TextEditingController();
  final TextEditingController _setController = TextEditingController();
  final TextEditingController _tekrarController = TextEditingController();
  final TextEditingController _agirlikController = TextEditingController();

  String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Egzersizler'),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(
                        'Users/$uid/Programs/${widget.programId}/Exercises')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Bir hata oluştu!'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final exerciseData = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: exerciseData.length,
                    itemBuilder: (context, index) {
                      var exercise = exerciseData[index];
                      return Card(
                        margin: EdgeInsets.all(10),
                        elevation: 5,
                        child: ListTile(
                          title: Text('Hareket: ${exercise['hareketAdi']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set: ${exercise['set']}'),
                              Text('Tekrar: ${exercise['tekrar']}'),
                              Text('Ağırlık: ${exercise['agirlik']}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  showEditDialog(
                                      exercise); // Düzenleme pop-up'ı
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  try {
                                    await exercise.reference.delete();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text('Program başarıyla silindi!'),
                                    ));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Silme işlemi sırasında hata oluştu: $e'),
                                    ));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Card(
              margin: EdgeInsets.all(20),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Program Ekle'),
                              content: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                          labelText: 'Hareket Adı'),
                                      controller: _hareketController,
                                    ),
                                    TextField(
                                      decoration:
                                          InputDecoration(labelText: 'Set'),
                                      controller: _setController,
                                    ),
                                    TextField(
                                      decoration:
                                          InputDecoration(labelText: 'Tekrar'),
                                      controller: _tekrarController,
                                    ),
                                    TextField(
                                      decoration:
                                          InputDecoration(labelText: 'Ağırlık'),
                                      controller: _agirlikController,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    clearTextFields();
                                  },
                                  child: Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await addProgramToFirebase();
                                    if (_hareketController.text.isNotEmpty &&
                                        _setController.text.isNotEmpty &&
                                        _tekrarController.text.isNotEmpty &&
                                        _agirlikController.text.isNotEmpty) {
                                      clearTextFields();
                                    }
                                  },
                                  child: Text('Program Ekle +'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('Program Ekle+'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addProgramToFirebase() async {
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kullanıcı kimliği alınamadı!'),
      ));
      return;
    }

    if (_hareketController.text.isEmpty ||
        _setController.text.isEmpty ||
        _tekrarController.text.isEmpty ||
        _agirlikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun!'),
      ));
      return; // Boş alan varsa pop-up kapanmaz
    }

    try {
      // Firebase'e program ekleme
      await FirebaseFirestore.instance
          .collection(
              'Users/$uid/Programs/${widget.programId}/Exercises') // programId kullanımı
          .add({
        'hareketAdi': _hareketController.text,
        'set': _setController.text,
        'tekrar': _tekrarController.text,
        'agirlik': _agirlikController.text,
        'timestamp':
            FieldValue.serverTimestamp(), // Kaydedilme zamanı ekleniyor
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Program başarıyla eklendi!'),
      ));
      Navigator.of(context).pop(); // Tüm alanlar doluysa pop-up kapanır
    } catch (e) {
      print("Program ekleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Program ekleme hatası!'),
      ));
    }
  }

  Future<void> editProgramInFirebase(DocumentSnapshot program) async {
    if (_hareketController.text.isEmpty ||
        _setController.text.isEmpty ||
        _tekrarController.text.isEmpty ||
        _agirlikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen tüm alanları doldurun!'),
      ));
      return; // Boş alan varsa pop-up kapanmaz
    }

    try {
      // Firebase'deki programı güncelle
      await program.reference.update({
        'hareketAdi': _hareketController.text,
        'set': _setController.text,
        'tekrar': _tekrarController.text,
        'agirlik': _agirlikController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Program başarıyla güncellendi!'),
      ));
      Navigator.of(context).pop(); // Pop-up kapanır
    } catch (e) {
      print("Program güncelleme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Program güncelleme hatası!'),
      ));
    }
  }

  void clearTextFields() {
    _hareketController.clear();
    _setController.clear();
    _tekrarController.clear();
    _agirlikController.clear();
  }

  void showEditDialog(DocumentSnapshot program) {
    _hareketController.text = program['hareketAdi'];
    _setController.text = program['set'];
    _tekrarController.text = program['tekrar'];
    _agirlikController.text = program['agirlik'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Program Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Hareket Adı'),
                  controller: _hareketController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Set'),
                  controller: _setController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Tekrar'),
                  controller: _tekrarController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Ağırlık'),
                  controller: _agirlikController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearTextFields();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                await editProgramInFirebase(program);
                clearTextFields();
              },
              child: Text('Güncelle'),
            ),
          ],
        );
      },
    );
    clearTextFields();
  }
}
