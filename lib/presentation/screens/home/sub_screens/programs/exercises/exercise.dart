import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/programs/activeprogram/activeprogram.dart';

import '../../../../../../repository/addToFirebase.dart';

class ExerciseScreen extends StatefulWidget {
  final String programId;

  const ExerciseScreen({super.key, required this.programId});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final TextEditingController _hareketController = TextEditingController();
  final TextEditingController _setController = TextEditingController();
  final TextEditingController _tekrarController = TextEditingController();
  final TextEditingController _agirlikController = TextEditingController();

  String? uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Egzersizler',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[900],
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
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
                    return Center(
                        child: Text('Bir hata oluştu!',
                            style: TextStyle(color: Colors.white)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text('Egzersiz yok.',
                            style: TextStyle(color: Colors.white)));
                  }

                  final exerciseData = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: exerciseData.length,
                    itemBuilder: (context, index) {
                      var exercise = exerciseData[index];
                      return Card(
                        margin: EdgeInsets.all(10),
                        elevation: 5,
                        color: Colors.grey[850], // Kart rengi
                        child: ListTile(
                          title: Text(
                            'Hareket: ${exercise['hareketAdi']}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set: ${exercise['set']}',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                              Text('Tekrar: ${exercise['tekrar']}',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                              Text('Ağırlık: ${exercise['agirlik']}',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: Colors.white), // İkon rengi
                                onPressed: () {
                                  showEditDialog(exercise);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.white), // İkon rengi
                                onPressed: () async {
                                  await AddExercise.deleteExercise(
                                      context, exercise);
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showAddExerciseDialog();
          },
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
          backgroundColor: Colors.grey[800],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 50,
            width: 50,
            child: ElevatedButton(
              onPressed: () {
                Get.to(ActiveProgram(
                  programId: widget.programId,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
              child: Text(
                'Programı Başlat',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850], // Karanlık tema için arka plan
          title: Text('Egzersiz Ekle', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Hareket Adı',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _hareketController,
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Set',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _setController,
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Tekrar',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _tekrarController,
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Ağırlık',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _agirlikController,
                  style: TextStyle(color: Colors.white),
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
              child: Text('İptal', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                bool success = await AddExercise.addExercise(
                  context,
                  uid!,
                  widget.programId,
                  hareketAdi: _hareketController.text,
                  set: _setController.text,
                  tekrar: _tekrarController.text,
                  agirlik: _agirlikController.text,
                );

                if (success) {
                  Navigator.of(context).pop();
                  clearTextFields();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Egzersiz başarıyla eklendi!')),
                  );
                }
              },
              child: Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void showEditDialog(DocumentSnapshot exercise) {
    _hareketController.text = exercise['hareketAdi'];
    _setController.text = exercise['set'];
    _tekrarController.text = exercise['tekrar'];
    _agirlikController.text = exercise['agirlik'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850], // Karanlık tema için arka plan
          title:
              Text('Egzersiz Düzenle', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Hareket Adı',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _hareketController,
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Set',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _setController,
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Tekrar',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _tekrarController,
                  style: TextStyle(color: Colors.white),
                ),
                TextField(
                  decoration: InputDecoration(
                      labelText: 'Ağırlık',
                      labelStyle: TextStyle(color: Colors.white)),
                  controller: _agirlikController,
                  style: TextStyle(color: Colors.white),
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
              child: Text('İptal', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                await AddExercise.editExercise(
                  context,
                  exercise,
                  hareketAdi: _hareketController.text,
                  set: _setController.text,
                  tekrar: _tekrarController.text,
                  agirlik: _agirlikController.text,
                );
                Navigator.of(context).pop();
                clearTextFields();
              },
              child: Text('Güncelle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void clearTextFields() {
    _hareketController.clear();
    _setController.clear();
    _tekrarController.clear();
    _agirlikController.clear();
  }
}
