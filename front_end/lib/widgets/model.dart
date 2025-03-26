import 'package:flutter/material.dart';
// import 'package:flutter_blue/flutter_blue.dart';

class Device {
  String name;
  final String id;
  final bool status;
  double frontTemp;
  double backTemp;
  double humidity;
  double targetFrontTemp;
  double targetBackTemp;
  double targetHumidity;

  Device({
    required this.name,
    required this.id,
    required this.status,
    this.frontTemp = 0.0,
    this.backTemp = 0.0,
    this.humidity = 0.0,
    this.targetFrontTemp = 0.0,
    this.targetBackTemp = 0.0,
    this.targetHumidity = 0.0,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['device_name'] ?? '',
      id: json['device_id']?.toString() ?? '',
      status: json['status'] == 1,
      frontTemp: json['front_temp'] != null
          ? (json['front_temp'] as num).toDouble()
          : 0.0,
      backTemp: json['back_temp'] != null
          ? (json['back_temp'] as num).toDouble()
          : 0.0,
      humidity:
          json['humidity'] != null ? (json['humidity'] as num).toDouble() : 0.0,
      targetFrontTemp: json['target_front_temp'] != null
          ? (json['target_front_temp'] as num).toDouble()
          : 0.0,
      targetBackTemp: json['target_back_temp'] != null
          ? (json['target_back_temp'] as num).toDouble()
          : 0.0,
      targetHumidity: json['target_humidity'] != null
          ? (json['target_humidity'] as num).toDouble()
          : 0.0,
    );
  }
}

class DeviceModel extends ChangeNotifier {
  final List<Device> _devices = [];

  List<Device> get devices => _devices;

  void addDevice(Device device) {
    if (!_devices.any((d) => d.id == device.id)) {
      _devices.add(device);
      notifyListeners();
    }
  }

  void removeDevice(Device device) {
    _devices.removeWhere((d) => d.id == device.id);
    notifyListeners();
  }
}
