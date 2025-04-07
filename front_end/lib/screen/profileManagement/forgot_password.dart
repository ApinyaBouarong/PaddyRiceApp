import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:paddy_rice/widgets/ChoiceDialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class ForgotProfileRoute extends StatefulWidget {
  const ForgotProfileRoute({Key? key}) : super(key: key);

  @override
  _ForgotRouteState createState() => _ForgotRouteState();
}

class _ForgotRouteState extends State<ForgotProfileRoute> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  Color _inputBorderColor = fill_color;
  FocusNode _inputFocusNode = FocusNode();
  Color _labelColor = unnecessary_colors;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    _inputFocusNode.addListener(() {
      setState(() {
        _labelColor =
            _inputFocusNode.hasFocus ? focusedBorder_color : unnecessary_colors;
      });
    });
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ฟังก์ชันส่ง OTP ไปที่อีเมล
  Future<void> sendOTP() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/send-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        final otpResponse = json.decode(response.body);

        // ตรวจสอบว่าค่า otp เป็น int หรือไม่ และแปลงให้เป็น String
        final otpValue = otpResponse['otp'].toString(); // แปลง int เป็น String

        context.router.push(
          OtpProfileRoute(
            key: ValueKey(
                'otpRoute'), // You may or may not need this, based on your requirements.
            inputValue: _emailController.text, // Ensure this is a string.
            otp: otpResponse['otp'].toString(), // Ensure this is a string.
          ),
        );
      } else {
        _showErrorSnackBar('Failed to send OTP. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันแสดง error message
  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: error_color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ฟังก์ชันแสดง dialog เมื่อไม่พบผู้ใช้
  // void _showUserNotFoundDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return ShDialog(
  //         title: S.of(context)!.user_not_found,
  //         content: S.of(context)!.user_not_found_prompt,
  //         parentContext: context,
  //         confirmButtonText: S.of(context)!.sign_up,
  //         cancelButtonText: S.of(context)!.cancel,
  //         onConfirm: () {
  //           context.router.replaceNamed('/signup');
  //         },
  //         onCancel: () {
  //           Navigator.of(context).pop();
  //         },
  //       );
  //     },
  //   );
  // }

  // ฟังก์ชันเช็คว่าผู้ใช้งานมีอยู่ในฐานข้อมูลหรือไม่
  Future<bool> checkUserExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/check-user-exists'), // URL API
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}), // ส่งอีเมลไปยังเซิร์ฟเวอร์
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['exists'];
      } else if (response.statusCode == 404) {
        return false; // ไม่พบอีเมล
      } else {
        throw Exception('Failed to check user existence');
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  // ฟังก์ชัน validate และส่ง OTP
  Future<void> _validateAndContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      final inputValue = _emailController.text;

      final userExists =
          await checkUserExists(inputValue); // เช็คอีเมลจากฐานข้อมูล

      if (userExists) {
        await sendOTP(); // ถ้ามีอีเมล ให้ส่ง OTP
      }
      // else {
      //   _showUserNotFoundDialog(); // ถ้าไม่พบอีเมล แสดงข้อความว่าไม่พบผู้ใช้
      // }
    } else {
      setState(() {
        _inputBorderColor = error_color;
      });
      _showErrorSnackBar(S.of(context)!.correct_errors);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          onPressed: () {
            context.router.replaceNamed('/change_password_profile');
          },
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
        title: Text(
          S.of(context)!.forgot_password,
          textAlign: TextAlign.center,
          style: appBarFont,
        ),
        centerTitle: true,
      ),
      backgroundColor: maincolor,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              S.of(context)!.enter_email_verification,
                              style: TextStyle(
                                color: fontcolor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 312,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextFormField(
                            focusNode: _inputFocusNode,
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fill_color,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              labelText: S.of(context)!.email,
                              labelStyle: TextStyle(
                                color: _labelColor,
                                fontSize: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: _inputBorderColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 1,
                                  color: focusedBorder_color,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: error_color,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: error_color,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return S.of(context)!.enter_email_verification;
                              }
                              final emailRegex =
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(value)) {
                                return S.of(context)!.invalid_email_format;
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: 312,
                          height: 48,
                          child: CustomButton(
                            text: S.of(context)!.send,
                            onPressed: _validateAndContinue,
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
