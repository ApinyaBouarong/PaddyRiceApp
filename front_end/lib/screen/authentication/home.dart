import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/screen/device/deviceStart.dart';
import 'package:paddy_rice/screen/device/deviceState.dart';
import 'package:paddy_rice/services/FCMTokenService.dart';
import 'package:paddy_rice/widgets/OkDialog.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:paddy_rice/widgets/model.dart';
import 'package:paddy_rice/widgets/ChoiceDialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paddy_rice/widgets/web_socket_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:paddy_rice/widgets/mqtt_client.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widgets/notification_state.dart';

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
  int deviceId = 0;
  double frontTemperature = 0.0;
  double rearTemperature = 0.0;
  double moisture = 0.0;
  late Timer _mqttTimeoutTimer;
  final int _mqttTimeoutDuration = 10;
  bool isDataReceived = false;
  // bool shouldShowNotification = false;
  Map<String, DeviceData> deviceDataMap = {};
  bool _isConnected = false;
  String _lastMessage = "ไม่มีข้อมูล";
  bool _isStopLoading = false;

  bool _isDrying = false;

  void _onDryingStarted() {
    setState(() {
      _isDrying = true;
    });
  }

  @override
  void initState() {
    super.initState();

    _mqttService = MQTTService();

    _initializeDevices();
    _connectAndListen();
    WidgetsBinding.instance.addObserver(this);

    _mqttService.connect().then((_) {
      _mqttService.listenToMessages((message) {
        setState(() {
          Map<String, dynamic> data = jsonDecode(message);
          print('--------------------------------------------------------');
          print('mqtt server: $data');

          int id = int.tryParse(data['device_id'].toString()) ?? -1;
          print('MQTT Device ID: $id');
          double frontTemp = data['front_temp']?.toDouble() ?? 0.0;
          double backTemp = data['back_temp']?.toDouble() ?? 0.0;
          double humidity = data['humidity']?.toDouble() ?? 0.0;

          int index = devices.indexWhere((device) {
            print(
                'Checking device ID: ${device.id} (Type: ${device.id.runtimeType}) against MQTT ID: $id (Type: ${id.runtimeType})'); // เพิ่ม Log
            return int.tryParse(device.id) == id;
          });
          print('Found Device Index: $index');
          if (index != -1) {
            devices[index].frontTemp = frontTemp;
            devices[index].backTemp = backTemp;
            devices[index].humidity = humidity;
            devices[index].status = true;

            double targetFront = devices[index].targetFrontTemp;
            double targetBack = devices[index].targetBackTemp;
            double targetHumidity = devices[index].targetHumidity;

            if (frontTemp > targetFront ||
                backTemp > targetBack ||
                humidity > targetHumidity) {
              print('device name: ${devices[index].name}');
              chackDeviceTargetValues(
                devices[index].id,
                devices[index].name,
                frontTemp,
                backTemp,
                humidity,
              );
            }
          }

          isDataReceived = true;
          _resetMqttTimeoutTimer();
          print("อัปเดตข้อมูลจาก MQTT");
          print("Front Temp: $frontTemp");
          print("Rear Temp: $backTemp");
          print("Moisture: $humidity");
        });
      });
    }).catchError((error) {
      print('Error connecting to MQTT: $error');
    });
    _startMqttTimeoutTimer();
  }

  void _connectAndListen() async {
    bool connected = await _mqttService.ensureConnected();

    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }

    if (connected) {
      _setupMessageListener();
    }
  }

  void _setupMessageListener() {
    _mqttService.listenToMessages((message) {
      if (mounted) {
        setState(() {
          _lastMessage = message;
        });
      }
    });
  }

  Future<void> _stopDryingProcess() async {
    setState(() {
      _isStopLoading = true;
    });

    final url = Uri.parse('${ApiConstants.baseUrl}/stop');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'deviceId': 1,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('Stop API call successful: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('หยุดการทำงานสำเร็จ')),
        );
      } else {
        print('Stop API call failed with status: ${response.statusCode}');
        print('Stop Response body: ${response.body}');
        // จัดการ response เมื่อหยุดไม่สำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการหยุด')),
        );
      }
    } catch (error) {
      print('Error during stop API call: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    } finally {
      setState(() {
        _isStopLoading = false;
      });
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connectAndListen();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    _deviceNameController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // _mqttService.disconnect();
    // _mqttTimeoutTimer.cancel();
    super.dispose();
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
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
          'deviceName': deviceName,
          'targetFrontTemp': targetFrontTemp,
          'targetBackTemp': targetBackTemp,
          'targetHumidity': targetHumidity,
        }),
      );
      print('DEVICE NAME: $deviceName');

      if (response.statusCode == 200) {
        print('Device updated successfully');
        setState(() {
          Provider.of<NotificationState>(context, listen: false)
              .showNotificationDot();
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

  // Future<void> _deleteDevice(String deviceId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final int? userId = prefs.getInt('userId');

  //   if (userId == null) {
  //     print('User ID not found, cannot update device.');
  //     return;
  //   }
  //   print('start delete device process');
  //   print('Device ID: $deviceId');
  //   print('User ID: $userId');
  //   final urlGetSerial = '${ApiConstants.baseUrl}/device/$deviceId/$userId';

  //   try {
  //     final responseGetSerial = await http.get(
  //       Uri.parse(urlGetSerial),
  //       headers: {'Content-Type': 'application/json'},
  //     );

  //     if (responseGetSerial.statusCode == 200) {
  //       print('Get Serial Number Response: ${responseGetSerial.body}');

  //       try {
  //         final Map<String, dynamic> responseData =
  //             jsonDecode(responseGetSerial.body);
  //         final String? serialNumber = responseData['serialNumber'];
  //         if (serialNumber != null) {
  //           print('Serial Number from API: $serialNumber');
  //           final urlUpdate =
  //               '${ApiConstants.baseUrl}/devices/userID/serialNumber/update';
  //           final responseUpdate = await http.put(
  //             Uri.parse(urlUpdate),
  //             headers: {'Content-Type': 'application/json'},
  //             body: jsonEncode({
  //               'userId': null,
  //               'serialNumber': serialNumber,
  //             }),
  //           );
  //           print(
  //               'Update Response: ${responseUpdate.statusCode} - ${responseUpdate.body}');
  //           if (responseUpdate.statusCode == 200) {
  //             showDialog(
  //               context: context,
  //               builder: (BuildContext context) {
  //                 return OkDialog(
  //                   title: 'สำเร็จ',
  //                   content: 'ยกเลิกการเชื่อมต่ออุปกรณ์สำเร็จ',
  //                   parentContext: context,
  //                   confirmButtonText: 'ตกลง',
  //                   cancelButtonText: '',
  //                   onConfirm: () {
  //                     Navigator.of(context).pop();
  //                     _initializeDevices();
  //                   },
  //                 );
  //               },
  //             );
  //           } else {
  //             print(
  //                 'Failed to update device user: ${responseUpdate.statusCode} - ${responseUpdate.body}');
  //           }
  //         } else {
  //           print('Serial Number not found in the get response.');
  //         }
  //       } catch (e) {
  //         print('Error decoding JSON for serial number: $e');
  //       }
  //     } else if (responseGetSerial.statusCode == 404) {
  //       print("Device not found to get serial number.");
  //     } else {
  //       print(
  //           'Failed to get serial number: ${responseGetSerial.statusCode} - ${responseGetSerial.body}');
  //     }
  //   } catch (e) {
  //     print('Error during get serial number request: $e');
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return OkDialog(
  //           title: 'ข้อผิดพลาด',
  //           content: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
  //           parentContext: context,
  //           confirmButtonText: 'ตกลง',
  //           cancelButtonText: '',
  //           onConfirm: () {
  //             Navigator.of(context).pop();
  //           },
  //         );
  //       },
  //     );
  //   }
  // }

  // void _showDeleteConfirmationDialog(Device device) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('ยืนยันการยกเลิก'),
  //         content: Text(
  //             'คุณต้องการยกเลิกการเชื่อมต่ออุปกรณ์ "${device.name}" (ID: ${device.id}) หรือไม่?'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text('ยกเลิก'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               _deleteDevice(device.id);
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('ยืนยัน'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = S.of(context);
    MenuItems.init(context);

    final notificationState = Provider.of<NotificationState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor,
        title: Text(localizations!.title, style: appBarFont),
        actions: [
          Consumer<NotificationState>(
            builder: (context, notificationState, child) {
              return IconButton(
                onPressed: () {
                  context.router.replaceNamed('/notifi');
                },
                icon: Stack(
                  children: <Widget>[
                    Icon(
                      Icons.notifications_outlined,
                      size: 24,
                      color: iconcolor,
                    ),
                    if (notificationState.shouldShowNotification)
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
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                customButton: Icon(Icons.more_vert, size: 24, color: iconcolor),
                items: [
                  ...MenuItems.firstItems
                      .map((item) => DropdownMenuItem<MenuItem>(
                            value: item,
                            child: MenuItems.buildItem(item),
                          )),
                ],
                onChanged: (value) {
                  final menuItem = value as MenuItem;
                  if (menuItem.text == localizations.add_device) {
                    context.router.replaceNamed('/addSerial');
                  } else if (menuItem.text == localizations.scan) {
                    context.router.replaceNamed('/scan');
                  }
                },
                dropdownStyleData: DropdownStyleData(
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: fill_color,
                  ),
                  offset: const Offset(-144, 8),
                ),
                menuItemStyleData: MenuItemStyleData(
                  customHeights: [
                    ...List<double>.filled(MenuItems.firstItems.length, 48),
                  ],
                  padding: const EdgeInsets.only(left: 16, right: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: maincolor,
      body: Stack(
        children: [
          DecoratedImage(),
          Center(
            child: Column(
              children: [
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
      child: ListView.builder(
        itemCount: devices.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final device = devices[index];
          return Padding(
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
                          builder: (context) => DeviceSateRoute(device: device),
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
                  SlidableAction(
                    onPressed: (context) {
                      setState(() {
                        _isDrying = !_isDrying;
                      });

                      if (!_isDrying) {
                        _stopDryingProcess();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DevicestartRoute()),
                        );
                      }
                    },
                    backgroundColor: _isDrying ? Colors.red : startSystem,
                    foregroundColor: fill_color,
                    icon: _isDrying ? Icons.stop : Icons.power_settings_new,
                  ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.thermostat_outlined,
                                  size: 24,
                                  color: frontTemp,
                                ),
                                Text(
                                  localizations.temp_front,
                                  style: TextStyle(
                                      fontSize: 12, color: unnecessary_colors),
                                ),
                                Text(
                                  '${device.frontTemp.toStringAsFixed(1)} °C',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: frontTemp),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.thermostat_outlined,
                                  size: 24,
                                  color: backTemp,
                                ),
                                Text(
                                  localizations.temp_back,
                                  style: TextStyle(
                                      fontSize: 12, color: unnecessary_colors),
                                ),
                                Text(
                                  '${device.backTemp.toStringAsFixed(1)} °C',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: backTemp),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.water_drop_outlined,
                                  size: 24,
                                  color: humidity,
                                ),
                                Text(
                                  localizations.humidity_,
                                  style: TextStyle(
                                      fontSize: 12, color: unnecessary_colors),
                                ),
                                Text(
                                  '${device.humidity.toStringAsFixed(2)} %',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: humidity),
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
          );
        },
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
    devices = MenuItem(text: localizations.add_device, icon: Icons.power_sharp);
    scan_qr = MenuItem(text: localizations.scan, icon: Icons.qr_code_scanner);

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
