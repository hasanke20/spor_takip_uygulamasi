import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addWeight(double weight) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore.collection('Users/$uid/Weight').add({
      'weight': weight,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editWeight(String id, double weight) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore.collection('Users/$uid/Weight').doc(id).update({
      'weight': weight,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLastProgram(String programId) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _firestore.collection('Users/$uid/Values').doc('LastProgram').set({
      'programId': programId,
    });
  }

  Future<void> fetchPrograms(
      BuildContext context,
      List<Map<String, dynamic>> programs,
      String lastProgramName,
      String nextProgramName) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lütfen giriş yapın.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      QuerySnapshot programSnapshot = await _firestore
          .collection('Users/$uid/Programs')
          .orderBy('timestamp')
          .get();

      programs.clear(); // Clear the list before adding new programs
      programs.addAll(programSnapshot.docs.map((doc) {
        return {
          'programId': doc.id,
          'programAdi': doc['programAdi'],
          'timestamp': doc['timestamp'] as Timestamp,
        };
      }).toList());

      await fetchNextProgram(uid, programs, lastProgramName, nextProgramName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Veri çekme hatası: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> fetchNextProgram(String uid, List<Map<String, dynamic>> programs,
      String lastProgramName, String nextProgramName) async {
    DocumentSnapshot lastProgramSnapshot = await FirebaseFirestore.instance
        .collection('Users/$uid/Values')
        .doc('LastProgram')
        .get();

    if (!lastProgramSnapshot.exists) {
      lastProgramName = 'Program Yok';
      nextProgramName = 'Program Yok';
      return;
    }

    String? lastProgramId = lastProgramSnapshot['programId'];
    DocumentSnapshot lastProgramDoc = await FirebaseFirestore.instance
        .collection('Users/$uid/Programs')
        .doc(lastProgramId)
        .get();

    lastProgramName =
        lastProgramDoc.exists ? lastProgramDoc['programAdi'] : 'Program Yok';

    // Programları sıralayın
    programs.sort((a, b) =>
        (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

    // Son yapılan programın indeksini bul
    int lastProgramIndex =
        programs.indexWhere((program) => program['programId'] == lastProgramId);

    if (lastProgramIndex != -1) {
      // Son program son eleman ise, sıradaki program listenin başındaki program
      if (lastProgramIndex == programs.length - 1) {
        nextProgramName = programs[0]['programAdi'];
      } else {
        nextProgramName = programs[lastProgramIndex + 1]['programAdi'];
      }
    } else {
      nextProgramName = 'Program Yok';
    }

    // setState(() {});
  }
}
