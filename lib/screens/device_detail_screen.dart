// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';

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

class DeviceDetailScreen extends StatelessWidget {
  static const String routeName = '/device-detail';
  const DeviceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DetailArgs args =
        ModalRoute.of(context)!.settings.arguments as DetailArgs;

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 28, child: Icon(args.icon, size: 28)),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 4),
                    Text(
                      args.value,
                      style: Theme.of(context).textTheme.headlineSmall,
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
            Text('Gợi ý', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text(
              '- Đặt ngưỡng cảnh báo phù hợp với môi trường.'
              '- Hiệu chuẩn cảm biến định kỳ.'
              '- Kiểm tra kết nối mạng để cập nhật dữ liệu theo thời gian thực.',
            ),
          ],
        ),
      ),
    );
  }
}
