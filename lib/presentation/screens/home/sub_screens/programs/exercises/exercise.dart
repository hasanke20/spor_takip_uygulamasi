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
  int _completedCycle = 0;
  int _targetCycle = 3;
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _fetchCycles();
  }

  Future<String> programAdi() async {
    try {
      final programAdiSnapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs')
          .doc(widget.programId)
          .get();

      if (programAdiSnapshot.exists && programAdiSnapshot.data() != null) {
        return programAdiSnapshot.data()!['programAdi'] ?? 'Egzersizler';
      } else {
        print('Program adı bulunamadı.');
        return 'Bilinmeyen Program';
      }
    } catch (e) {
      print('Hata: $e');
      return 'Hata';
    }
  }

  Future<void> _fetchCycles() async {
    try {
      final completedCycleSnapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Programs/${widget.programId}/Dongu')
          .doc('cycle')
          .get();

      if (completedCycleSnapshot.exists &&
          completedCycleSnapshot.data() != null) {
        _completedCycle = completedCycleSnapshot.data()!['completedCycle'] ?? 0;
        _targetCycle = completedCycleSnapshot.data()!['targetCycle'] ?? 3;
      } else {
        print('Completed cycle document does not exist or has no data.');
      }
    } catch (e) {
      print('Error fetching cycles: $e');
    } finally {
      setState(() {
        isDataLoaded = true;
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
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back, color: Colors.white),
            ),
            backgroundColor: Colors.black,
            title: FutureBuilder<String>(
              future: programAdi(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Hata: ${snapshot.error}',
                      style: TextStyle(color: Colors.red));
                } else if (snapshot.hasData) {
                  return Text(
                    snapshot.data ?? 'Program Adı Yok',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  );
                } else {
                  return Text('Program adı alınamadı');
                }
              },
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
                          buildCycleField(context, _completedCycle,
                              'Tamamlanan', Colors.white),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: () async {
                                  String? newTargetCycle =
                                      await _showEditTargetCycleDialog();
                                  if (newTargetCycle != null &&
                                      newTargetCycle.isNotEmpty) {
                                    await FirebaseFirestore.instance
                                        .collection(
                                            'Users/$uid/Programs/${widget.programId}/Dongu')
                                        .doc('cycle')
                                        .update({
                                      'targetCycle': int.parse(newTargetCycle),
                                    });
                                    // Fetch the updated cycles
                                    await _fetchCycles();
                                  }
                                },
                              ),
                              buildCycleField(
                                  context, _targetCycle, 'Hedef', Colors.white),
                            ],
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
              : Center(child: CircularProgressIndicator()),
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

  Future<String?> _showEditTargetCycleDialog() async {
    TextEditingController targetCycleController =
        TextEditingController(text: _targetCycle.toString());

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Koyu tema arka plan rengi
          title: Text(
            'Hedef Döngü Düzenle',
            style: TextStyle(color: Colors.white), // Başlık metin rengi
          ),
          content: TextField(
            controller: targetCycleController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Yeni Hedef Döngü',
              labelStyle: TextStyle(color: Colors.white), // Etiket rengi
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Alt çizgi rengi
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.blueAccent), // Seçili çizgi rengi
              ),
            ),
            style: TextStyle(color: Colors.white), // Metin rengi
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.white), // "İptal" buton rengi
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(targetCycleController.text);
              },
              child: Text(
                'Kaydet',
                style:
                    TextStyle(color: Colors.blueAccent), // "Kaydet" buton rengi
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildExerciseCard(BuildContext context, DocumentSnapshot exercise) {
    final TextEditingController _donguKiloController = TextEditingController();

    final donguKilo = exercise['donguKilo'] ?? 0;

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      color: Colors.grey[900],
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
            SizedBox(width: 10),
            Row(
              children: [
                Icon(
                  Icons.loop,
                  color: Colors.grey,
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
                      controller: _donguKiloController,
                      style: TextStyle(color: Colors.white, fontSize: 30),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: donguKilo.toString(),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 30),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) async {
                        if (value.isNotEmpty) {
                          // Yeni donguKilo değerini kaydetme
                          await exercise.reference.update({
                            'donguKilo': int.parse(_donguKiloController.text),
                          });

                          // Ekranı güncelleme
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
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
                try {
                  await exercise.reference
                      .update({field: int.parse(updatedValue)});

                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Güncelleme hatası: $e")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Boş bir değer gönderilemez!")),
                );
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
    final TextEditingController donguKiloController =
        TextEditingController(text: exercise['donguKilo'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Egzersizi Düzenle',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[900],
          content: SingleChildScrollView(
            // Eklenen kaydırma desteği
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(hareketController, 'Hareket Adı'),
                _buildTextField(setController, 'Set',
                    keyboardType: TextInputType.number),
                _buildTextField(tekrarController, 'Tekrar',
                    keyboardType: TextInputType.number),
                _buildTextField(agirlikController, 'Ağırlık',
                    keyboardType: TextInputType.number),
                _buildTextField(donguKiloController, 'Döngü Kilo',
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await exercise.reference.update({
                    'hareketAdi': hareketController.text,
                    'set': int.parse(setController.text),
                    'tekrar': int.parse(tekrarController.text),
                    'agirlik': int.parse(agirlikController.text),
                    'donguKilo': int.parse(donguKiloController.text),
                  });

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Egzersiz başarıyla güncellendi!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Güncelleme hatası: $e")),
                  );
                }
              },
              child: Text(
                'Kaydet',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      style: TextStyle(color: Colors.white),
    );
  }

  void showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // Koyu tema arka plan rengi
          title: Text(
            'Egzersiz Ekle',
            style: TextStyle(color: Colors.white), // Başlık metin rengi
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _hareketController,
                  decoration: InputDecoration(
                    labelText: 'Hareket Adı',
                    labelStyle: TextStyle(color: Colors.white), // Etiket rengi
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white), // Kenar çizgi
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white), // Seçili çizgi
                    ),
                  ),
                  style: TextStyle(color: Colors.white), // Metin rengi
                ),
                TextField(
                  controller: _setController,
                  decoration: InputDecoration(
                    labelText: 'Set',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _tekrarController,
                  decoration: InputDecoration(
                    labelText: 'Tekrar',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _agirlikController,
                  decoration: InputDecoration(
                    labelText: 'Ağırlık',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _donguController,
                  decoration: InputDecoration(
                    labelText: 'Döngü Kilo',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.white), // Buton rengi kırmızı
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_hareketController.text.isNotEmpty &&
                    _setController.text.isNotEmpty &&
                    _tekrarController.text.isNotEmpty &&
                    _agirlikController.text.isNotEmpty &&
                    _donguController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection(
                            'Users/$uid/Programs/${widget.programId}/Exercises')
                        .add({
                      'hareketAdi': _hareketController.text,
                      'set': int.parse(_setController.text),
                      'tekrar': int.parse(_tekrarController.text),
                      'agirlik': int.parse(_agirlikController.text),
                      'donguKilo': int.parse(_donguController.text),
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // Metin alanlarını temizle
                    _hareketController.clear();
                    _setController.clear();
                    _tekrarController.clear();
                    _agirlikController.clear();
                    _donguController.clear();

                    // Dialog kapat
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Egzersiz başarıyla eklendi!")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Hata oluştu: $e")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Tüm alanları doldurun!")),
                  );
                }
              },
              child: Text(
                'Ekle',
                style: TextStyle(color: Colors.blueAccent), // Buton rengi yeşil
              ),
            ),
          ],
        );
      },
    );
  }
}
