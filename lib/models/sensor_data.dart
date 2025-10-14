class SensorData {
  final double? temperature;
  final double? humidity;
  final String timestamp;

  SensorData({
    this.temperature,
    this.humidity,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] != null)
          ? (json['temperature'] as num).toDouble()
          : null,
      humidity: (json['humidity'] != null)
          ? (json['humidity'] as num).toDouble()
          : null,
      timestamp: json['timestamp'] ?? '',
    );
  }
}
