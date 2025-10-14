import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';

class TemperatureChart extends StatefulWidget {
  final String deviceId;
  final bool isHumidity;

  const TemperatureChart({
    super.key,
    required this.deviceId,
    this.isHumidity = false,
  });

  @override
  State<TemperatureChart> createState() =>
      _TemperatureChartState();
}

class _TemperatureChartState
    extends State<TemperatureChart> {
  List<SensorData> data = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(
      Duration(seconds: 5),
      (_) => _fetchData(),
    );
  }

  Future<void> _fetchData() async {
    try {
      List<SensorData> result = widget.isHumidity
          ? await ApiService.fetchHumidityData(
              widget.deviceId,
            )
          : await ApiService.fetchTemperatureData(
              widget.deviceId,
            );
      setState(() {
        data = result.reversed.toList();
      });
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ✅ Tính giá trị min/max tự động
    final values = data.map((e) {
      return widget.isHumidity
          ? (e.humidity ?? 0)
          : (e.temperature ?? 0);
    }).toList();

    final minY =
        (values.reduce((a, b) => a < b ? a : b)) - 2;
    final maxY =
        (values.reduce((a, b) => a > b ? a : b)) + 2;

    return LineChart(
      LineChartData(
        minY: minY < 0 ? 0 : minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) {
                if (value.toInt() % 2 == 0 &&
                    value.toInt() < data.length) {
                  // ✅ Chỉ hiển thị phần thời gian HH:mm:ss
                  final time =
                      data[value.toInt()].timestamp;
                  final display = time.split(' ').length > 1
                      ? time.split(' ')[1]
                      : time;
                  return Text(
                    display,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              final index = e.key.toDouble();
              final value = widget.isHumidity
                  ? (e.value.humidity ?? 0)
                  : (e.value.temperature ?? 0);
              return FlSpot(index, value);
            }).toList(),
            isCurved: true,
            color: widget.isHumidity
                ? Colors.blue
                : Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: widget.isHumidity
                    ? [
                        Colors.blue.withOpacity(0.3),
                        Colors.transparent,
                      ]
                    : [
                        Colors.red.withOpacity(0.3),
                        Colors.transparent,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
