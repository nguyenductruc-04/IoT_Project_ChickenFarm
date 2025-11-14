// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:iot_app/mqtt/mqtt.dart';

class DeviceCardControl extends StatefulWidget {
  final String title;
  final bool value;
  final IconData icon;
  final Color color;
  final bool status;
  final bool statusReal;
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
    required this.statusReal,
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

  bool? _pendingValueStatus;
  bool _isLoadingSwitch = false; // chờ phản hồi từ ESP32
  bool? _pendingValueStatusReal;
  bool _isLoadingOnOff = false; // chờ phản hồi từ ESP32

  @override
  void didUpdateWidget(
    covariant DeviceCardControl oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Khi ESP32 trả về status mới khác trước đó:
    if (oldWidget.status != widget.status) {
      setState(() {
        _isLoadingSwitch = false; // tắt loading
        _pendingValueStatus = null; // xóa trạng thái tạm
      });
    }
    // Khi ESP32 phản hồi trạng thái thật (statusReal)
    if (oldWidget.statusReal != widget.statusReal) {
      setState(() {
        _isLoadingOnOff =
            false; // tắt loading ở chữ BẬT/TẮT
      });
    }
  }

  Future<void> _toggleDevice(bool value) async {
    setState(() {
      _pendingValueStatus = value;
      _isLoadingSwitch = true; // bật loading
      _isLoadingOnOff = true; // bật loading ở chữ BẬT/TẮT
      _pendingValueStatusReal =
          value; // lưu giá trị tạm để so sánh sau
    });
    await widget.mqttService.toggleMotor(
      value,
      widget.topicPub,
    ); // Gửi MQTT
    // Sau 3 giây, nếu ESP32 chưa phản hồi, hoàn tác trạng thái
    Future.delayed(Duration(seconds: 30), () {
      if (mounted && _pendingValueStatus != null) {
        setState(() {
          _isLoadingSwitch = false; // tắt loading

          _pendingValueStatus = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không điều khiển được thiết bị, vui lòng tắt chế độ Auto Mode hoặc kiểm tra lại mạng',
            ),
            duration: Duration(seconds: 8),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
    Future.delayed(Duration(seconds: 30), () {
      if (mounted && _isLoadingOnOff) {
        setState(() {
          _isLoadingOnOff = false; // tắt loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không điều khiển được thiết bị, vui lòng tắt chế độ Auto Mode hoặc kiểm tra lại mạng',
            ),
            duration: Duration(seconds: 5),
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
        _pendingValueStatus ?? widget.status;
    final bool isMismatch =
        widget.status != widget.statusReal;
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
                      onChanged: _isLoadingSwitch
                          ? null
                          : _toggleDevice,
                    ),
                    if (_isLoadingSwitch)
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
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          widget.statusReal ? "BẬT" : "TẮT",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isMismatch
                                ? Colors
                                      .orange // ⚠️ cảnh báo khi lệch
                                : widget.statusReal
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        if (_isLoadingOnOff)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white
                                  .withOpacity(0.5),
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
                    if (isMismatch) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
