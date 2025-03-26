import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/screen/device/deviceState.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:paddy_rice/widgets/model.dart';
import 'package:paddy_rice/widgets/ChoiceDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paddy_rice/widgets/web_socket_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:paddy_rice/widgets/mqtt_client.dart';

@RoutePage()
class HomeRoute extends StatefulWidget {
  const HomeRoute({Key? key}) : super(key: key);

  @override
  _HomeRouteState createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute> with WidgetsBindingObserver {
  List<Device> devices = [];
  final WebSocketService _webSocketService = WebSocketService();
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isTempChanged = false;
  late MQTTService _mqttService;
  String _mqttMessage = "No data received";
  double frontTemperature = 0.0;
  double rearTemperature = 0.0;
  double moisture = 0.0;
  late Timer _mqttTimeoutTimer;
  final int _mqttTimeoutDuration = 10;
  bool isDataReceived = false;
  bool shouldShowNotification = false;
  Map<String, DeviceData> deviceDataMap = {};
  String? _token;

  @override
  void initState() {
    super.initState();
    _getToken();

    _mqttService = MQTTService();

    _initializeDevices();

    WidgetsBinding.instance.addObserver(this);

    _mqttService.connect().then((_) {
      _mqttService.listenToMessages((message) {
        setState(() {
          // _mqttMessage = message;
          Map<String, dynamic> data = jsonDecode(message);
          frontTemperature = data['front_temperature']?.toDouble() ?? 0.0;
          rearTemperature = data['rear_temperature']?.toDouble() ?? 0.0;
          moisture = data['moisture']?.toDouble() ?? 0.0;
          // int deviceStatus = data['status'] ?? 0;
          isDataReceived = true;
          _resetMqttTimeoutTimer();
          print("อัปเดตข้อมูลจาก MQTT");
          print("Front Temp: $frontTemperature");
          print("Rear Temp: $rearTemperature");
          print("Moisture: $moisture");
          // print("Status: $deviceStatus");
        });
      });
    }).catchError((error) {
      print('Error connecting to MQTT: $error');
    });
    _startMqttTimeoutTimer();
  }

  void _startMqttTimeoutTimer() {
    _mqttTimeoutTimer =
        Timer.periodic(Duration(seconds: _mqttTimeoutDuration), (timer) {
      if (!isDataReceived) {
        setState(() {
          for (var device in devices) {
            device.status == false;
          }
        });
        print(
            "MQTT timeout: No data received within $_mqttTimeoutDuration seconds, setting devices to offline.");
      }
      isDataReceived = false;
    });
  }

  void _resetMqttTimeoutTimer() {
    if (_mqttTimeoutTimer.isActive) {
      _mqttTimeoutTimer.cancel();
    }
    _startMqttTimeoutTimer();
  }

  Future<void> _initializeDevices() async {
    await _fetchDevices();
    _setupWebSocketConnections();
  }

  void _setupWebSocketConnections() {
    for (var device in devices) {
      _webSocketService.connectToDevice(
        device.id,
        (data) => _handleWebSocketMessage(jsonDecode(data)),
      );
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    try {
      final deviceId = data['deviceId'];
      final devicename = data['device_name'];
      final frontTemp = data['front_temperature'];
      final backTemp = data['back_temperature'];
      final humidity = data['moisture'];

      setState(() {
        final index = devices.indexWhere((device) => device.id == deviceId);
        if (index != -1) {
          devices[index].frontTemp = frontTemp?.toDouble() ?? 0.0;
          devices[index].backTemp = backTemp?.toDouble() ?? 0.0;
          devices[index].humidity = humidity?.toDouble() ?? 0.0;
          devices[index].status == true;

          double targetFrontTemp = devices[index].targetFrontTemp;
          print("Target Front Temp: $targetFrontTemp");
          double targetBackTemp = devices[index].targetBackTemp;
          double targetHumidity = devices[index].targetHumidity;

          if (frontTemp > targetFrontTemp ||
              backTemp > targetBackTemp ||
              humidity > targetHumidity) {
            chackDeviceTargetValues(
              devices[index].id,
              devices[index].name,
              frontTemp,
              backTemp,
              humidity,
            );
          }
        }
      });

      print('Device Front Temperature: $frontTemp');
      print('Device Rear Temperature: $backTemp');
      print('Device Moisture: $humidity');
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    _deviceNameController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _mqttService.disconnect();
    _mqttTimeoutTimer.cancel();
    super.dispose();
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> _getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print('Firebase Token Request Started');

      if (token == null) {
        print('Token is null');
      } else {
        setState(() {
          _token = token;
        });
        print('Token successfully retrieved: $token');
      }
    } catch (e) {
      print('Error getting token: $e');
    }
  }

  Future<void> _fetchDevices() async {
    final userId = await _getUserId();
    if (userId == null) return;

    final url = '${ApiConstants.baseUrl}/user/devices/$userId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> deviceJson = jsonDecode(response.body);
        print("Response body: ${response.body}");
        setState(() {
          devices = deviceJson.map((json) => Device.fromJson(json)).toList();
        });
        for (var device in devices) {
          double frontTemp = device.frontTemp;
          double rearTemp = device.backTemp;
          double moisture = device.humidity;

          print('Device Front Temperature: $frontTemp');
          print('Device Rear Temperature: $rearTemp');
          print('Device Moisture: $moisture');
        }
      } else {
        print('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching devices: $e');
    }
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = (_deviceNameController.text.isNotEmpty &&
              _deviceNameController.text != widget.key.toString()) ||
          _isTempChanged;
    });
  }

  Future<void> chackDeviceTargetValues(
      String deviceId,
      String deviceName,
      double targetFrontTemp,
      double targetBackTemp,
      double targetHumidity) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/update-device');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'device_name': deviceName,
          'targetFrontTemp': targetFrontTemp,
          'targetBackTemp': targetBackTemp,
          'targetHumidity': targetHumidity,
        }),
      );

      if (response.statusCode == 200) {
        print('Device updated successfully');
        setState(() {
          shouldShowNotification = true;
        });
      } else {
        print('Failed to update device: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating device: $e');
    }
  }

  void onDeviceTap(Device device) async {
    _webSocketService.disconnectFromDevice(device.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceId', device.id);

    final updatedDevice = await Navigator.push<Device>(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceSateRoute(device: device),
      ),
    );

    if (updatedDevice != null) {
      await _fetchDevices();
      setState(() {
        int index = devices.indexWhere((d) => d.id == updatedDevice.id);
        if (index != -1) {
          devices[index] = updatedDevice;
        }
      });
      _webSocketService.connectToDevice(
        updatedDevice.id,
        (data) => _handleWebSocketMessage(jsonDecode(data)),
      );
    }
  }

  // Show error message in a SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error_color),
    );
  }

  // Get device status color
  Color _getDeviceStatusColor(bool status) {
    return status ? Color(0xFF80C080) : Color.fromRGBO(237, 76, 47, 1);
  }

  void removeDevice(int index) {
    setState(() => devices.removeAt(index));
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: S.of(context)!.delete,
          content: S.of(context)!.delete_confirmation,
          parentContext: context,
          confirmButtonText: S.of(context)!.delete,
          cancelButtonText: S.of(context)!.cancel,
          onConfirm: () {
            removeDevice(index);
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = S.of(context);
    MenuItems.init(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor,
        title: Text(localizations!.title, style: appBarFont),
        actions: [
          IconButton(
            onPressed: () => context.router.replaceNamed('/notifi'),
            icon: Stack(
              children: <Widget>[
                Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: shouldShowNotification
                      ? Colors.red
                      : iconcolor, // เปลี่ยนสีเป็นแดงเมื่อมีการแจ้งเตือน
                ),
                if (shouldShowNotification)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(237, 76, 47, 1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(right: 16),
          //   child: DropdownButtonHideUnderline(
          //     child: DropdownButton2(
          //       customButton: Icon(Icons.more_vert, size: 24, color: iconcolor),
          //       items: [
          //         ...MenuItems.firstItems
          //             .map((item) => DropdownMenuItem<MenuItem>(
          //                   value: item,
          //                   child: MenuItems.buildItem(item),
          //                 )),
          //       ],
          //       // onChanged: (value) {
          //       //   final menuItem = value as MenuItem;
          //       //   if (menuItem.text == localizations.bluetooth) {
          //       //     context.router.replaceNamed('/addDevice');
          //       //   } else if (menuItem.text == localizations.qr_code) {
          //       //     context.router.replaceNamed('/scan');
          //       //   }
          //       // },
          //       dropdownStyleData: DropdownStyleData(
          //         width: 160,
          //         padding: const EdgeInsets.symmetric(vertical: 6),
          //         decoration: BoxDecoration(
          //           borderRadius: BorderRadius.circular(4),
          //           color: fill_color,
          //         ),
          //         offset: const Offset(-144, 8),
          //       ),
          //       menuItemStyleData: MenuItemStyleData(
          //         customHeights: [
          //           ...List<double>.filled(MenuItems.firstItems.length, 48),
          //         ],
          //         padding: const EdgeInsets.only(left: 16, right: 16),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      backgroundColor: maincolor,
      body: Stack(
        children: [
          DecoratedImage(),
          Center(
            child: Column(
              children: [
                DecoratedImage(),
                const SizedBox(height: 24),
                devices.isEmpty
                    ? _buildNoDevices(localizations)
                    : Expanded(child: _buildDeviceList(localizations)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // No devices UI
  Widget _buildNoDevices(S localizations) {
    return Container(
      width: 316,
      height: 135,
      decoration: BoxDecoration(
        color: fill_color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.5,
            child: Image.asset(
              'lib/assets/icon/home.png',
              height: 94,
              fit: BoxFit.contain,
            ),
          ),
          const Divider(
            height: 1.0,
            color: Color.fromRGBO(215, 215, 215, 1),
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          Text(
            localizations.no_devices,
            style: const TextStyle(
              color: Color.fromRGBO(137, 137, 137, 1),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Device list UI
  Widget _buildDeviceList(S localizations) {
    return Container(
      width: 316,
      height: 135,
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var device in devices)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Slidable(
                  key: ValueKey(device),
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeviceSateRoute(device: device),
                            ),
                          );

                          if (result == true) {
                            _initializeDevices();
                          }
                        },
                        backgroundColor: const Color.fromRGBO(247, 145, 19, 1),
                        foregroundColor: fill_color,
                        icon: Icons.settings,
                      ),
                      // SlidableAction(
                      //   onPressed: (context) => onDeviceTap(device),
                      //   backgroundColor: const Color.fromRGBO(247, 145, 19, 1),
                      //   foregroundColor: fill_color,
                      //   icon: Icons.settings,
                      // ),
                      // SlidableAction(
                      //   onPressed: (context) =>
                      //       _showDeleteConfirmationDialog(),
                      //   backgroundColor: const Color.fromRGBO(237, 76, 47, 1),
                      //   foregroundColor: fill_color,
                      //   icon: Icons.delete,
                      // ),
                    ],
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: fill_color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: _getDeviceStatusColor(device.status),
                          width: 8,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                // ใช้ Expanded เพื่อให้ข้อความไม่ล้น
                                child: Text(
                                  device.name.length > 21
                                      ? '${device.name.substring(0, 21)}...'
                                      : device.name,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: fontcolor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getDeviceStatusColor(device.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  device.status
                                      ? localizations.running
                                      : localizations.close,
                                  style: TextStyle(
                                    color: fill_color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${frontTemperature.toStringAsFixed(2)} C',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: fontcolor),
                                    ),
                                    Text(
                                      S.of(context)!.temp_front,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: unnecessary_colors),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${rearTemperature.toStringAsFixed(2)} C',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: fontcolor),
                                    ),
                                    Text(
                                      S.of(context)!.temp_back,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: unnecessary_colors),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${moisture.toStringAsFixed(2)} %',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: fontcolor),
                                    ),
                                    Text(
                                      S.of(context)!.humidity_,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: unnecessary_colors),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _getDeviceStatusColor(bool status) {
  return status ? Color(0xFF80C080) : Color.fromRGBO(237, 76, 47, 1);
}

class MenuItem {
  const MenuItem({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;
}

abstract class MenuItems {
  static late MenuItem devices;
  static late MenuItem scan_qr;

  static late List<MenuItem> firstItems;

  static void init(BuildContext context) {
    final localizations = S.of(context)!;
    devices = MenuItem(text: localizations.bluetooth, icon: Icons.bluetooth);
    scan_qr =
        MenuItem(text: localizations.qr_code, icon: Icons.qr_code_2_outlined);

    firstItems = [devices, scan_qr];
  }

  static Widget buildItem(MenuItem item) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(item.icon, color: iconcolor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(color: Color.fromRGBO(77, 22, 0, 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceData {
  final double frontTemp;
  final double rearTemp;
  final double moisture;

  DeviceData({
    required this.frontTemp,
    required this.rearTemp,
    required this.moisture,
  });
}
