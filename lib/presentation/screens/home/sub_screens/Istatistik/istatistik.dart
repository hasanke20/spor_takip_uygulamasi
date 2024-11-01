import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spor_takip_uygulamasi/presentation/screens/home/sub_screens/Istatistik/Weight/allWeights.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class IstatisticScreen extends StatefulWidget {
  const IstatisticScreen({super.key});

  @override
  State<IstatisticScreen> createState() => _IstatisticScreenState();
}

class _IstatisticScreenState extends State<IstatisticScreen> {
  late List<ChartData> _chartData;
  double? _minYValue;
  double? _maxYValue;
  List<double> _lastTwoWeights = [];
  double? _initialWeight; // Firebase'den alınan ilk kilo değeri

  @override
  void initState() {
    super.initState();
    _chartData = [];
    _fetchWeightData();
  }

  Future<void> _fetchWeightData() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users/$uid/Weight')
          .orderBy('timestamp', descending: false)
          .get();

      List<ChartData> allData = [];
      for (var doc in snapshot.docs) {
        double weight = doc['weight'];
        allData.add(ChartData('', weight));
      }

      List<ChartData> lastEightData =
          allData.length > 8 ? allData.sublist(allData.length - 8) : allData;

      if (lastEightData.isNotEmpty) {
        double minWeight = lastEightData
            .map((data) => data.weight)
            .reduce((a, b) => a < b ? a : b);
        double maxWeight = lastEightData
            .map((data) => data.weight)
            .reduce((a, b) => a > b ? a : b);

        setState(() {
          _chartData = lastEightData.asMap().entries.map((entry) {
            int index = allData.length - lastEightData.length + entry.key + 1;
            ChartData data = entry.value;
            return ChartData('$index. Ölçüm', data.weight);
          }).toList();

          _minYValue = minWeight - 5;
          _maxYValue = maxWeight + 5;

          // Son iki ölçümü al
          if (allData.isNotEmpty) {
            _lastTwoWeights = allData.map((data) => data.weight).toList();
            if (_lastTwoWeights.length > 2) {
              _lastTwoWeights =
                  _lastTwoWeights.sublist(_lastTwoWeights.length - 2);
            }

            // Firebase'den alınan ilk kilo değeri
            _initialWeight = allData.first.weight; // İlk ölçüm
          }
        });
      }
    } catch (e) {
      print("Veri çekerken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double? latestWeight =
        _lastTwoWeights.length > 0 ? _lastTwoWeights.last : null;
    double? previousWeight = _lastTwoWeights.length > 1
        ? _lastTwoWeights[_lastTwoWeights.length - 2]
        : null;

    double? changeFromInitial = (latestWeight != null && _initialWeight != null)
        ? (latestWeight - _initialWeight!)
        : null;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 4,
                      child: SfCartesianChart(
                        title: ChartTitle(
                          text: 'Kilo Takibi',
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        legend: Legend(
                          isVisible: false,
                          textStyle: TextStyle(color: Colors.white),
                        ),
                        primaryXAxis: CategoryAxis(
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        primaryYAxis: NumericAxis(
                          minimum: _minYValue,
                          maximum: _maxYValue,
                          labelFormat: '{value} kg',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        series: <LineSeries<ChartData, String>>[
                          LineSeries<ChartData, String>(
                            dataSource: _chartData,
                            xValueMapper: (ChartData data, _) => data.week,
                            yValueMapper: (ChartData data, _) => data.weight,
                            name: 'Kilo',
                            color: Colors.blue,
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Card(
                          color: Colors.grey.shade700,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Son Ölçüm',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        latestWeight != null
                                            ? '$latestWeight kg'
                                            : 'Veri yok',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Toplam Değişim',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        changeFromInitial != null
                                            ? '${changeFromInitial >= 0 ? '+' : ''}${changeFromInitial.toStringAsFixed(1)} kg'
                                            : 'Veri yok',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: TextButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.grey.shade700),
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                ),
                                onPressed: () {
                                  Get.to(AllWeights());
                                },
                                child: Text('Tümünü Gör'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.week, this.weight);
  final String week;
  final double weight;
}
