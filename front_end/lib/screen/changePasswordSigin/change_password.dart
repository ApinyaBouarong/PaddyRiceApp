import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/custom_text_field_no_icon.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class ChangePasswordRoute extends StatefulWidget {
  const ChangePasswordRoute({Key? key}) : super(key: key);

  @override
  _ChangePasswordRouteState createState() => _ChangePasswordRouteState();
}

class _ChangePasswordRouteState extends State<ChangePasswordRoute> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool isLoading = false;
  String? _newPasswordError;
  String? _confirmPasswordError;

  // ฟังก์ชันดึง userId จาก SharedPreferences
  Future<int?> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      print('User ID: $userId');
      return userId; // ส่งคืน userId ที่ดึงได้
    } else {
      print('User ID not found');
      _showErrorSnackBar('User ID not found');
      return null;
    }
  }

  // ฟังก์ชันเปลี่ยนรหัสผ่านโดยเรียก API
  Future<void> changePassword(String userId, String newPassword) async {
    final response = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/change_password'), // เปลี่ยน URL ตามจริง
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userId': userId, // ใช้ userId ของผู้ใช้จริง
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      print('Password changed successfully');
      // เปลี่ยนไปหน้า LoginRoute ถ้าเปลี่ยนรหัสผ่านสำเร็จ
      context.router.replaceAll([LoginRoute()]);
    } else {
      print('Failed to change password');
      _showErrorSnackBar('Failed to change password');
    }
  }

  // ฟังก์ชันแสดง error message ผ่าน SnackBar
  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: error_color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ฟังก์ชัน validate และส่งรหัสผ่านใหม่ไปยัง backend
  Future<void> _validateAndProceed() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      // ดึง userId จาก SharedPreferences
      final userId = await _fetchUserId();
      if (userId != null) {
        // ส่ง userId และรหัสผ่านใหม่ไปยัง API
        await changePassword(userId.toString(), _newPasswordController.text);
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _validatePasswords() async {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
      isLoading = true;
    });

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _newPasswordError = S.of(context)!.please_enter_new_password;
        isLoading = false;
      });
    } else if (_newPasswordController.text.length < 6) {
      setState(() {
        _newPasswordError = S.of(context)!.password_too_short;
        isLoading = false;
      });
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = S.of(context)!.please_confirm_your_password;
        isLoading = false;
      });
    } else if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = S.of(context)!.passwords_do_not_match;
        isLoading = false;
      });
    }

    if (_newPasswordError == null && _confirmPasswordError == null) {
      await _validateAndProceed();
    } else {
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
          icon: Icon(Icons.arrow_back, color: iconcolor),
          onPressed: () => context.router.replaceNamed('/otp'),
        ),
        title: Text(S.of(context)!.reset_password, style: appBarFont),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -135,
            left: (MediaQuery.of(context).size.width - 456) / 2,
            child: Container(
              width: 456,
              height: 456,
              decoration: BoxDecoration(
                color: fill_color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          DecoratedImage(),
          Column(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              S.of(context)!.new_password_instruction,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  color: fontcolor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.0),
                        TextFieldCustom(
                          controller: _newPasswordController,
                          labelText: S.of(context)!.new_password,
                          suffixIcon: _isNewPasswordObscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                          obscureText: _isNewPasswordObscured,
                          isError: _newPasswordError != null,
                          errorMessage: _newPasswordError ?? '',
                          onSuffixIconPressed: () {
                            setState(() {
                              _isNewPasswordObscured = !_isNewPasswordObscured;
                            });
                          },
                        ),
                        SizedBox(height: 16.0),
                        TextFieldCustom(
                          controller: _confirmPasswordController,
                          labelText: S.of(context)!.confirm_password,
                          suffixIcon: _isConfirmPasswordObscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                          obscureText: _isConfirmPasswordObscured,
                          isError: _confirmPasswordError != null,
                          errorMessage: _confirmPasswordError ?? '',
                          onSuffixIconPressed: () {
                            setState(() {
                              _isConfirmPasswordObscured =
                                  !_isConfirmPasswordObscured;
                            });
                          },
                        ),
                        SizedBox(height: 16.0),
                        CustomButton(
                          text: S.of(context)!.reset,
                          onPressed: _validatePasswords,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
