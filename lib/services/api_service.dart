import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  static const String baseUrl =
      'https://rv5zu8zsdb.execute-api.us-east-1.amazonaws.com/prod';

  static Future<List<SensorData>> fetchTemperatureData(
    String deviceId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/temperature?deviceId=$deviceId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(
        response.body,
      );
      print(
        'Parsed JSON: $jsonList',
      ); // In ra dữ liệu sau khi decode
      return jsonList
          .map((e) => SensorData.fromJson(e))
          .toList();
    } else {
      throw Exception(
        'Lỗi tải dữ liệu: ${response.statusCode}',
      );
    }
  }

  static Future<List<SensorData>> fetchHumidityData(
    String deviceId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/humidity?deviceId=$deviceId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(
        response.body,
      );
      return jsonList
          .map((e) => SensorData.fromJson(e))
          .toList();
    } else {
      throw Exception(
        'Lỗi tải dữ liệu: ${response.statusCode}',
      );
    }
  }
}
