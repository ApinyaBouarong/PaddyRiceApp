import 'dart:async';
import 'dart:convert'; // For JSON encoding
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/OkDialog.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:paddy_rice/widgets/model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http; // HTTP package for API calls
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/widgets/mqtt_client.dart';
import 'package:paddy_rice/widgets/web_socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/shDialog.dart'; // Assuming you have API constants

class DeviceSateRoute extends StatefulWidget {
  final Device device;

  DeviceSateRoute({required this.device});

  @override
  _DeviceSateRouteState createState() => _DeviceSateRouteState();
}

class _DeviceSateRouteState extends State<DeviceSateRoute> {
  late WebSocketService _webSocketService;
  late MQTTService _mqttService;
  late String deviceName;
  double frontTemperature = 0.0;
  double rearTemperature = 0.0;
  double moisture = 0.0;
  late double targetFrontTemp;
  late double targetBackTemp;
  late double targetHumidity;
  String selectedTempType = 'Front';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _frontTempController = TextEditingController();
  final TextEditingController _backTempController = TextEditingController();
  final TextEditingController _humidityStartController =
      TextEditingController();

  List<Device> devices = [];
  bool _isDeviceNameError = false;
  bool _isTempChanged = false;
  bool _isButtonEnabled = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTargetValues();
    _initializeDevices();
    _mqttService = MQTTService();
    deviceName = widget.device.name;
    _deviceNameController.text = deviceName;
    frontTemperature = widget.device.frontTemp;
    rearTemperature = widget.device.backTemp;
    moisture = widget.device.humidity;
    targetFrontTemp = widget.device.targetFrontTemp ?? 0.0;
    targetBackTemp = widget.device.targetBackTemp ?? 0.0;
    targetHumidity = widget.device.targetHumidity ?? 0.0;

