import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/constants/api.dart'; // Import ApiConstants
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:http/http.dart' as http; // Import http

@RoutePage()
class ScanRoute extends StatefulWidget {
  const ScanRoute({Key? key}) : super(key: key);

  @override
  _ScanRouteState createState() => _ScanRouteState();
}

class _ScanRouteState extends State<ScanRoute> {
  bool _torchIsOn = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  String? scannedValue;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {}
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _checkSerialExists(String serialNumber) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/devices/$serialNumber'),
      );
      if (response.statusCode == 200) {
        print('Check Serial Response (Scan): ${response.body}');
        final responseData = json.decode(response.body);
        if (responseData.containsKey('device') &&
            responseData['device'].containsKey('user_id')) {
          return responseData['device'];
        } else {
          _showErrorSnackBar('Invalid response format for device info.');
          return null;
        }
      } else if (response.statusCode == 404) {
        return null; // ไม่พบอุปกรณ์
      } else {
        _showErrorSnackBar(
            'Failed to check serial number. Status: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      _showErrorSnackBar('Network error: $error');
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _assignUserToDevice(String serialNumber, int userId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/devices/userID/serialNumber/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'serialNumber': serialNumber,
        }),
      );
      print('Assign User Response (Scan): ${response.body}');
      if (response.statusCode == 200) {
        print('Device assigned to user successfully (Scan)!');
        _showSuccessSnackBar('Device assigned successfully!');
        context.router.replaceNamed('/home');
      } else {
        _showErrorSnackBar(
            'Failed to assign user to device. Status: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorSnackBar('Network error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int?> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  void _showErrorSnackBar(String message) {
    final snackBar =
        SnackBar(content: Text(message), backgroundColor: error_color);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessSnackBar(String message) {
    final snackBar =
        SnackBar(content: Text(message), backgroundColor: Colors.green);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showDeviceAlreadyAssignedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("ไม่สามารถเพิ่มอุปกรณ์"),
          content: Text("อุปกรณ์ Serial Number นี้ถูกใช้งานโดยผู้ใช้อื่นแล้ว"),
          actions: <Widget>[
            TextButton(
              child: Text("ตกลง"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleScannedValue(String value) async {
    setState(() {
      scannedValue = value;
    });
    print('Scanned Value Handled: $scannedValue');
    final deviceInfo = await _checkSerialExists(scannedValue!);
    if (deviceInfo != null) {
      if (deviceInfo['user_id'] == null) {
        final userId = await _fetchUserId();
        if (userId != null) {
          await _assignUserToDevice(scannedValue!, userId);
        } else {
          _showErrorSnackBar('User ID not found. Please login again.');
        }
      } else {
        _showDeviceAlreadyAssignedDialog(context);
      }
    } else {
      _showErrorSnackBar('Serial number not found.');
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (result?.code != null) {
          controller.pauseCamera(); // หยุดการสแกนเมื่อเจอ QR Code แล้ว
          _handleScannedValue(result!.code!);
        }
      });
    });
  }

  void _openGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Selected image path: ${image.path}');
      // You might need a plugin to decode QR codes from images.
      // Consider using 'qr_code_scanner_plus' with image decoding capabilities
      // or another plugin like 'image_cropper' and 'scan'.
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await controller?.toggleFlash();
      setState(() {
        _torchIsOn = !_torchIsOn;
      });
    } on Exception catch (e) {
      print('Could not toggle torch: $e');
      _showErrorSnackBar('Could not toggle torch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      body: Stack(
        children: [
          Container(
            color: maincolor,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: iconcolor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
                overlayColor: maincolor.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () =>
                    context.router.replaceNamed('/bottom_navigation'),
                icon: Icon(Icons.arrow_back, color: iconcolor),
              ),
              title: Text(
                S.of(context)!.scan,
                style: appBarFont,
              ),
              centerTitle: true,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 376.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.router.replaceNamed('/addSerial');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: fontcolor,
                      backgroundColor: buttoncolor,
                    ),
                    child: Text(
                      S.of(context)!.no_qr_code,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  if (_isLoading) // แสดง CircularProgressIndicator เมื่อกำลังโหลด
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  if (_errorMessage != null) // แสดงข้อผิดพลาดถ้ามี
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: error_color),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () => _openGallery(context),
                  child: Icon(Icons.image_search_outlined),
                  backgroundColor: buttoncolor,
                ),
                FloatingActionButton(
                  onPressed: _toggleTorch,
                  child: Icon(
                    _torchIsOn
                        ? Icons.flashlight_off_outlined
                        : Icons.flashlight_on_outlined,
                  ),
                  backgroundColor: buttoncolor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
