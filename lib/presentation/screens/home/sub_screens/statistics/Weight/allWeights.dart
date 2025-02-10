import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:spor_takip_uygulamasi/repository/addToFirebase.dart';

class AllWeights extends StatefulWidget {
  const AllWeights({super.key});

  @override
  State<AllWeights> createState() => _AllWeightsState();
}

class _AllWeightsState extends State<AllWeights> {
  late List<WeightData> _weightDataList = [];

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
          .orderBy('timestamp', descending: true)
          .get();

      List<WeightData> allData = snapshot.docs.map((doc) {
        double weight = doc['weight'];
        DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
        return WeightData(weight, timestamp, doc.id);
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
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Weight')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _fetchAllWeights();
    } catch (e) {
      print("Veri silerken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        middle: const Text('Tüm Ölçümler',
            style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: CupertinoColors.destructiveRed,
          ),
          child: CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 10),
            onPressed: _showDeleteConfirmationDialog,
            child: const Text('Hepsini Sil',
                style: TextStyle(color: CupertinoColors.white)),
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _weightDataList.isEmpty
                ? const Center(child: CupertinoActivityIndicator())
                : ListView.builder(
                    itemCount: _weightDataList.length,
                    itemBuilder: (context, index) {
                      final weightData = _weightDataList[index];
                      double initialWeight = _weightDataList.last.weight;
                      double previousWeight = index < _weightDataList.length - 1
                          ? _weightDataList[index + 1].weight
                          : weightData.weight;
                      double previousChange =
                          weightData.weight - previousWeight;
                      double totalChange = weightData.weight - initialWeight;

                      return _buildWeightCard(
                          weightData, previousChange, totalChange, index);
                    },
                  ),
            Positioned(
              right: 16,
              bottom: 16,
              child: CupertinoButton(
                color: CupertinoColors.activeBlue,
                padding: EdgeInsets.all(15),
                onPressed: showWeightDialog,
                child: const Icon(CupertinoIcons.add,
                    color: CupertinoColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(WeightData weightData, double previousChange,
      double totalChange, int index) {
    bool isFirstItem = index == 0;
    Color cardColor = isFirstItem
        ? CupertinoColors.systemGrey.withOpacity(0.7)
        : CupertinoColors.systemGrey.withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.0),
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
              style: const TextStyle(
                  color: CupertinoColors.systemGrey, fontSize: 12),
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
              color: CupertinoColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil,
                  color: CupertinoColors.white),
              onPressed: () => _showEditWeightDialog(weightData),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.delete,
                  color: CupertinoColors.white),
              onPressed: () => _onDeleteWeight(weightData.id),
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
        Text(label,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 16)),
        Text(value,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 24)),
      ],
    );
  }

  Column _buildChangeColumn(String label, double change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 16)),
        Text(
          (change >= 0 ? '+' : '') + '${change.toStringAsFixed(1)} kg',
          style: TextStyle(
              color: change >= 0
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.destructiveRed,
              fontSize: 24),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Tüm Ölçümleri Sil'),
          content: const Text(
              'Bu işlemi onaylıyor musunuz? Tüm ölçümler silinecektir!'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                await _deleteAllWeights();
                Navigator.of(context).pop();
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showEditWeightDialog(WeightData weightData) {
    final TextEditingController weightController =
        TextEditingController(text: weightData.weight.toString());

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Düzenle'),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CupertinoTextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'Yeni Kilo',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                double? newWeight = double.tryParse(weightController.text);
                if (newWeight != null) {
                  await AddWeight.editWeight(context, weightData.id, newWeight);
                  _fetchAllWeights();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Güncelle'),
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

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Kilo Ekle'),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CupertinoTextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: 'Kilo',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                double? weight = double.tryParse(weightController.text);
                if (weight != null) {
                  await AddWeight.addWeight(context, weight);
                  _fetchAllWeights();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ekle'),
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
  final String id;

  WeightData(this.weight, this.timestamp, this.id);
}
