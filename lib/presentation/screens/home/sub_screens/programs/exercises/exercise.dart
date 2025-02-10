import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(CupertinoIcons.back, color: CupertinoColors.white),
        ),
        middle: FutureBuilder<String>(
          future: programAdi(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CupertinoActivityIndicator();
            } else if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}',
                  style: TextStyle(color: CupertinoColors.destructiveRed));
            } else if (snapshot.hasData) {
              return Text(
                snapshot.data ?? 'Program Adı Yok',
                style: TextStyle(
                  color: CupertinoColors.white,
                ),
              );
            } else {
              return Text('Program adı alınamadı');
            }
          },
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {},
          child: Stack(
            children: [
              isDataLoaded
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildCycleField(context, _completedCycle,
                                  'Tamamlanan', CupertinoColors.white),
                              Row(
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Icon(CupertinoIcons.pencil,
                                        color: CupertinoColors.white),
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
                                          'targetCycle':
                                              int.parse(newTargetCycle),
                                        });
                                        await _fetchCycles();
                                      }
                                    },
                                  ),
                                  buildCycleField(context, _targetCycle,
                                      'Hedef', CupertinoColors.white),
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
                                      style: TextStyle(
                                          color: CupertinoColors.white)),
                                );
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CupertinoActivityIndicator());
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                    child: Text('Egzersiz yok.',
                                        style: TextStyle(
                                            color: CupertinoColors.white)));
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
                  : Center(child: CupertinoActivityIndicator()),
              Positioned(
                right: 16,
                bottom: 80,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.activeBlue,
                  child: Icon(CupertinoIcons.add, color: CupertinoColors.black),
                  onPressed: showAddExerciseDialog,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SizedBox(
                  height: 50,
                  child: CupertinoButton.filled(
                    onPressed: () async {
                      Navigator.of(context).push(CupertinoPageRoute(
                          builder: (context) =>
                              ActiveProgram(programId: widget.programId)));
                      print("merhabaaaa");
                      setState(() {});
                      await _fetchCycles();
                    },
                    child: Text('Programı Başlat',
                        style: TextStyle(
                            fontSize: 20, color: CupertinoColors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showEditTargetCycleDialog() async {
    TextEditingController targetCycleController =
        TextEditingController(text: _targetCycle.toString());
    String? result;

    await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Hedef Döngü Düzenle'),
          content: CupertinoTextField(
            controller: targetCycleController,
            keyboardType: TextInputType.number,
            placeholder: 'Yeni Hedef Döngü',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
              isDestructiveAction: true,
            ),
            CupertinoDialogAction(
              onPressed: () {
                result = targetCycleController.text;
                Navigator.of(context).pop();
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Widget buildExerciseCard(BuildContext context, DocumentSnapshot exercise) {
    final TextEditingController _donguKiloController = TextEditingController();
    final donguKilo = exercise['donguKilo'] ?? 0;

    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.darkBackgroundGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hareket: ${exercise['hareketAdi']}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child:
                      Icon(CupertinoIcons.pencil, color: CupertinoColors.white),
                  onPressed: () {
                    _editExercise(context, exercise);
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child:
                      Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                  onPressed: () => _showDeleteConfirmation(context, exercise),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                buildEditableField(context, exercise, exercise.id, 'set',
                    CupertinoColors.systemGrey),
                SizedBox(width: 5),
                Text('x',
                    style:
                        TextStyle(color: CupertinoColors.white, fontSize: 30)),
                SizedBox(width: 10),
                buildEditableField(context, exercise, exercise.id, 'tekrar',
                    CupertinoColors.systemGrey),
                SizedBox(width: 10),
                buildEditableField(context, exercise, exercise.id, 'agirlik',
                    CupertinoColors.white),
                SizedBox(width: 10),
                Text('kg',
                    style:
                        TextStyle(color: CupertinoColors.white, fontSize: 30)),
                SizedBox(width: 10),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.loop,
                      color: CupertinoColors.systemGrey,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      width: 50,
                      child: CupertinoTextField(
                        controller: _donguKiloController,
                        style: TextStyle(
                            color: CupertinoColors.white, fontSize: 30),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        placeholder: donguKilo.toString(),
                        placeholderStyle: TextStyle(
                            color: CupertinoColors.systemGrey, fontSize: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSubmitted: (value) async {
                          if (value.isNotEmpty) {
                            await exercise.reference.update({
                              'donguKilo': int.parse(_donguKiloController.text),
                            });
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
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
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: CupertinoTextField(
          textAlign: TextAlign.center,
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 30, color: color),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          onSubmitted: (updatedValue) async {
            if (updatedValue.isNotEmpty) {
              try {
                await exercise.reference
                    .update({field: int.parse(updatedValue)});
                setState(() {});
              } catch (e) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text("Hata"),
                    content: Text("Güncelleme hatası: $e"),
                    actions: [
                      CupertinoDialogAction(
                        child: Text("Tamam"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            } else {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text("Hata"),
                  content: Text("Boş bir değer gönderilemez!"),
                  actions: [
                    CupertinoDialogAction(
                      child: Text("Tamam"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            }
          },
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
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Silmek istediğinize emin misiniz?'),
          content: Text('Bu egzersizi silmek için onaylayın.'),
          actions: [
            CupertinoDialogAction(
              child: Text('İptal'),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
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

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Egzersizi Düzenle'),
          content: Container(
            height: 300,
            child: Column(
              children: [
                CupertinoTextField(
                  controller: hareketController,
                  placeholder: 'Hareket Adı',
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: setController,
                  placeholder: 'Set',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: tekrarController,
                  placeholder: 'Tekrar',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: agirlikController,
                  placeholder: 'Ağırlık',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: donguKiloController,
                  placeholder: 'Döngü Kilo',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            CupertinoDialogAction(
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

                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text("Başarılı"),
                      content: Text("Egzersiz başarıyla güncellendi!"),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("Tamam"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text("Hata"),
                      content: Text("Güncelleme hatası: $e"),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("Tamam"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void showAddExerciseDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Egzersiz Ekle'),
          content: Container(
            height: 300,
            child: Column(
              children: [
                CupertinoTextField(
                  controller: _hareketController,
                  placeholder: 'Hareket Adı',
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: _setController,
                  placeholder: 'Set',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: _tekrarController,
                  placeholder: 'Tekrar',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: _agirlikController,
                  placeholder: 'Ağırlık',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: _donguController,
                  placeholder: 'Döngü Kilo',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            CupertinoDialogAction(
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

                    _hareketController.clear();
                    _setController.clear();
                    _tekrarController.clear();
                    _agirlikController.clear();
                    _donguController.clear();

                    Navigator.of(context).pop();

                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("Başarılı"),
                        content: Text("Egzersiz başarıyla eklendi!"),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("Tamam"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("Hata"),
                        content: Text("Hata oluştu: $e"),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("Tamam"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text("Hata"),
                      content: Text("Tüm alanları doldurun!"),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("Tamam"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
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
