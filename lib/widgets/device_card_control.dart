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
  @override
  void initState() {
    super.initState();
  }

  bool? _pendingValue;
  bool _isLoading = false; // chờ phản hồi từ ESP32

  @override
  void didUpdateWidget(
    covariant DeviceCardControl oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Khi ESP32 trả về status mới khác trước đó:
    if (oldWidget.status != widget.status) {
      setState(() {
        _isLoading = false; // tắt loading
        _pendingValue = null; // xóa trạng thái tạm
      });
    }
  }

  Future<void> _toggleDevice(bool value) async {
    setState(() {
      _pendingValue = value;
      _isLoading = true; // bật loading
    });
    await widget.mqttService.toggleMotor(
      value,
      widget.topicPub,
    ); // Gửi MQTT
    // Sau 3 giây, nếu ESP32 chưa phản hồi, hoàn tác trạng thái
    Future.delayed(Duration(seconds: 60), () {
      if (mounted && _pendingValue != null) {
        setState(() {
          _isLoading = false; // tắt loading

          _pendingValue = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không điều khiển được thiết bị, vui lòng tắt chế độ Auto Mode hoặc phần cứng có vấn đề vui lòng kiểm tra!',
            ),
            duration: Duration(seconds: 8),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.title} đang được ${value ? "BẬT" : "TẮT"}',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool displayValue =
        _pendingValue ?? widget.status;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: Offset(0, 3),
              color: Colors.black.withOpacity(0.1),
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Switch(
                      value: displayValue,
                      activeColor: widget.color,
                      onChanged: _isLoading
                          ? null
                          : _toggleDevice,
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(
                            0.5,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: widget.color,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                    widget.status ? "BẬT" : "TẮT",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.status
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
