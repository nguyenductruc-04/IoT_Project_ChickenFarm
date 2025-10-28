// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

class DetailArgs {
  final String title;
  final String value;
  final String description;
  final IconData icon;

  DetailArgs({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
  });
}

class DeviceDetailScreen extends StatefulWidget {
  static const String routeName = '/device-detail';
  const DeviceDetailScreen({super.key});

  @override
  State<DeviceDetailScreen> createState() =>
      _DeviceDetailScreenState();
}

class _DeviceDetailScreenState
    extends State<DeviceDetailScreen> {
  int? selectedThreshold; // lưu ngưỡng nhiệt độ

  @override
  Widget build(BuildContext context) {
    final DetailArgs args =
        ModalRoute.of(context)!.settings.arguments
            as DetailArgs;

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
                      args.value,
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
