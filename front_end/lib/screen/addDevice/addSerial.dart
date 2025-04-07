import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paddy_rice/widgets/custom_button.dart'; // สมมติว่าคุณมี CustomButton

@RoutePage()
class AddSerialRoute extends StatefulWidget {
  @override
  _AddSerialRouteState createState() => _AddSerialRouteState();
}

class _AddSerialRouteState extends State<AddSerialRoute> {
  final TextEditingController _serialNumberController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

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
        print('Check Serial Response: ${response.body}');
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
    print('serialNumber: $serialNumber, userId: $userId');
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/devices/userID/serialNumber/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'serialNumber': serialNumber,
        }),
      );
      print('Start assigning user to device...');
      if (response.statusCode == 200) {
        print('User assigned to device successfully!');
        if (json.decode(response.body)['status'] == 'success') {
          _serialNumberController.clear();
          context.router.replaceNamed('/home');
        }
        _showSuccessSnackBar('Device assigned to user successfully!');
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
    print('User ID: ${prefs.getInt('userId')}');
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

  void _handleAddSerial() async {
    setState(() {
      _errorMessage = null;
    });
    final serialNumber = _serialNumberController.text.trim();
    print('Serial Number: $serialNumber');
    if (serialNumber.isNotEmpty) {
      final deviceInfo = await _checkSerialExists(serialNumber);
      if (deviceInfo != null) {
        if (deviceInfo['user_id'] == null) {
          final userId = await _fetchUserId();
          if (userId != null) {
            await _assignUserToDevice(serialNumber, userId);
          } else {
            _showErrorSnackBar('User ID not found. Please login again.');
          }
        } else {
          _showDeviceAlreadyAssignedDialog(context);
        }
      } else {
        _showErrorSnackBar('Serial number not found.');
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter a serial number.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor,
        title: Text(
          "Add Serial Number",
          style: appBarFont,
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.router.replaceNamed('/bottom_navigation'),
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
      ),
      backgroundColor: maincolor,
      body: Stack(
        children: [
          DecoratedImage(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFieldCustom(
                    controller: _serialNumberController,
                    labelText: "Serial Number",
                    suffixIcon: Icons.qr_code_scanner,
                    isError: _errorMessage != null,
                    errorMessage: _errorMessage ?? "",
                    onSuffixIconPressed: () {
                      context.router.replaceNamed('/scan');
                    },
                  ),
                  SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttoncolor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(312, 48),
                        ),
                        onPressed: _isLoading ? null : _handleAddSerial,
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            color: fontcolor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
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
    return Container(
      width: 312,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            validator: widget.validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: fill_color,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              suffixIcon: (_isFocused)
                  ? IconButton(
                      icon: Icon(widget.suffixIcon, color: iconcolor),
                      onPressed: widget.onSuffixIconPressed,
                    )
                  : null,
              labelText: widget.labelText,
              labelStyle: TextStyle(
                color: _isFocused
                    ? focusedBorder_color
                    : widget.isError
                        ? error_color
                        : unnecessary_colors,
                fontSize: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.isError ? error_color : fill_color,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: focusedBorder_color, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: error_color, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: error_color, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (widget.isError)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 16.0),
              child: Text(
                widget.errorMessage,
                style: errorFont,
              ),
            ),
        ],
      ),
    );
  }
}
