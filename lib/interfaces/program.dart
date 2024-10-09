import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  @override
  Widget build(BuildContext context) {
    CollectionReference programRef =
        FirebaseFirestore.instance.collection('Users/User.1/Program');

    Future<void> addProgram() async {
      try {
        // Firestore'a veri ekliyoruz
        await programRef.add({
          'Agirlik': 72, // Eklenecek veriler
          'Tarih': DateTime.now(), // Eklenme tarihi
          // Diğer verileri buraya ekleyebilirsiniz
        });
        // Başarılı bir ekleme sonrası kullanıcıya mesaj göster
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Program başarıyla eklendi!'),
        ));
      } catch (e) {
        // Hata durumunda kullanıcıya mesaj göster
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Veri eklerken hata oluştu: $e'),
        ));
      }
    }

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Program Screen'),
              TextButton(
                  onPressed: () {
                    addProgram();
                  },
                  child: Text('Program Ekle+')),
            ],
          ),
        ),
      ),
    );
  }
}
