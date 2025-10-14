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
  final Function(double temp, double hum, String level)?
  onSensorUpdate;
  Function(String topic, bool status)? onRelayUpdate;

  // ✅ Biến lưu giá trị gần nhất
  double? _lastTemp;
  double? _lastHum;
  String? _lastLevel;

  // ✅ Map lưu trạng thái relay theo topic
  final Map<String, bool> _relayStatus = {};

  MqttService({
    required this.awsEndpoint,
    required this.clientId,
    required this.port,
    this.onSensorUpdate,
  }) {
    client = MqttServerClient.withPort(
      awsEndpoint,
      clientId,
      port,
    );
    client.secure = true;
    client.keepAlivePeriod = 20;
    client.setProtocolV311();
    client.logging(on: true);
  }

  Future<int> connectMQTT() async {
    // --- Tải chứng chỉ AWS ---
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

      const topicTemp = 'esp32/esp32-to-aws-temp';
      const topicHum = 'esp32/esp32-to-aws-hum';
      const topicWaterLevel =
          'esp32/esp32-to-aws-water-level';

      const topicStatusLed = 'device/status/led';
      const topicStatusFan = 'device/status/fan';
      const topicStatusMotor = 'device/status/motor';
      const topicStatusPump = 'device/status/pump';
      client.subscribe(topicTemp, MqttQos.atLeastOnce);
      client.subscribe(topicHum, MqttQos.atLeastOnce);
      client.subscribe(
        topicWaterLevel,
        MqttQos.atLeastOnce,
      );
      client.subscribe(topicStatusLed, MqttQos.atLeastOnce);
      client.subscribe(topicStatusFan, MqttQos.atLeastOnce);
      client.subscribe(
        topicStatusMotor,
        MqttQos.atLeastOnce,
      );
      client.subscribe(
        topicStatusPump,
        MqttQos.atLeastOnce,
      );
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
          if (data is Map<String, dynamic> &&
              data['status'] != null) {
            bool statusBool = (data['status'] == "ON");

            if (onRelayUpdate != null) {
              onRelayUpdate!(c[0].topic, statusBool);
            }
          }
          if (data is Map<String, dynamic>) {
            // Tạm thời lấy giá trị cũ
            double temp = _lastTemp ?? 0;
            double hum = _lastHum ?? 0;
            String level = _lastLevel ?? "";
            if (c[0].topic == topicTemp &&
                data['data_TempC'] != null) {
              temp = (data['data_TempC'] as num).toDouble();
              _lastTemp = temp;
              print('🌡️ Nhiệt độ cập nhật: $temp °C');
            }
            if (c[0].topic == topicHum &&
                data['data_Hum'] != null) {
              hum = (data['data_Hum'] as num).toDouble();
              _lastHum = hum;
              print('💧 Độ ẩm cập nhật: $hum %');
            }
            if (c[0].topic == topicWaterLevel &&
                data['data_WaterLevel'] != null) {
              String level = data['data_WaterLevel']
                  .toString();
              _lastLevel = level;
              print('💧 Mực nước cập nhật: $level %');
            }

            // ✅ Gọi callback ngay khi có bất kỳ dữ liệu mới nào
            if (onSensorUpdate != null) {
              onSensorUpdate!(temp, hum, level);
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

  /// Gửi lệnh điều khiển motor
  Future<void> toggleMotor(bool value, String topic) async {
    if (client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(
        value ? '{"status":"ON"}' : '{"status":"OFF"}',
      );

      client.publishMessage(
        topic,
        MqttQos.atMostOnce,
        builder.payload!,
      );

      print(
        "📤 Đã gửi lệnh motor: ${value ? "ON" : "OFF"}",
      );
    } else {
      print("⚠️ MQTT chưa kết nối!");
    }
  }

  /// Gửi ngưỡng nhiệt độ settup
  Future<void> pickerNumber(
    String value,
    String topic,
  ) async {
    if (client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"threshold":"$value"}');

      client.publishMessage(
        topic,
        MqttQos.atMostOnce,
        builder.payload!,
      );

      print(
        "📤 Đã gửi ngưỡng nhiệt độ: ${"temperatureThreshold : $value"}",
      );
    } else {
      print("⚠️ MQTT chưa kết nối!");
    }
  }

  /// ✅ Lấy trạng thái relay hiện tại theo topic
  bool? getRelayStatus(String topic) {
    return _relayStatus[topic];
  }
}
