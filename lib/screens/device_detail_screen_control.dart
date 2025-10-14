// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:iot_app/mqtt/mqtt.dart';

class DetailControlArgs {
  final String title;
  final bool status;
  final String description;
  final IconData icon;
  final MqttService mqttService;
  final String topic;

  DetailControlArgs({
    required this.title,
    required this.status,
    required this.description,
    required this.icon,
    required this.mqttService,
    required this.topic,
  });
}

class DeviceDetailScreenControl extends StatefulWidget {
  static const String routeName = '/device-control-detail';
  const DeviceDetailScreenControl({super.key});

  @override
  State<DeviceDetailScreenControl> createState() =>
      _DeviceDetailScreenControlState();
}

class _DeviceDetailScreenControlState
    extends State<DeviceDetailScreenControl> {
  int? selectedThreshold; // lưu ngưỡng nhiệt độ

  // Hàm chọn số (Picker)
  void showPickerNumber(
    BuildContext context,
    DetailControlArgs args,
  ) {
    Picker(
      adapter: NumberPickerAdapter(
        data: [
          NumberPickerColumn(
            begin: 0,
            end: 50,
            suffix: Text(" °C"), // nhập nhiệt độ
          ),
        ],
      ),
      hideHeader: true,
      title: Text("Chọn ngưỡng nhiệt độ để bật đèn sưởi"),
      selectedTextStyle: TextStyle(
        color: Colors.blue,
        fontSize: 18,
      ),
      onConfirm: (Picker picker, List value) {
        final selected = picker.getSelectedValues()[0];
        setState(() {
          selectedThreshold = selected;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ngưỡng nhiệt đo: $selected °C"),
          ),
        );

        // TODO: Gửi ngưỡng này qua MQTT tới ESP32
        args.mqttService.pickerNumber(
          selectedThreshold.toString(),
          args.topic,
        );
      },
    ).showDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final DetailControlArgs args =
        ModalRoute.of(context)!.settings.arguments
            as DetailControlArgs;

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(args.icon, size: 28),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge,
                    ),
                    SizedBox(height: 4),
                    Text(
                      args.status ? "Bật" : "Tắt",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(args.description),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 12),
            Text("Chọn ngưỡng nhiệt độ bật đèn sưởi"),
            Center(
              child: Column(
                children: [
                  if (selectedThreshold != null)
                    Text(
                      "Ngưỡng nhiệt độ bật đèn sưởi: $selectedThreshold °C",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        showPickerNumber(context, args),
                    child: Text("Chọn lại"),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
