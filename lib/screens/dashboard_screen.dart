// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iot_app/mqtt/mqtt.dart';
import '../widgets/device_card_sensor.dart';
import '../widgets/device_card_control.dart';
import 'device_detail_screen_monitor.dart';
import 'device_detail_screen_control.dart';
import 'dashboard_drawer.dart';
import '../widgets/temperature_chart.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double temperatureC = 0;
  double humidity = 0;
  String waterLevel = "Thấp";
  double loadcell = 0;

  bool statusLed = false;
  bool statusFan = false;
  bool statusMotor = false;
  bool statusPump = false;

  bool statusRealLed = false;
  bool statusRealFan = false;
  bool statusRealMotor = false;
  bool statusRealPump = false;

  int? updateselectedThresholdLed;
  int? updateselectedThresholdFan;
  late Future<List<SensorData>> _futureData;
  late MqttService mqttService;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () {
      mqttService.requestRelay();
    });
    _futureData = ApiService.fetchTemperatureData(
      'esp32_01',
    );
    mqttService = MqttService(
      awsEndpoint:
          'a2wcwnaa9j6foi-ats.iot.us-east-1.amazonaws.com',
      clientId: 'Flutter-client',
      port: 8883,
      onSensorUpdate: (temp, hum, level, cell) {
        setState(() {
          temperatureC = temp;
          humidity = hum;
          waterLevel = level.toString();
          loadcell = cell;
        });
      },
    );
    mqttService.onRelayUpdate = (topic, status) {
      print("📩 Relay update from $topic => $status");
      setState(() {
        if (topic == 'device/status/led')
          statusLed = status;
        if (topic == 'device/status/fan')
          statusFan = status;
        if (topic == 'device/status/motor')
          statusMotor = status;
        if (topic == 'device/status/pump')
          statusPump = status;
      });
    };
    mqttService.onRelayRealUpdate = (topic, statusReal) {
      print("📩 Relay update from $topic => $statusReal");
      setState(() {
        if (topic == 'device/status/real/led')
          statusRealLed = statusReal;
        if (topic == 'device/status/real/fan')
          statusRealFan = statusReal;
        if (topic == 'device/status/real/motor')
          statusRealMotor = statusReal;
        if (topic == 'device/status/real/pump')
          statusRealPump = statusReal;
      });
    };

    mqttService.connectMQTT();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang chủ'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Giám sát'),
              Tab(text: 'Điều khiển'),
            ],
          ),
        ),
        drawer: const DashboardDrawer(),
        body: TabBarView(
          children: [
            // TAB 1: GIÁM SÁT
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giám sát môi trường',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap:
                          true, // <-- Bắt buộc để cuộn được
                      physics:
                          NeverScrollableScrollPhysics(), // <-- Ngăn grid tự cuộn
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
                          value:
                              '${humidity.toStringAsFixed(1)} %',
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
                                    '${humidity.toStringAsFixed(1)} %',
                                description:
                                    'Độ ẩm không khí từ cảm biến.',
                                icon: Icons.water_drop,
                              ),
                            );
                          },
                        ),
                        DeviceCard(
                          title: 'Mực nước',
                          value: waterLevel,
                          unit: 'Mức',
                          icon: Icons.waves,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              DeviceDetailScreen.routeName,
                              arguments: DetailArgs(
                                title: 'Mực nước',
                                value: waterLevel,
                                description:
                                    'Mực nước trong bể/ao hiện tại.',
                                icon: Icons.waves,
                              ),
                            );
                          },
                        ),
                        DeviceCard(
                          title: 'Mức thức ăn',
                          value:
                              '${loadcell.toStringAsFixed(0)} Kg',
                          unit: 'Kg',
                          icon: Icons.inventory,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              DeviceDetailScreen.routeName,
                              arguments: DetailArgs(
                                title: 'Mức thức ăn',
                                value:
                                    '${loadcell.toStringAsFixed(0)} %',
                                description:
                                    'Dung lượng thức ăn còn lại trong khoang.',
                                icon: Icons.inventory,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Biểu đồ nhiệt độ',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: TemperatureChart(
                        deviceId: 'esp32',
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Biểu đồ độ ẩm',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: TemperatureChart(
                        deviceId: 'esp32',
                        isHumidity: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TAB 2: ĐIỀU KHIỂN
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  DeviceCardControl(
                    title: 'Đèn sưởi',
                    value: true,
                    icon: Icons.lightbulb_circle_sharp,
                    color: Colors.redAccent,
                    status: statusLed,
                    statusReal: statusRealLed,
                    topicPub: 'esp32/led/control',
                    mqttService: mqttService,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreenControl.routeName,
                        arguments: DetailControlArgs(
                          title: 'Đèn sưởi',
                          secondaryTitle: 'nhiệt độ',
                          status: statusLed,
                          description: '',
                          icon:
                              Icons.lightbulb_circle_sharp,
                          mqttService: mqttService,
                          topic:
                              'device/automode/confirm/led',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DeviceCardControl(
                    title: 'Quạt gió',
                    value: true,
                    icon: Icons.air,
                    color: Colors.green,
                    status: statusFan,
                    statusReal: statusRealFan,
                    topicPub: 'esp32/fan/control',
                    mqttService: mqttService,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreenControl.routeName,
                        arguments: DetailControlArgs(
                          title: 'Quạt gió',
                          secondaryTitle: 'độ ẩm',
                          status: statusFan,
                          description:
                              'Trạng thái hiện tại của quạt gió',
                          icon: Icons.air,
                          mqttService: mqttService,
                          topic:
                              'device/automode/confirm/fan',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DeviceCardControl(
                    title: 'Bơm thức ăn',
                    value: true,
                    icon: Icons.settings,
                    color: Colors.orangeAccent,
                    status: statusMotor,
                    statusReal: statusRealMotor,
                    topicPub: 'esp32/motor/control',
                    mqttService: mqttService,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreenControl.routeName,
                        arguments: DetailControlArgs(
                          title: 'Bơm thức ăn',
                          secondaryTitle: 'cân nặng',
                          status: statusMotor,
                          description:
                              'Trạng thái hiện tại của bơm thức ăn',
                          icon: Icons.settings,
                          mqttService: mqttService,
                          topic:
                              'device/automode/confirm/motor',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DeviceCardControl(
                    title: 'Bơm nước',
                    value: true,
                    icon: Icons.water_drop_outlined,
                    color: Colors.blue,
                    status: statusPump,
                    statusReal: statusRealPump,
                    topicPub: 'esp32/pump/control',
                    mqttService: mqttService,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        DeviceDetailScreenControl.routeName,
                        arguments: DetailControlArgs(
                          title: 'Bơm nước',
                          secondaryTitle: 'mực nước',
                          status: statusPump,
                          description:
                              'Trạng thái hiện tại của bơm nước',
                          icon: Icons.water_drop_outlined,
                          mqttService: mqttService,
                          topic:
                              'device/automode/confirm/pump',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
