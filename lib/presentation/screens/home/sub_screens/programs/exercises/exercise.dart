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

  String? uid;
  int completedCycles = 0;
  int cycle = 20;
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _fetchCycles();
  }

  Future<void> _fetchCycles() async {
    try {
      final completedCycleSnapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs/${widget.programId}/Dongu')
          .doc('completedCycle')
          .get();

      if (completedCycleSnapshot.exists &&
          completedCycleSnapshot.data() != null) {
        completedCycles = completedCycleSnapshot.data()!['cycle'] ?? 0;
      } else {
        print('Completed cycle document does not exist or has no data.');
      }

      final targetCycleSnapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs/${widget.programId}/Dongu')
          .doc('cycle')
          .get();

      if (targetCycleSnapshot.exists && targetCycleSnapshot.data() != null) {
        cycle = targetCycleSnapshot.data()!['cycle'];
      } else {
        print('Target cycle document does not exist or has no data.');
        cycle = 20;
      }
    } catch (e) {
      print('Error fetching cycles: $e');
    } finally {
      setState(() {
        isDataLoaded = true; // Veri yüklendikten sonra true yap
      });
    }
  }

  @override
  void dispose() {
    _hareketController.dispose();
    _setController.dispose();
    _tekrarController.dispose();
    _agirlikController.dispose();
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
          body: isDataLoaded
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildCycleField(context, completedCycles,
                              'Tamamlanan', Colors.white),
                          buildCycleField(
                              context, cycle, 'Hedef', Colors.white),
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
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
                )
              : Center(
                  child:
                      CircularProgressIndicator()), // Veri yükleniyorsa yükleme simgesi göster
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
                onPressed: () async {
                  await Get.to(
                      () => ActiveProgram(programId: widget.programId));
                  print("merhabaaaa");
                  setState(() {});
                  await _fetchCycles();
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
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              width: 50,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: kiloGirisController,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
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
                      // Kilo güncellemelerinin ekranda gösterilmesi
                      setState(() {}); // Ekranı güncelle
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
              icon: Icon(Icons.delete, color: Colors.white),
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
    final controller = TextEditingController(text: exercise[field].toString());

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
            controller: controller,
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

  Widget buildCycleField(
      BuildContext context, int value, String label, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color),
        ),
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DocumentSnapshot exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Silmek istediğinize emin misiniz?'),
          content: Text('Bu egzersizi silmek için onaylayın.'),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Sil'),
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

  void _editExercise(BuildContext context, DocumentSnapshot exercise) {
    final TextEditingController hareketController =
        TextEditingController(text: exercise['hareketAdi']);
    final TextEditingController setController =
        TextEditingController(text: exercise['set'].toString());
    final TextEditingController tekrarController =
        TextEditingController(text: exercise['tekrar'].toString());
    final TextEditingController agirlikController =
        TextEditingController(text: exercise['agirlik'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Egzersizi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hareketController,
                decoration: InputDecoration(labelText: 'Hareket Adı'),
              ),
              TextField(
                controller: setController,
                decoration: InputDecoration(labelText: 'Set'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: tekrarController,
                decoration: InputDecoration(labelText: 'Tekrar'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: agirlikController,
                decoration: InputDecoration(labelText: 'Ağırlık'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                await exercise.reference.update({
                  'hareketAdi': hareketController.text,
                  'set': int.parse(setController.text),
                  'tekrar': int.parse(tekrarController.text),
                  'agirlik': int.parse(agirlikController.text),
                });
                Navigator.of(context).pop();
              },
              child: Text('Kaydet'),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                if (_hareketController.text.isNotEmpty &&
                    _setController.text.isNotEmpty &&
                    _tekrarController.text.isNotEmpty &&
                    _agirlikController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection(
                          'Users/$uid/Programs/${widget.programId}/Exercises')
                      .add({
                    'hareketAdi': _hareketController.text,
                    'set': int.parse(_setController.text),
                    'tekrar': int.parse(_tekrarController.text),
                    'agirlik': int.parse(_agirlikController.text),
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  _hareketController.clear();
                  _setController.clear();
                  _tekrarController.clear();
                  _agirlikController.clear();
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
}
