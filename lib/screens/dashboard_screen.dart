// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/device_card.dart';
import 'device_detail_screen.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock sensor values. Replace with your real data sources (MQTT/HTTP/BLE).
  double temperatureC = 0;
  double humidity = 0;
  double waterLevel = 0; // percent
  double feedLevel = 0; // percent
  bool motorOn = false;

  late MqttServerClient client;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _connectMQTT();
  }

  Future<int> _connectMQTT() async {
    const awsEndpoint =
        'a2wcwnaa9j6foi-ats.iot.us-east-1.amazonaws.com';
    const port = 8883;
    const clientId = 'Flutter-client';

    client = MqttServerClient.withPort(
      awsEndpoint,
      clientId,
      port,
    );
    client.secure = true;
    client.keepAlivePeriod = 20;
    client.setProtocolV311();
    client.logging(on: true);

    // Load cert từ assets
    ByteData rootCA = await rootBundle.load(
      'assets/certs/AmazonRootCA1.pem',
    );
    ByteData deviceCert = await rootBundle.load(
      'assets/certs/certificate.pem.crt',
    );
    ByteData privateKey = await rootBundle.load(
      'assets/certs/private.pem.key',
    );

    SecurityContext context =
        SecurityContext.defaultContext;
    context.setClientAuthoritiesBytes(
      rootCA.buffer.asInt8List(),
    );
    context.useCertificateChainBytes(
      deviceCert.buffer.asInt8List(),
    );
    context.usePrivateKeyBytes(
      privateKey.buffer.asInt8List(),
    );

    client.securityContext = context;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    client.connectionMessage = connMess;

    try {
      print("🔌 Đang kết nối tới MQTT...");
      await client.connect();
    } on Exception catch (e) {
      print("❌ Lỗi kết nối: $e");
      client.disconnect();
      return -1;
    }

    if (client.connectionStatus!.state ==
        MqttConnectionState.connected) {
      print('✅ MQTT client connected to AWS IoT');

      const topic = 'esp32/esp32-to-aws';
      client.subscribe(topic, MqttQos.atLeastOnce);

      client.updates!.listen((
        List<MqttReceivedMessage<MqttMessage>> c,
      ) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message,
            );

        print(
          '📩 Nhận dữ liệu từ topic <${c[0].topic}>: $payload',
        );

        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) {
            final temp = (data['data'] as num).toDouble();
            setState(() {
              temperatureC = temp;
            });
            print(
              '🌡️ Nhiệt độ cập nhật: $temperatureC °C',
            );
          }
        } catch (e) {
          print('❌ Lỗi parse payload: $e');
        }
      });
    } else {
      print(
        'ERROR MQTT client connection failed - state: ${client.connectionStatus!.state}',
      );
      client.disconnect();
    }

    return 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleMotor(bool value) async {
    // TODO: integrate with your backend to switch the motor.
    // For example:
    // await http.post(Uri.parse('http://your-esp32/motor'), body: {'on': value.toString()});
    setState(() => motorOn = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Motor đã ${motorOn ? "BẬT" : "TẮT"}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giám sát môi trường',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12),
            Expanded(
              child: GridView(
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(
                                context,
                              ).size.width >
                              900
                          ? 4
                          : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                children: [
                  DeviceCard(
                    title: 'Nhiệt độ',
                    value:
                        '${temperatureC.toStringAsFixed(1)} °C',
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreen.routeName,
                        arguments: DetailArgs(
                          title: 'Nhiệt độ',
                          value:
                              '${temperatureC.toStringAsFixed(1)} °C',
                          description:
                              'Nhiệt độ hiện tại đo bởi cảm biến.',
                          icon: Icons.thermostat,
                        ),
                      );
                    },
                  ),
                  DeviceCard(
                    title: 'Độ ẩm',
                    value: humidity.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.water_drop,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreen.routeName,
                        arguments: DetailArgs(
                          title: 'Độ ẩm',
                          value:
                              '${humidity.toStringAsFixed(0)} %',
                          description:
                              'Độ ẩm không khí từ cảm biến.',
                          icon: Icons.water_drop,
                        ),
                      );
                    },
                  ),
                  DeviceCard(
                    title: 'Mực nước',
                    value: waterLevel.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.waves,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreen.routeName,
                        arguments: DetailArgs(
                          title: 'Mực nước',
                          value:
                              '${waterLevel.toStringAsFixed(0)} %',
                          description:
                              'Mực nước trong bể/ao hiện tại.',
                          icon: Icons.waves,
                        ),
                      );
                    },
                  ),
                  DeviceCard(
                    title: 'Mức thức ăn',
                    value: feedLevel.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.inventory,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreen.routeName,
                        arguments: DetailArgs(
                          title: 'Mức thức ăn',
                          value:
                              '${feedLevel.toStringAsFixed(0)} %',
                          description:
                              'Dung lượng thức ăn còn lại trong khoang.',
                          icon: Icons.inventory,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.power_settings_new),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Mô tơ'),
                          Text(
                            motorOn
                                ? 'Đang BẬT'
                                : 'Đang TẮT',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: motorOn
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: motorOn,
                      onChanged: _toggleMotor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
