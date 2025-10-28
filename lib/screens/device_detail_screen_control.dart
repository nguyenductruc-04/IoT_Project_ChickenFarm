// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:iot_app/mqtt/mqtt.dart';
import 'package:mqtt_client/mqtt_client.dart';

class DetailControlArgs {
  final String title;
  final String secondaryTitle;
  final bool status;
  final String description;
  final IconData icon;
  final MqttService mqttService;
  final String topic;

  DetailControlArgs({
    required this.title,
    required this.secondaryTitle,
    required this.status,
    required this.description,
    required this.icon,
    required this.mqttService,
    required this.topic,
  });
}

class DeviceDetailScreenControl extends StatefulWidget {
  static const String routeName = '/device-control-detail';
  const DeviceDetailScreenControl({super.key});

  @override
  State<DeviceDetailScreenControl> createState() =>
      _DeviceDetailScreenControlState();
}

class _DeviceDetailScreenControlState
    extends State<DeviceDetailScreenControl> {
  dynamic selectedThreshold; // lưu ngưỡng nhiệt độ
  bool autoMode = false; // trạng thái công tắc auto
  late DetailControlArgs args;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args =
        ModalRoute.of(context)!.settings.arguments
            as DetailControlArgs;
    Future.delayed(Duration(microseconds: 500), () {
      args.mqttService.requestAutoMode();
    });

    // ✅ Lắng nghe dữ liệu ngưỡng từ ESP32
    args.mqttService.onselectedThresholdUpdate =
        (topic, bool newautoMode, dynamic newThreshold) {
          if (!mounted) return;
          if (topic == args.topic ||
              (args.title.contains("Đèn") &&
                  topic == 'device/automode/confirm/led') ||
              (args.title.contains("Quạt") &&
                  topic == 'device/automode/confirm/fan') ||
              (args.title.contains("Bơm Thức Ăn") &&
                  topic ==
                      'device/automode/confirm/motor') ||
              (args.title.contains("Bơm nước") &&
                  topic ==
                      'device/automode/confirm/pump')) {
            if (autoMode != newautoMode ||
                selectedThreshold != newThreshold) {
              setState(() {
                autoMode = newautoMode;
                selectedThreshold = newThreshold;
              });
            }
          }
        };
  }

  // ✅ Hàm chọn ngưỡng
  void showPickerNumber(
    BuildContext context,
    DetailControlArgs args,
  ) {
    int begin;
    int end;
    String unit;

    if (args.title.toLowerCase().contains("đèn")) {
      begin = 15;
      end = 40;
      unit = "°C";
    } else if (args.title.toLowerCase().contains("quạt")) {
      begin = 50;
      end = 100;
      unit = "%";
    } else {
      begin = 0;
      end = 100;
      unit = "";
    }

    Picker(
      adapter: NumberPickerAdapter(
        data: [
          NumberPickerColumn(
            begin: begin,
            end: end,
            suffix: Text(unit),
          ),
        ],
      ),
      hideHeader: true,
      title: Text(
        "Chọn ngưỡng ${args.secondaryTitle} để bật ${args.title}",
      ),
      selectedTextStyle: TextStyle(
        color: Colors.blue,
        fontSize: 18,
      ),
      onConfirm: (Picker picker, List value) {
        final selected = picker.getSelectedValues()[0];

        selectedThreshold = selected;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Set ngưỡng nhiệt độ: $selected $unit",
            ),
          ),
        );

        // ✅ Gửi ngưỡng qua MQTT tới ESP32
        final topic =
            args.title.toLowerCase().contains("đèn")
            ? "device/automode/threshold/led"
            : args.title.toLowerCase().contains("quạt")
            ? "device/automode/threshold/fan"
            : "device/automode/threshold/unknown"; // ✅ thêm nhánh else cuối

        args.mqttService.pickerNumber(
          selectedThreshold,
          topic,
        );
      },
    ).showDialog(context);
  }

  void showPickerText(
    BuildContext context,
    DetailControlArgs args,
  ) {
    // Danh sách giá trị để chọn
    final List<String> options = ["Thap", "Trung binh"];

    Picker(
      adapter: PickerDataAdapter<String>(
        pickerData: options,
      ),
      hideHeader: true,
      title: Text("Chọn mức cho ${args.title}"),
      selectedTextStyle: TextStyle(
        color: Colors.blue,
        fontSize: 18,
      ),
      onConfirm: (Picker picker, List value) {
        final selected =
            picker.getSelectedValues()[0] as String;
        selectedThreshold = selected;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã chọn mức: $selected")),
        );
        final topic =
            args.title.toLowerCase().contains("bơm thức ăn")
            ? "device/automode/threshold/motor"
            : args.title.toLowerCase().contains("bơm nước")
            ? "device/automode/threshold/pump"
            : "device/automode/threshold/unknown"; // ✅ thêm nhánh else cuối

        args.mqttService.pickerNumber(
          selectedThreshold,
          topic,
        );
      },
    ).showDialog(context);
  }

  // ✅ Gửi lệnh Auto Mode
  void toggleAutoMode(bool value) {
    setState(() {
      autoMode = value;
    });

    // Xác định topic gửi lệnh Auto
    final topic = args.title.toLowerCase().contains("đèn")
        ? "device/automode/led"
        : args.title.toLowerCase().contains("quạt")
        ? "device/automode/fan"
        : args.title.toLowerCase().contains("bơm thức ăn")
        ? "device/automode/motor"
        : args.title.toLowerCase().contains("bơm nước")
        ? "device/automode/pump"
        : "device/automode/unknown"; // ✅ thêm nhánh else cuối

    args.mqttService.toggleAutoMode(value, topic);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? "✅ Bật chế độ tự động theo ngưỡng"
              : "🛠️ Tắt chế độ tự động (thủ công)",
        ),
      ),
    );
    if (value) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (args.title.contains("Đèn") ||
            args.title.contains("Quạt")) {
          showPickerNumber(context, args);
        } else if (args.title.contains("Bơm thức ăn") ||
            args.title.contains("Bơm nước")) {
          showPickerText(context, args);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DetailControlArgs args =
        ModalRoute.of(context)!.settings.arguments
            as DetailControlArgs;

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Icon(args.icon, size: 28),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge,
                    ),
                    SizedBox(height: 4),
                    Text(
                      args.status ? "Bật" : "Tắt",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(args.description),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 12),

            /// 🔘 Công tắc Auto Mode
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Điều khiển theo ngưỡng",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: autoMode,
                  onChanged: toggleAutoMode,
                ),
              ],
            ),

            Divider(),
            SizedBox(height: 12),
            if (args.title.contains("Đèn") ||
                args.title.contains("Quạt")) ...[
              Text(
                "Chọn ngưỡng ${args.secondaryTitle} bật ${args.title}",
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      selectedThreshold != null
                          ? "${selectedThreshold!} ${args.title.toLowerCase().contains("đèn")
                                ? "°C"
                                : args.title.toLowerCase().contains("quạt")
                                ? "%"
                                : ""}"
                          : "Chưa có dữ liệu từ ESP32",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          showPickerNumber(context, args),
                      child: Text("Chọn lại"),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
            if (args.title.contains("Bơm thức ăn") ||
                args.title.contains("Bơm nước")) ...[
              Text(
                "Chọn ngưỡng ${args.secondaryTitle} bật ${args.title}",
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      selectedThreshold != null
                          ? "${selectedThreshold!} ${args.title.toLowerCase().contains("đèn")
                                ? "°C"
                                : args.title.toLowerCase().contains("quạt")
                                ? "%"
                                : ""}"
                          : "Chưa có dữ liệu từ ESP32",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          showPickerText(context, args),
                      child: Text("Chọn lại"),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],

            /// 👇 Chỉ hiển thị phần chọn ngưỡng khi AutoMode đang bật
          ],
        ),
      ),
    );
  }
}
