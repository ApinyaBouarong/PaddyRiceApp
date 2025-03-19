import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_text_field_no_icon.dart';
import 'package:http/http.dart' as http;
import 'package:paddy_rice/constants/api.dart';

@RoutePage()
class ChangePassword_profileRoute extends StatefulWidget {
  @override
  _ChangePassword_profileRouteState createState() =>
      _ChangePassword_profileRouteState();
}

class _ChangePassword_profileRouteState
    extends State<ChangePassword_profileRoute> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  // ตัวแปรใหม่สำหรับจัดการข้อผิดพลาดของแต่ละช่อง
  bool _isCurrentPasswordError = false;
  bool _isNewPasswordError = false;
  bool _isConfirmPasswordError = false;

  String _currentPasswordErrorMessage = '';
  String _newPasswordErrorMessage = '';
  String _confirmPasswordErrorMessage = '';

  bool isLoading = false;

  // ฟังก์ชันดึงข้อมูลโปรไฟล์จาก API
  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    print('User ID: $userId');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    await http.get(Uri.parse('${ApiConstants.baseUrl}/profile/$userId'));
  }

  // ฟังก์ชันเปลี่ยนรหัสผ่าน
  Future<void> changePassword(
      BuildContext context, String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      print('User not found');
    } else {
      print('User ID: $userId');
    }
    if (userId == null) {
      setState(() {
        _isCurrentPasswordError = true;
        _currentPasswordErrorMessage = "User ID not found";
      });
      return;
    }

    final url = '${ApiConstants.baseUrl}/change-password';

    // สร้าง body ที่จะส่งไปให้ back-end
    final body = jsonEncode({
      'userId': userId.toString(),
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

    // ส่ง request ไปยัง server
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    // แสดง response body เพื่อช่วย debug
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    // ตรวจสอบผลลัพธ์จาก server
    if (response.statusCode == 200) {
      print('Error: ${response.body}');
      setState(() {
        // การเปลี่ยนรหัสผ่านสำเร็จ
        _isCurrentPasswordError = false;
        _currentPasswordErrorMessage = '';
        _isNewPasswordError = false;
        _newPasswordErrorMessage = '';
        _isConfirmPasswordError = false;
        _confirmPasswordErrorMessage = '';
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ShDialog(
            title: S.of(context)!.password_changed,
            content: S.of(context)!.password_changed_success,
            parentContext: context,
            confirmButtonText: S.of(context)!.ok,
            onConfirm: () {
              Navigator.of(context).pop();
              context.router.replace(BottomNavigationRoute(page: 1));
            },
          );
        },
      );
    } else {
      final responseBody = jsonDecode(response.body);
      setState(() {
        _isCurrentPasswordError = true;
        _currentPasswordErrorMessage =
            responseBody["message"] ?? 'Unknown error';
      });
    }
  }

  // ฟังก์ชันสำหรับการตรวจสอบรหัสผ่าน
  Future<void> _validatePasswords(BuildContext context) async {
    setState(() {
      _isCurrentPasswordError = false;
      _isNewPasswordError = false;
      _isConfirmPasswordError = false;
      _currentPasswordErrorMessage = '';
      _newPasswordErrorMessage = '';
      _confirmPasswordErrorMessage = '';
      isLoading = true;
    });

    if (_currentPasswordController.text.isEmpty) {
      setState(() {
        _isCurrentPasswordError = true;
        _currentPasswordErrorMessage = S.of(context)!.error_current_password;
        isLoading = false;
      });
    } else if (_newPasswordController.text.isEmpty) {
      setState(() {
        _isNewPasswordError = true;
        _newPasswordErrorMessage = S.of(context)!.error_new_password;
        isLoading = false;
      });
    } else if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _isConfirmPasswordError = true;
        _confirmPasswordErrorMessage = S.of(context)!.error_new_password;
        isLoading = false;
      });
    } else if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _isNewPasswordError = true;
        _newPasswordErrorMessage = S.of(context)!.error_passwords_do_not_match;
        _isConfirmPasswordError = true;
        _confirmPasswordErrorMessage =
            S.of(context)!.error_passwords_do_not_match;
        isLoading = false;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) {
        setState(() {
          _isCurrentPasswordError = true;
          _currentPasswordErrorMessage = "User ID not found";
          isLoading = false;
        });
        return;
      }

      await changePassword(
        context,
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: iconcolor,
          ),
          onPressed: () =>
              context.router.replace(BottomNavigationRoute(page: 1)),
        ),
        title: Text(
          S.of(context)!.change_password,
          style: appBarFont,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          DecoratedImage(),
          Column(
            children: [
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    // แสดงเฉพาะข้อผิดพลาดของ Current Password
                    TextFieldCustom(
                      controller: _currentPasswordController,
                      labelText: S.of(context)!.current_password,
                      suffixIcon: _isCurrentPasswordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                      obscureText: _isCurrentPasswordObscured,
                      onSuffixIconPressed: () {
                        setState(() {
                          _isCurrentPasswordObscured =
                              !_isCurrentPasswordObscured;
                        });
                      },
                      isError: _isCurrentPasswordError,
                      errorMessage: _currentPasswordErrorMessage,
                    ),
                    const SizedBox(height: 20),
                    // แสดงเฉพาะข้อผิดพลาดของ New Password
                    TextFieldCustom(
                      controller: _newPasswordController,
                      labelText: S.of(context)!.new_password,
                      suffixIcon: _isNewPasswordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                      obscureText: _isNewPasswordObscured,
                      onSuffixIconPressed: () {
                        setState(() {
                          _isNewPasswordObscured = !_isNewPasswordObscured;
                        });
                      },
                      isError: _isNewPasswordError,
                      errorMessage: _newPasswordErrorMessage,
                    ),
                    SizedBox(height: 20),
                    // แสดงเฉพาะข้อผิดพลาดของ Confirm Password
                    TextFieldCustom(
                      controller: _confirmPasswordController,
                      labelText: S.of(context)!.confirm_new_password,
                      suffixIcon: _isConfirmPasswordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                      obscureText: _isConfirmPasswordObscured,
                      onSuffixIconPressed: () {
                        setState(() {
                          _isConfirmPasswordObscured =
                              !_isConfirmPasswordObscured;
                        });
                      },
                      isError: _isConfirmPasswordError,
                      errorMessage: _confirmPasswordErrorMessage,
                    ),
                    SizedBox(height: 4.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: TextButton(
                          onPressed: () =>
                              context.router.replaceNamed('/forgot_profile'),
                          child: Text(
                            S.of(context)!.forgot_password,
                            style: TextStyle(
                                color: unnecessary_colors, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    CustomButton(
                      text: S.of(context)!.reset_password,
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });

                        await _validatePasswords(context);

                        setState(() {
                          isLoading = false;
                        });
                      },
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShDialog extends StatelessWidget {
  final String title;
  final String content;
  final BuildContext parentContext;
  final String confirmButtonText;
  final VoidCallback onConfirm;

  ShDialog({
    required this.title,
    required this.content,
    required this.parentContext,
    required this.confirmButtonText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(16.0),
        ),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: fill_color,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: fontcolor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              content,
              style: TextStyle(
                color: fontcolor,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // ทำให้ปุ่มอยู่ตรงกลาง
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttoncolor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Text(
                  confirmButtonText,
                  style: TextStyle(
                    color: fontcolor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
