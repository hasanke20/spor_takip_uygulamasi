import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/programs/activeprogram/activeprogram.dart';

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
  final TextEditingController _donguController = TextEditingController();

  String? uid;
  int completedCycles = 0;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _fetchCompletedCycles(); // Tamamlanan döngü verisini çek
  }

  Future<void> _fetchCompletedCycles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs/${widget.programId}/Dongu')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        completedCycles =
            snapshot.docs.length; // Tamamlanan döngü sayısını güncelle
      });
    }
  }

  @override
  void dispose() {
    _hareketController.dispose();
    _setController.dispose();
    _tekrarController.dispose();
    _agirlikController.dispose();
    _donguController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {},
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Tamamlanan Döngü: $completedCycles',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: 80,
                      child: TextField(
                        controller: _donguController,
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Döngü',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _updateCycles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: Text(
                        'Kaydet',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
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
                            style: TextStyle(color: Colors.white)),
                      );
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
                        return buildExerciseCard(context, exercise);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: showAddExerciseDialog,
            child: Icon(Icons.add, color: Colors.black),
            backgroundColor: Colors.blueAccent,
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Get.to(ActiveProgram(programId: widget.programId));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: Text('Programı Başlat',
                    style: TextStyle(fontSize: 20, color: Colors.black)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildExerciseCard(BuildContext context, DocumentSnapshot exercise) {
    final TextEditingController kiloGirisController = TextEditingController();

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      color: Colors.grey[850],
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Hareket: ${exercise['hareketAdi']}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius:
                    BorderRadius.all(Radius.circular(20)), // Köşe yuvarlama
              ),
              width: 50,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: kiloGirisController,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20), // Yazı boyutunu ayarlayın
                  textAlign: TextAlign.center, // Ortaya hizalama
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Kilo',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      int additionalWeight = int.parse(value);
                      int existingWeight = int.parse(exercise['agirlik']);
                      int updatedWeight = existingWeight + additionalWeight;
                      await exercise.reference
                          .update({'agirlik': updatedWeight});
                    }
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                _editExercise(context, exercise);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, exercise),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildEditableField(
                context, exercise, exercise.id, 'set', Colors.grey.shade400),
            SizedBox(width: 5),
            Text('x', style: TextStyle(color: Colors.white, fontSize: 30)),
            SizedBox(width: 10),
            buildEditableField(
                context, exercise, exercise.id, 'tekrar', Colors.grey.shade400),
            SizedBox(width: 10),
            buildEditableField(
                context, exercise, exercise.id, 'agirlik', Colors.white),
            SizedBox(width: 10),
            Text('kg', style: TextStyle(color: Colors.white, fontSize: 30)),
          ],
        ),
      ),
    );
  }

  Widget buildEditableField(BuildContext context, DocumentSnapshot exercise,
      String exerciseId, String field, Color color) {
    return Flexible(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            textAlign: TextAlign.center,
            controller: TextEditingController(text: exercise[field].toString()),
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 30, color: color),
            decoration: InputDecoration(border: InputBorder.none),
            onSubmitted: (updatedValue) async {
              if (updatedValue.isNotEmpty) {
                await exercise.reference.update({field: updatedValue});
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _updateCycles() async {
    if (_donguController.text.isNotEmpty) {
      int newCycles = int.parse(_donguController.text);
      setState(() {
        completedCycles += newCycles; // Güncellenen döngü sayısını artır
      });

      // Tamamlanan döngüleri Firestore'a ekle
      for (int i = 0; i < newCycles; i++) {
        await FirebaseFirestore.instance
            .collection('Users/$uid/Programs/${widget.programId}/Dongu')
            .add({
          'completedAt': FieldValue.serverTimestamp(), // Tamamlanma zamanı
        });
      }

      _donguController.clear(); // TextField'i temizle
    }
  }

  Future<void> _editExercise(
      BuildContext context, DocumentSnapshot exercise) async {
    // Burada egzersizi düzenleme mantığını ekleyebilirsiniz.
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, DocumentSnapshot exercise) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Silme Onayı'),
          content: Text('Bu egzersizi silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hayır'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Evet'),
              onPressed: () async {
                await exercise.reference.delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Egzersiz Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _hareketController,
                decoration: InputDecoration(labelText: 'Hareket Adı'),
              ),
              TextField(
                controller: _setController,
                decoration: InputDecoration(labelText: 'Set'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _tekrarController,
                decoration: InputDecoration(labelText: 'Tekrar'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _agirlikController,
                decoration: InputDecoration(labelText: 'Ağırlık'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Ekle'),
              onPressed: () {
                _addExercise();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExercise() async {
    if (_hareketController.text.isNotEmpty &&
        _setController.text.isNotEmpty &&
        _tekrarController.text.isNotEmpty &&
        _agirlikController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('Users/$uid/Programs/${widget.programId}/Exercises')
          .add({
        'hareketAdi': _hareketController.text,
        'set': int.parse(_setController.text),
        'tekrar': int.parse(_tekrarController.text),
        'agirlik': int.parse(_agirlikController.text),
        'timestamp': FieldValue.serverTimestamp(), // Zaman damgası ekle
      });

      _hareketController.clear();
      _setController.clear();
      _tekrarController.clear();
      _agirlikController.clear();
    }
  }
}
