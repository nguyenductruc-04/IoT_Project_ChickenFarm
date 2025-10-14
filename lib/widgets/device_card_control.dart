// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:iot_app/mqtt/mqtt.dart';

class DeviceCardControl extends StatefulWidget {
  final String title;
  final bool value;
  final IconData icon;
  final Color color;
  final bool status;
  final MqttService mqttService; // ✅ thêm service vào
  final String topicPub; // topic để publish MQTT
  final VoidCallback? onTap;

  const DeviceCardControl({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.status,
    required this.mqttService,
    required this.topicPub,
    this.onTap,
  });

  @override
  State<DeviceCardControl> createState() =>
      _DeviceCardControlState();
}

class _DeviceCardControlState
    extends State<DeviceCardControl> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.status;
  }

  Future<void> _toggleDevice(bool value) async {
    setState(() => _isOn = value);
    await widget.mqttService.toggleMotor(
      value,
      widget.topicPub,
    ); // Gửi MQTT
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.title} đã ${value ? "BẬT" : "TẮT"}',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 4),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: widget.color.withOpacity(
                    0.15,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                  ),
                ),
                Switch(
                  value: _isOn,
                  activeColor: widget.color,
                  onChanged: _toggleDevice,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isOn ? "BẬT" : "TẮT",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isOn
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
