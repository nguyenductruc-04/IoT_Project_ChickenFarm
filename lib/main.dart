// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_detail_screen.dart';

void main() {
  runApp(const MyIoTApp());
}

class MyIoTApp extends StatelessWidget {
  const MyIoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Farm Monitor',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            const DashboardScreen(),
        DeviceDetailScreen
            .routeName: (context) =>
            const DeviceDetailScreen(),
      },
    );
  }
}