    _mqttService.connect().then((_) {
      _mqttService.listenToMessages((message) {
        setState(() {
          Map<String, dynamic> data = jsonDecode(message);
          print('--------------------------------------------------------');
          print('mqtt server: $data');

          int mqttDeviceId = int.tryParse(data['device_id'].toString()) ?? -1;
          int currentDeviceId =
              int.tryParse(widget.device.id) ?? -1; // Get current device ID

          print('MQTT Device ID: $mqttDeviceId');
          print('Current Screen Device ID: $currentDeviceId');

          // Check if the MQTT message is for the current device
          if (mqttDeviceId == currentDeviceId) {
            double frontTemp = data['front_temp']?.toDouble() ?? 0.0;
            double backTemp = data['back_temp']?.toDouble() ?? 0.0;
            double humidity = data['humidity']?.toDouble() ?? 0.0;

            frontTemperature = frontTemp;
            rearTemperature = backTemp;
            moisture = humidity;

            // อัปเดต target values ใน devices list ด้วย (ถ้าต้องการให้ list นี้อัปเดตด้วย)
            int index = devices.indexWhere(
                (device) => int.tryParse(device.id) == currentDeviceId);
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
                chackDeviceTargetValues(
                  devices[index].id,
                  devices[index].name,
                  frontTemp,
                  backTemp,
                  humidity,
                );
              }
            }

            print("อัปเดตข้อมูลจาก MQTT สำหรับ Device ID: $currentDeviceId");
            print("Front Temp: $frontTemp");
            print("Rear Temp: $backTemp");
            print("Moisture: $humidity");
          } else {
            print(
                "ข้อมูล MQTT (Device ID: $mqttDeviceId) ไม่ตรงกับ Device ID ปัจจุบัน: $currentDeviceId");
          }
        });
      });
    }).catchError((error) {
      print('Error connecting to MQTT: $error');
    });
    _webSocketService = WebSocketService();
    _webSocketService.connectToDevice(widget.device.id, (data) {
      setState(() {
        Map<String, dynamic> parsedData = jsonDecode(data);
        frontTemperature =
            parsedData['front_temperature']?.toDouble() ?? frontTemperature;
        rearTemperature =
            parsedData['rear_temperature']?.toDouble() ?? rearTemperature;
        moisture = parsedData['moisture']?.toDouble() ?? moisture;
      });
    });
  }

  Future<void> fetchTargetValues() async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}/devices/${widget.device.id}/target-values');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          deviceName = data['device_name'] ?? 'Unknown Device';
          targetFrontTemp = data['target_front_temp']?.toDouble() ?? 0.0;
          targetBackTemp = data['target_back_temp']?.toDouble() ?? 0.0;
          targetHumidity = data['target_humidity']?.toDouble() ?? 0.0;
        });
        print("Device Name: $deviceName");
        print("Front Temp: $targetFrontTemp");
        print("Rear Temp: $targetBackTemp");
        print("Moisture: $targetHumidity");
      }
    } catch (e) {
      print('Error fetching target values: $e');
    }
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
      } else {
        print('Failed to update device: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating device: $e');
    }
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

  Future<void> updateDeviceTargetValues() async {
    print("device id: ${widget.device.id}");
    print("device name: ${_deviceNameController.text}");
    print("target front temp: $targetFrontTemp");
    print("target back temp: $targetBackTemp");
    print("target humidity: $targetHumidity");
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse('${ApiConstants.baseUrl}/update-device');
    final body = jsonEncode({
      'deviceId': widget.device.id,
      'deviceName': _deviceNameController.text,
      'targetFrontTemp': targetFrontTemp,
      'targetBackTemp': targetBackTemp,
      'targetHumidity': targetHumidity,
    });

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //       content: Text("Updated Successfully"),
        //       backgroundColor: Colors.green),
        // );
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return OkDialog(
              title: S.of(context)!.success,
              content: S.of(context)!.updated_Successfully,
              parentContext: context,
              confirmButtonText: S.of(context)!.ok,
              cancelButtonText: S.of(context)!.cancel,
              onConfirm: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        // await fetchTargetValues();
        setState(() {
          deviceName = _deviceNameController.text;
          isLoading = false;
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return OkDialog(
              title: S.of(context)!.error,
              content: S.of(context)!.failed_update_target,
              parentContext: context,
              confirmButtonText: S.of(context)!.ok,
              cancelButtonText: S.of(context)!.cancel,
              onConfirm: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error updating target values: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    _webSocketService.disconnectFromDevice(widget.device.id);
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      // Enable the button if either the device name or target values change
      _isButtonEnabled = (_deviceNameController.text != widget.device.name ||
          targetFrontTemp != widget.device.targetFrontTemp ||
          targetBackTemp != widget.device.targetBackTemp ||
          targetHumidity != widget.device.targetHumidity);
    });
  }

  // void _showDeleteConfirmationDialog(Device device) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.transparent,
  //         title: Text(S.of(context)!.delete_confirmation),
  //         content: Text(
  //             'คุณต้องการยกเลิกการเชื่อมต่ออุปกรณ์ "${device.name}" (ID: ${device.id}) หรือไม่?'),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text(S.of(context)!.cancel),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               _deleteDevice(device.id);
  //               Navigator.of(context).pop();
  //             },
  //             child: Text(S.of(context)!.ok),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showDeleteConfirmationDialog(Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: S.of(context)!.delete_confirmation,
          content: S
              .of(context)!
              .doYouWantToDisconnectTheDevice(device.name, device.id),
          parentContext: context,
          confirmButtonText: S.of(context)!.ok,
          cancelButtonText: S.of(context)!.cancel,
          onConfirm: () {
            _deleteDevice(device.id);
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _deleteDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (userId == null) {
      print('User ID not found, cannot update device.');
      return;
    }
    print('start delete device process');
    print('Device ID: $deviceId');
    print('User ID: $userId');
    final urlGetSerial = '${ApiConstants.baseUrl}/device/$deviceId/$userId';

    try {
      final responseGetSerial = await http.get(
        Uri.parse(urlGetSerial),
        headers: {'Content-Type': 'application/json'},
      );

      if (responseGetSerial.statusCode == 200) {
        print('Get Serial Number Response: ${responseGetSerial.body}');

        try {
          final Map<String, dynamic> responseData =
              jsonDecode(responseGetSerial.body);
          final String? serialNumber = responseData['serialNumber'];
          if (serialNumber != null) {
            print('Serial Number from API: $serialNumber');
            final urlUpdate =
                '${ApiConstants.baseUrl}/devices/userID/serialNumber/update';
            final responseUpdate = await http.put(
              Uri.parse(urlUpdate),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'userId': null,
                'serialNumber': serialNumber,
              }),
            );
            print(
                'Update Response: ${responseUpdate.statusCode} - ${responseUpdate.body}');
            if (responseUpdate.statusCode == 200) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return OkDialog(
                    title: S.of(context)!.success,
                    content: S.of(context)!.deviceDisconnect,
                    parentContext: context,
                    confirmButtonText: S.of(context)!.ok,
                    cancelButtonText: '',
                    onConfirm: () {
                      Navigator.of(context).pop();
                      _initializeDevices();
                      Navigator.of(context).pop(true);
                    },
                  );
                },
              );
            } else {
              print(
                  'Failed to update device user: ${responseUpdate.statusCode} - ${responseUpdate.body}');
            }
          } else {
            print('Serial Number not found in the get response.');
          }
        } catch (e) {
          print('Error decoding JSON for serial number: $e');
        }
      } else if (responseGetSerial.statusCode == 404) {
        print("Device not found to get serial number.");
      } else {
        print(
            'Failed to get serial number: ${responseGetSerial.statusCode} - ${responseGetSerial.body}');
      }
    } catch (e) {
      print('Error during get serial number request: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return OkDialog(
            title: 'ข้อผิดพลาด',
            content: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
            parentContext: context,
            confirmButtonText: 'ตกลง',
            cancelButtonText: '',
            onConfirm: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
    }
  }

  Future<void> showTempDialog(BuildContext context, String tempType) async {
    double targetValue = (tempType == S.of(context)!.temp_front)
        ? targetFrontTemp
        : (tempType == S.of(context)!.temp_back)
            ? targetBackTemp
            : targetHumidity;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      S.of(context)!.setting,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: fontcolor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context)!.adjust_temp_type(
                          tempType, (tempType == 'Humidity') ? '%' : '°C'),
                      style: TextStyle(color: unnecessary_colors),
                    ),

                    const SizedBox(height: 20),

                    // Use NumberPicker for adjusting temperature
                    NumberPicker(
                      value: targetValue.toInt(),
                      minValue: 0,
                      maxValue: 200, // Set max value as needed
                      step: 1,
                      haptics: true,
                      textStyle: TextStyle(
                        fontSize: 22,
                        color: unnecessary_colors,
                      ),
                      selectedTextStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: fontcolor,
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          targetValue = value.toDouble();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        // Update the target value and close the dialog
                        setState(() {
                          if (tempType == S.of(context)!.temp_front) {
                            targetFrontTemp = targetValue;
                          } else if (tempType == S.of(context)!.temp_back) {
                            targetBackTemp = targetValue;
                          } else if (tempType == S.of(context)!.humidity_) {
                            targetHumidity = targetValue;
                          }
                          _updateButtonState();
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttoncolor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      child: Text(S.of(context)!.save,
                          style: TextStyle(
                              color: iconcolor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return true;
      },
      child: Scaffold(
        backgroundColor: maincolor,
        appBar: AppBar(
          backgroundColor: maincolor,
          title: Text(
            S.of(context)!.device_settings(deviceName),
            style: appBarFont,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.delete, color: error_color),
              onPressed: () => _showDeleteConfirmationDialog(widget.device),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            DecoratedImage(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: fontcolor,
                    fontSize: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        TextFieldCustom(
                          controller: _deviceNameController,
                          labelText: S.of(context)!.device_name,
                          suffixIcon: Icons.clear,
                          isError: _isDeviceNameError,
                          errorMessage: S.of(context)!.field_required,
                          onSuffixIconPressed: () {
                            _deviceNameController.clear();
                          },
                          onChanged: (value) {
                            setState(() {
                              // deviceName = value;
                              _isDeviceNameError = value.isEmpty;
                              _updateButtonState();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          label: S.of(context)!.front_temperature,
                          currentValue: frontTemperature,
                          targetValue: targetFrontTemp,
                          unit: '°C',
                          imagePath: 'lib/assets/icon/Temp.jpg',
                          labelBackgroundColor:
                              const Color.fromRGBO(175, 160, 142, 1),
                          labelTextColor: fill_color,
                          imageWidth: 10,
                          imageHeight: 10,
                          onEditPressed: () => showTempDialog(
                              context, S.of(context)!.temp_front),
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          label: S.of(context)!.back_temperature,
                          currentValue: rearTemperature,
                          targetValue: targetBackTemp,
                          unit: '°C',
                          imagePath: 'lib/assets/icon/Temp.jpg',
                          labelBackgroundColor:
                              const Color.fromRGBO(175, 160, 142, 1),
                          labelTextColor: fill_color,
                          imageWidth: 10,
                          imageHeight: 10,
                          onEditPressed: () =>
                              showTempDialog(context, S.of(context)!.temp_back),
                        ),
                        const SizedBox(height: 16),
                        InfoRow(
                          label: S.of(context)!.humidity_,
                          currentValue: moisture,
                          targetValue: targetHumidity,
                          unit: '%',
                          imagePath: 'lib/assets/icon/Humidity.jpg',
                          labelBackgroundColor:
                              const Color.fromRGBO(157, 186, 193, 1),
                          labelTextColor: fill_color,
                          imageWidth: 10,
                          imageHeight: 10,
                          onEditPressed: () =>
                              showTempDialog(context, S.of(context)!.humidity_),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: S.of(context)!.saveSetting,
                          onPressed: () async {
                            await updateDeviceTargetValues();
                            await fetchTargetValues();
                          },
                          isLoading: isLoading,
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

class InfoRow extends StatelessWidget {
  final String label;
  final double currentValue;
  final double targetValue;
  final String unit;
  final String imagePath;
  final Color labelBackgroundColor;
  final Color labelTextColor;
  final double imageWidth;
  final double imageHeight;
  final VoidCallback onEditPressed;

  InfoRow({
    required this.label,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.imagePath,
    required this.labelBackgroundColor,
    required this.labelTextColor,
    required this.onEditPressed,
    this.imageWidth = 140,
    this.imageHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          width: 312,
          decoration: BoxDecoration(
            color: fill_color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    imagePath,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: labelBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: labelTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Align values right
                    children: [
                      Text(
                        S.of(context)!.current,
                        style:
                            TextStyle(fontSize: 18, color: unnecessary_colors),
                      ),
                      Text(
                        '$currentValue $unit',
                        style: TextStyle(fontSize: 18, color: iconcolor),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context)!.target,
                        style:
                            TextStyle(fontSize: 18, color: unnecessary_colors),
                      ),
                      Text(
                        '$targetValue $unit',
                        style: TextStyle(fontSize: 18, color: iconcolor),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextFieldCustom extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData suffixIcon;
  final bool obscureText;
  final bool isError;
  final String errorMessage;
  final void Function()? onSuffixIconPressed;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  TextFieldCustom({
    required this.controller,
    required this.labelText,
    required this.suffixIcon,
    this.obscureText = false,
    required this.isError,
    required this.errorMessage,
    this.onSuffixIconPressed,
    this.validator,
    this.onChanged,
  });

  @override
  _TextFieldCustomState createState() => _TextFieldCustomState();
}

class _TextFieldCustomState extends State<TextFieldCustom> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTextChange() {
    setState(() {
      _hasText = widget.controller.text.isNotEmpty;
      widget.onChanged?.call(widget.controller.text);
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 312,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: fill_color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isFocused ? iconcolor : fill_color),
          ),
          child: Row(
            children: [
              Text(
                widget.labelText + " : ",
                style: TextStyle(
                  fontSize: 16,
                  color: unnecessary_colors,
                ),
              ),
              Expanded(
                child: TextFormField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  validator: widget.validator,
                  style: TextStyle(color: iconcolor, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    suffixIcon: (_isFocused || _hasText)
                        ? IconButton(
                            icon: Icon(widget.suffixIcon,
                                color: unnecessary_colors),
                            onPressed: widget.onSuffixIconPressed,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.isError)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
            child: Text(
              widget.errorMessage,
              style: TextStyle(color: error_color, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
