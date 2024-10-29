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
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _hareketController.dispose();
    _setController.dispose();
    _tekrarController.dispose();
    _agirlikController.dispose();
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          // FocusScope.of(context).unfocus();
        },
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
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              buildCycleController(context),
                              buildExerciseCard(context, exercise),
                            ],
                          );
                        } else {
                          return buildExerciseCard(context, exercise);
                        }
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

  Widget buildCycleController(BuildContext context) {
    return Row(children: [
      SizedBox(width: MediaQuery.of(context).size.width * 0.05),
      Flexible(
        flex: 1,
        child: Container(
            decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: TextField(
              keyboardType: TextInputType.number,
            )),
      ),
      Flexible(
        flex: 1,
        child: Container(
            decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: TextField(keyboardType: TextInputType.number)),
      ),
      Flexible(
        flex: 1,
        child: FilledButton.tonal(
            onPressed: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text("Arttir"),
            )),
      ),
      SizedBox(width: MediaQuery.of(context).size.width * 0.05)
    ]);
  }

  Widget buildExerciseCard(BuildContext context, DocumentSnapshot exercise) {
    final String exerciseId = exercise.id;

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
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: () async {
                await _confirmDelete(context, exercise);
              },
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildEditableField(
                context, exercise, exerciseId, 'set', Colors.grey.shade400),
            SizedBox(width: 5),
            Text('x', style: TextStyle(color: Colors.white, fontSize: 30)),
            SizedBox(width: 10),
            buildEditableField(
                context, exercise, exerciseId, 'tekrar', Colors.grey.shade400),
            SizedBox(width: 10),
            buildEditableField(
                context, exercise, exerciseId, 'agirlik', Colors.white),
            SizedBox(width: 10),
            Text('KG', style: TextStyle(color: Colors.white, fontSize: 30)),
            Spacer()
          ],
        ),
      ),
    );
  }

  Widget buildEditableField(
    BuildContext context,
    DocumentSnapshot exercise,
    String exerciseId,
    String field,
    Color color,
  ) {
    if (!controllers.containsKey(exerciseId + field)) {
      controllers[exerciseId + field] =
          TextEditingController(text: exercise[field].toString());
    }

    final text = controllers[exerciseId + field]!.text;
    final textStyle = TextStyle(fontSize: 30, color: color);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final FocusNode nodefocus = FocusNode();
    return Flexible(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.all(Radius.circular(20))),
        // width: textPainter.width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: TextField(
            textAlign: TextAlign.center,
            controller: controllers[exerciseId + field],
            keyboardType: TextInputType.number,
            style: textStyle,
            focusNode: nodefocus,
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
            // onChanged: (updatedValue) {
            //   if (field == 'set' || field == 'tekrar') {
            //     if (updatedValue.length > 2) {
            //       controllers[exerciseId + field]!.text =
            //           updatedValue.substring(0, 2);
            //       controllers[exerciseId + field]!.selection =
            //           TextSelection.fromPosition(TextPosition(offset: 2));
            //     }
            //   } else if (field == 'agirlik') {
            //     if (updatedValue.length > 4) {
            //       controllers[exerciseId + field]!.text =
            //           updatedValue.substring(0, 4);
            //       controllers[exerciseId + field]!.selection =
            //           TextSelection.fromPosition(TextPosition(offset: 4));
            //     }
            //   }
            // },
            onSubmitted: (updatedValue) async {
              if (updatedValue.isNotEmpty) {
                await exercise.reference.update({field: updatedValue});
              }
              nodefocus.unfocus();
            },
            // onEditingComplete: () async {
            //   final updatedValue = controllers[exerciseId + field]!.text;
            //   if (updatedValue.isNotEmpty) {
            //     await exercise.reference.update({field: updatedValue});
            //   }
            // },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, DocumentSnapshot exercise) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Text(
            'Bu egzersizi silmek istediğinize emin misiniz?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hayır',
                  style: TextStyle(fontSize: 16, color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Evet',
                  style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await AddExercise.deleteExercise(context, exercise);
    }
  }

  void showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text('Egzersiz Ekle', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                buildTextField('Hareket Adı', _hareketController),
                buildTextField('Set', _setController),
                buildTextField('Tekrar', _tekrarController),
                buildTextField('Ağırlık', _agirlikController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearTextFields();
              },
              child: Text('İptal', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                await AddExercise.addExercise(
                  context,
                  uid!,
                  widget.programId,
                  hareketAdi: _hareketController.text,
                  set: _setController.text,
                  tekrar: _tekrarController.text,
                  agirlik: _agirlikController.text,
                );
                Navigator.of(context).pop();
                clearTextFields();
              },
              child: Text('Ekle', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  TextField buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
      ),
      keyboardType: TextInputType.number,
    );
  }

  void clearTextFields() {
    _hareketController.clear();
    _setController.clear();
    _tekrarController.clear();
    _agirlikController.clear();
  }
}
