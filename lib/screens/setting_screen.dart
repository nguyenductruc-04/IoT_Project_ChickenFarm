import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  BluetoothCharacteristic? targetCharacteristic;

  bool isScanning = false;
  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // cho Android <12
    ].request();
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) async {
      // kiểm tra adapter state trước khi quét
      var state = await FlutterBluePlus.adapterState.first;
      debugPrint("Bluetooth adapter state: $state");
    });
  }

  // Quét thiết bị
  Future<void> startScan() async {
    await _checkPermissions();

    setState(() => isScanning = true);
    scanResults.clear();

    // GỌI STATIC METHOD TRỰC TIẾP TỪ CLASS
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    // Lắng nghe kết quả
    FlutterBluePlus.scanResults
        .listen((results) {
          setState(() => scanResults = results);
        })
        .onDone(() {
          setState(() => isScanning = false);
        });
  }

  // Kết nối tới thiết bị
  Future<void> connectToDevice(
    BluetoothDevice device,
  ) async {
    await device.connect();
    setState(() => connectedDevice = device);
    services = await device.discoverServices();

    // Tìm characteristic có quyền đọc/ghi
    for (var service in services) {
      for (var c in service.characteristics) {
        if (c.properties.read && c.properties.write) {
          targetCharacteristic = c;
        }
      }
    }
  }

  // Đọc dữ liệu
  Future<void> readData() async {
    if (targetCharacteristic == null) return;
    final value = await targetCharacteristic!.read();
    final data = String.fromCharCodes(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dữ liệu đọc: $data')),
    );
  }

  // Ghi dữ liệu
  Future<void> writeData(String msg) async {
    if (targetCharacteristic == null) return;
    await targetCharacteristic!.write(
      msg.codeUnits,
      withoutResponse: false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi dữ liệu')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt BLE')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isScanning ? null : startScan,
              child: Text(
                isScanning
                    ? 'Đang quét...'
                    : 'Quét thiết bị',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final r = scanResults[index];
                  return ListTile(
                    title: Text(
                      r.device.name.isNotEmpty
                          ? r.device.name
                          : r.device.id.toString(),
                    ),
                    subtitle: Text(r.device.id.toString()),
                    onTap: () => connectToDevice(r.device),
                  );
                },
              ),
            ),
            if (connectedDevice != null)
              Column(
                children: [
                  Text(
                    'Đã kết nối: ${connectedDevice!.name}',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: readData,
                    child: const Text('Đọc dữ liệu'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        writeData('Hello ESP32'),
                    child: const Text('Gửi dữ liệu'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
