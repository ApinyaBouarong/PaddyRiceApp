import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:http/http.dart' as http;

@RoutePage()
class OtpRoute extends StatefulWidget {
  final String inputValue;
  final String otp; // Add this line to accept the OTP

  const OtpRoute({
    Key? key,
    required this.inputValue,
    required this.otp, // Add this line to accept the OTP
  }) : super(key: key);

  @override
  _OtpRouteState createState() => _OtpRouteState();
}

class _OtpRouteState extends State<OtpRoute> {
  TextEditingController _pinController = TextEditingController();
  bool isLoading = false;
  bool canResend = false;
  Timer? _timer;
  int _remainingTime = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resendOtp() async {
    if (canResend) {
      setState(() {
        isLoading = true;
      });

      try {
        await _sendOtpToServer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)!.otp_sent_successfully),
          ),
        );

        _startResendTimer();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)!.otp_send_failed),
            backgroundColor: error_color,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendOtpToServer() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': widget.inputValue}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  void _startResendTimer() {
    setState(() {
      canResend = false;
    });
    _remainingTime = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_pinController.text == widget.otp) {
      setState(() {
        isLoading = true;
      });

      await Future.delayed(Duration(seconds: 3));
      setState(() {
        isLoading = false;
      });

      context.router.replaceNamed('/change_password');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.enter_valid_otp),
          backgroundColor: error_color,
        ),
      );
    }
  }

  // void _resendOtp() {
  //   if (canResend) {
  //     print('Resend OTP button pressed');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(S.of(context)!.resend_otp),
  //       ),
  //     );
  //     _startResendTimer(); // Restart the timer after sending OTP
  //   } else {
  //     // ScaffoldMessenger.of(context).showSnackBar(
  //     //   SnackBar(
  //     //     content: Text(S.of(context)!.wait_before_resend), // Show a message to wait
  //     //   ),
  //     // );
  //   }
  // }

  String _getRemainingTime() {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconcolor),
          onPressed: () => context.router.replaceNamed('/forgot'),
        ),
        title: Text(
          S.of(context)!.verification,
          style: appBarFont,
        ),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            S.of(context)!.verification_code_sent,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: fontcolor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: PinCodeTextField(
                          appContext: context,
                          length: 4,
                          controller: _pinController,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 56,
                            fieldWidth: 56,
                            activeColor:
                                Colors.transparent, // ไม่มีเส้นขอบเมื่อ active
                            selectedColor: fontcolor, // สีขอบเมื่อเลือก
                            inactiveColor:
                                Colors.grey[300]!, // สีขอบเมื่อไม่ได้เลือก
                            activeFillColor:
                                Colors.white, // สีพื้นหลังเมื่อ active
                            selectedFillColor:
                                Colors.white, // สีพื้นหลังเมื่อเลือก
                            inactiveFillColor: Colors.grey[100]!,
                          ),
                          keyboardType: TextInputType.number,
                          boxShadows: [
                            BoxShadow(
                              offset: Offset(0, 2),
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ],
                          onChanged: (value) {},
                          enableActiveFill: true,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Center(
                        child: GestureDetector(
                          onTap: canResend ? _resendOtp : null,
                          child: Text(
                            canResend
                                ? '${S.of(context)!.resend_otp} '
                                : S
                                    .of(context)!
                                    .time_left_to_resend(_getRemainingTime()),
                            style: TextStyle(
                              color: canResend ? fontcolor : unnecessary_colors,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: canResend
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      // Center(
                      //   child: TextButton(
                      //     onPressed: canResend ? _resendOtp : null,
                      //     child: Text(
                      //       S.of(context)!.resend_otp,
                      //       style: TextStyle(
                      //         color:
                      //             canResend ? unnecessary_colors : Colors.grey,
                      //         decoration: TextDecoration.underline,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: 8.0),
                      // Center(
                      //   child: Text(
                      //     S
                      //         .of(context)!
                      //         .time_left_to_resend(_getRemainingTime()),
                      //     style: TextStyle(
                      //       color: fontcolor,
                      //       fontSize: 14,
                      //       fontWeight: FontWeight.w400,
                      //     ),
                      //   ),
                      // ),
                      SizedBox(height: 16.0),
                      Center(
                        child: CustomButton(
                          text: S.of(context)!.verify,
                          onPressed: _verifyOtp,
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
