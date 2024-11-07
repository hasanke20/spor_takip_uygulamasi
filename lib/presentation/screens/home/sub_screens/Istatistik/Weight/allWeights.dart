import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

class AllWeights extends StatefulWidget {
  const AllWeights({super.key});

  @override
  State<AllWeights> createState() => _AllWeightsState();
}

class _AllWeightsState extends State<AllWeights> {
  late List<WeightData> _weightDataList = []; // Kilo verilerini tutan liste

  @override
  void initState() {
    super.initState();
    _fetchAllWeights();
  }

  Future<void> _fetchAllWeights() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Weight')
          .orderBy('timestamp',
              descending: true) // En yeni ölçümü en üstte gösterir
          .get();

      List<WeightData> allData = snapshot.docs.map((doc) {
        double weight = doc['weight'];
        DateTime timestamp = (doc['timestamp'] as Timestamp)
            .toDate(); // Timestamp'i DateTime'a çevir
        return WeightData(weight, timestamp, doc.id); // Belge ID'sini ekleyin
      }).toList();

      setState(() {
        _weightDataList = allData;
      });
    } catch (e) {
      print("Veri çekerken hata: $e");
    }
  }

  Future<void> _deleteAllWeights() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      // Tüm kilo verilerini sil
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Weight')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete(); // Belgeyi sil
      }

      _fetchAllWeights(); // Listeyi güncelle
    } catch (e) {
      print("Veri silerken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title:
              const Text('Tüm Ölçümler', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.red,
              ),
              child: TextButton(
                onPressed: _showDeleteConfirmationDialog,
                child: const Text('Hepsini Sil',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        body: _weightDataList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _weightDataList.length,
                itemBuilder: (context, index) {
                  final weightData = _weightDataList[index];
                  double initialWeight =
                      _weightDataList.last.weight; // İlk veriyi al
                  double previousWeight = index < _weightDataList.length - 1
                      ? _weightDataList[index + 1].weight
                      : weightData.weight; // Önceki kilo verisi
                  double previousChange = weightData.weight -
                      previousWeight; // Öncekiyle değişimi hesapla
                  double totalChange = weightData.weight -
                      initialWeight; // Toplam değişimi hesapla

                  return _buildWeightCard(
                      weightData, previousChange, totalChange, index);
                },
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueAccent,
          onPressed: showWeightDialog, // Kilo ekleme diyalogunu göster
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildWeightCard(WeightData weightData, double previousChange,
      double totalChange, int index) {
    bool isFirstItem = index == 0;
    Color cardColor = isFirstItem ? Colors.grey.shade700 : Colors.grey.shade900;

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeightHeader(weightData, index),
            _buildWeightDetails(weightData, previousChange, totalChange),
            Text(
              'Kaydedilme Tarihi: ${DateFormat('dd/MM/yyyy').format(weightData.timestamp)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildWeightHeader(WeightData weightData, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ölçüm No: ${_weightDataList.length - index}',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _showEditWeightDialog(weightData),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () =>
                  _onDeleteWeight(weightData.id), // ID'yi burada kullan
            ),
          ],
        ),
      ],
    );
  }

  Row _buildWeightDetails(
      WeightData weightData, double previousChange, double totalChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildWeightColumn('Kilo:', '${weightData.weight} kg'),
        _buildChangeColumn('Öncekiyle Değişim:', previousChange),
        _buildChangeColumn('Toplam Değişim:', totalChange),
      ],
    );
  }

  Column _buildWeightColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24)),
      ],
    );
  }

  Column _buildChangeColumn(String label, double change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(
          (change >= 0 ? '+' : '') + '${change.toStringAsFixed(1)} kg',
          style: TextStyle(
              color: change >= 0 ? Colors.green : Colors.red, fontSize: 24),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Tüm Ölçümleri Sil',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Bu işlemi onaylıyor musunuz? Tüm ölçümler silinecektir!',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // İptal için dialogu kapat
              child: const Text('İptal',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () async {
                await _deleteAllWeights();
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditWeightDialog(WeightData weightData) {
    final TextEditingController weightController =
        TextEditingController(text: weightData.weight.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Düzenle', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Yeni Kilo',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // İptal için dialogu kapat
              child: const Text('İptal',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () async {
                double? newWeight = double.tryParse(weightController.text);
                if (newWeight != null) {
                  await AddWeight.editWeight(context, weightData.id, newWeight);
                  _fetchAllWeights(); // Verileri yeniden yükle
                  Navigator.of(context).pop(); // Dialogu kapat
                }
              },
              child:
                  const Text('Güncelle', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _onDeleteWeight(String id) async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Users/$uid/Weight')
          .doc(id)
          .delete();

      _fetchAllWeights();
    } catch (e) {
      print("Ölçüm silinirken hata: $e");
    }
  }

  void showWeightDialog() {
    final TextEditingController weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Kilo Ekle', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Kilo',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                double? weight = double.tryParse(weightController.text);
                if (weight != null) {
                  await AddWeight.addWeight(context, weight);
                  _fetchAllWeights();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ekle',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }
}

class WeightData {
  final double weight;
  final DateTime timestamp;
  final String id; // Belge ID'sini ekleyin

  WeightData(this.weight, this.timestamp, this.id);
}
