import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

class ActiveProgram extends StatefulWidget {
  final String programId;

  const ActiveProgram({Key? key, required this.programId}) : super(key: key);

  @override
  _ActiveProgramState createState() => _ActiveProgramState();
}

class _ActiveProgramState extends State<ActiveProgram> {
  int currentIndex = 0;
  List<DocumentSnapshot> exercises = [];

  void getExercises() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    String programId = widget.programId;

    DocumentSnapshot programSnapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs/')
        .doc(programId)
        .get();

    if (!programSnapshot.exists) {
      print('Program mevcut değil.');
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs/$programId/Exercises')
        .orderBy('timestamp')
        .get();

    setState(() {
      exercises = snapshot.docs.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    getExercises();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text('Çıkış yapmak istediğinize emin misiniz?',
                  style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child:
                      Text('Geri Dön', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Çıkış', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          leadingWidth: 80,
          leading: Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: Text('Çıkış yapmak istediğinize emin misiniz?',
                          style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Geri Dön',
                              style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pop(context);
                          },
                          child: Text('Çıkış',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                'Çıkış',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          title: Text(
            'Aktif Program',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: exercises.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${currentIndex + 1}/${exercises.length}',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10.0,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              exercises[currentIndex]['hareketAdi'],
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Set: ${exercises[currentIndex]['set']}',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            Text(
                              'Tekrar: ${exercises[currentIndex]['tekrar']}',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            Text(
                              'Ağırlık: ${exercises[currentIndex]['agirlik']}',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: TextButton(
                              onPressed: currentIndex == 0
                                  ? null
                                  : () {
                                      setState(() {
                                        currentIndex--;
                                      });
                                    },
                              child: Text(
                                'Geri',
                                style: TextStyle(
                                  color: currentIndex == 0
                                      ? Colors.grey[600]
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: TextButton(
                              onPressed: currentIndex == exercises.length - 1
                                  ? null
                                  : () {
                                      setState(() {
                                        currentIndex++;
                                      });
                                    },
                              child: Text(
                                'İleri',
                                style: TextStyle(
                                  color: currentIndex == exercises.length - 1
                                      ? Colors.grey[600]
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (currentIndex == exercises.length - 1)
                      Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            String programId = widget.programId;
                            await incrementCompletedCycle(programId);
                            LastProgram lastProgramInstance = LastProgram();
                            lastProgramInstance.lastProgram(programId);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Programı Bitir',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

Future<void> incrementCompletedCycle(String programId) async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    print("Kullanıcı kimliği bulunamadı.");
    return;
  }

  try {
    incrementCompletedCycles(programId);

    print("completedCycle değeri başarıyla artırıldı.");
  } catch (error) {
    print("completedCycle değeri artırılamadı: $error");
  }
}
