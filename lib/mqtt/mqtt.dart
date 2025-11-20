// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  final String awsEndpoint;
  final String clientId;
  final int port;

  /// Callback gửi dữ liệu cảm biến về UI
  final Function(double temp, double hum, String level, double cell)?
  onSensorUpdate;
  Function(String topic, bool status)? onRelayUpdate;
  Function(String topic, bool statusReal)? onRelayRealUpdate;
  Function(String topic, bool autoMode, dynamic newThreshold)?
  onselectedThresholdUpdate;

  // Biến lưu giá trị gần nhất
  double? _lastTemp;
  double? _lastHum;
  String? _lastLevel;
  double? _lastcell;

  // Map lưu trạng thái relay theo topic
  final Map<String, bool> _relayStatus = {};
  final Map<String, bool> _relayStatusReal = {};

  MqttService({
    required this.awsEndpoint,
    required this.clientId,
    required this.port,
    this.onSensorUpdate,
  }) {
    client = MqttServerClient.withPort(awsEndpoint, clientId, port);
    client.secure = true;
    client.keepAlivePeriod = 20;
    client.setProtocolV311();
    client.logging(on: true);
  }

  Future<int> connectMQTT() async {
    // --- Tải chứng chỉ AWS ---
    ByteData rootCA = await rootBundle.load('assets/certs/AmazonRootCA1.pem');
    ByteData deviceCert = await rootBundle.load(
      'assets/certs/certificate.pem.crt',
    );
    ByteData privateKey = await rootBundle.load('assets/certs/private.pem.key');

    SecurityContext context = SecurityContext.defaultContext;
    context.setClientAuthoritiesBytes(rootCA.buffer.asInt8List());
    context.useCertificateChainBytes(deviceCert.buffer.asInt8List());
    context.usePrivateKeyBytes(privateKey.buffer.asInt8List());

    client.securityContext = context;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();
    client.connectionMessage = connMess;

    // Debug connect MQTT
    try {
      print("🔌 Đang kết nối tới MQTT...");
      await client.connect();
    } on Exception catch (e) {
      print("❌ Lỗi kết nối: $e");
      client.disconnect();
      return -1;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('✅ MQTT client connected to AWS IoT');

      const topicTemp = 'esp32/esp32-to-aws-temp';
      const topicHum = 'esp32/esp32-to-aws-hum';
      const topicWaterLevel = 'esp32/esp32-to-aws-water-level';
      const topicCell = 'esp32/esp32-to-aws-cell';

      const topicStatusLed = 'device/status/led';
      const topicStatusFan = 'device/status/fan';
      const topicStatusMotor = 'device/status/motor';
      const topicStatusPump = 'device/status/pump';

      const topicRealStatusLed = 'device/status/real/led';
      const topicRealStatusFan = 'device/status/real/fan';
      const topicRealStatusMotor = 'device/status/real/motor';
      const topicRealStatusPump = 'device/status/real/pump';

      const topicThresholdLed = 'device/automode/confirm/led';
      const topicThresholdFan = 'device/automode/confirm/fan';
      const topicThresholdMotor = 'device/automode/confirm/motor';
      const topicThresholdPump = 'device/automode/confirm/pump';

      client.subscribe(topicTemp, MqttQos.atLeastOnce);
      client.subscribe(topicHum, MqttQos.atLeastOnce);
      client.subscribe(topicWaterLevel, MqttQos.atLeastOnce);
      client.subscribe(topicCell, MqttQos.atLeastOnce);

      client.subscribe(topicStatusLed, MqttQos.atLeastOnce);
      client.subscribe(topicStatusFan, MqttQos.atLeastOnce);
      client.subscribe(topicStatusMotor, MqttQos.atLeastOnce);
      client.subscribe(topicStatusPump, MqttQos.atLeastOnce);

      client.subscribe(topicRealStatusLed, MqttQos.atLeastOnce);
      client.subscribe(topicRealStatusFan, MqttQos.atLeastOnce);
      client.subscribe(topicRealStatusMotor, MqttQos.atLeastOnce);
      client.subscribe(topicRealStatusPump, MqttQos.atLeastOnce);

      client.subscribe(topicThresholdLed, MqttQos.atLeastOnce);
      client.subscribe(topicThresholdFan, MqttQos.atLeastOnce);
      client.subscribe(topicThresholdMotor, MqttQos.atLeastOnce);
      client.subscribe(topicThresholdPump, MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        print('📩 Nhận dữ liệu từ topic <${c[0].topic}>: $payload');

        try {
          final data = jsonDecode(payload);

          if (data is Map<String, dynamic> && data['status'] != null) {
            bool statusBool = (data['status'] == "ON");

            if (onRelayUpdate != null) {
              onRelayUpdate!(c[0].topic, statusBool);
            }
          }

          if (data is Map<String, dynamic> && data['status'] != null) {
            bool statusReal = (data['status'] == "ON");

            if (onRelayRealUpdate != null) {
              onRelayRealUpdate!(c[0].topic, statusReal);
            }
          }

          if (data is Map<String, dynamic>) {
            bool autoMode = false;
            dynamic selectedThreshold;

            if (data['autoMode'] != null) {
              if (data['autoMode'] is bool) {
                autoMode = data['autoMode'];
              } else if (data['autoMode'] is String) {
                final value = data['autoMode'].toString().toLowerCase();
                autoMode = value == "on" || value == "true" || value == "1";
              }
            }

            if (data.containsKey('selectedThreshold')) {
              selectedThreshold = data['selectedThreshold'];
            }

            print('🔥 Ngưỡng nhiệt độ nhận được: $selectedThreshold');

            if (onselectedThresholdUpdate != null) {
              onselectedThresholdUpdate!(
                c[0].topic,
                autoMode,
                selectedThreshold,
              );
            }
          }
          if (data is Map<String, dynamic>) {
            // Tạm thời lấy giá trị cũ
            double temp = _lastTemp ?? 0;
            double hum = _lastHum ?? 0;
            String level = _lastLevel ?? "";
            double cell = _lastcell ?? 0;

            if (c[0].topic == topicTemp && data['data_TempC'] != null) {
              temp = (data['data_TempC'] as num).toDouble();
              _lastTemp = temp;
              print('🌡️ Nhiệt độ cập nhật: $temp °C');
            }
            if (c[0].topic == topicHum && data['data_Hum'] != null) {
              hum = (data['data_Hum'] as num).toDouble();
              _lastHum = hum;
              print('💧 Độ ẩm cập nhật: $hum %');
            }
            if (c[0].topic == topicWaterLevel &&
                data['data_WaterLevel'] != null) {
              String level = data['data_WaterLevel'].toString();
              _lastLevel = level;
              print('💧 Mực nước cập nhật: $level %');
            }
            if (c[0].topic == topicCell && data['data_Cell'] != null) {
              cell = (data['data_Cell'] as num).toDouble();
              _lastcell = cell;
              print('💧Mức thức ăn cập nhật: $cell Kg');
            }

            // Gọi callback ngay khi có bất kỳ dữ liệu mới nào
            if (onSensorUpdate != null) {
              onSensorUpdate!(temp, hum, level, cell);
            }
          }
        } catch (e) {
          print('❌ Lỗi parse payload: $e');
        }
      });
    } else {
      print("❌ Không thể kết nối MQTT.");
    }
    return 0;
  }

  Future<void> requestRelay() async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"status":"ON"}');

      // Gửi yêu cầu đến ESP32
      client.publishMessage(
        'esp32/request/relay',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('📤 Yêu cầu ESP32 gửi trạng thái hiện tại của Relay');
    } else {
      print('⚠️ MQTT chưa kết nối, không thể yêu cầu trạng thái!');
    }
  }

  Future<void> requestAutoMode() async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"status":"ON"}');

      // Gửi yêu cầu đến ESP32
      client.publishMessage(
        'esp32/request/autoMode',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('📤 Yêu cầu ESP32 gửi trạng thái hiện tại của Auto Mode...');
    } else {
      print('⚠️ MQTT chưa kết nối, không thể yêu cầu trạng thái!');
    }
  }

  /// Gửi lệnh điều khiển motor
  Future<void> toggleMotor(bool value, String topic) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(value ? '{"status":"ON"}' : '{"status":"OFF"}');

      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);

      print("📤 Đã gửi lệnh motor: ${value ? "ON" : "OFF"}");
    } else {
      print("⚠️ MQTT chưa kết nối!");
    }
  }

  /// Gửi ngưỡng nhiệt độ settup
  Future<void> pickerNumber(dynamic value, String topic) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"threshold":"$value"}');

      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);

      print("📤 Đã gửi ngưỡng nhiệt độ: ${"temperatureThreshold : $value"}");
    } else {
      print("⚠️ MQTT chưa kết nối!");
    }
  }

  /// Lấy trạng thái relay theo topic
  bool? getRelayStatus(String topic) {
    return _relayStatus[topic];
  }

  /// Lấy trạng thái relay hiện tại theo topic
  bool? getRelayStatusReal(String topic) {
    return _relayStatusReal[topic];
  }

  /// Gửi lệnh bật/tắt chế độ tự động
  Future<void> toggleAutoMode(bool isOn, String topic) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"status":"${isOn ? "ON" : "OFF"}"}');

      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);

      print("📤 Gửi lệnh AutoMode: ${isOn ? "ON" : "OFF"} đến $topic");
    } else {
      print("⚠️ MQTT chưa kết nối!");
    }
  }
}
