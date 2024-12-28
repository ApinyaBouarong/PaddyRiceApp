import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

@RoutePage()
class OtpProfileRoute extends StatefulWidget {
  final String inputValue;
  final String otp; // Add this line to accept the OTP

  const OtpProfileRoute({
    Key? key,
    required this.inputValue,
    required this.otp, // Add this line to accept the OTP
  }) : super(key: key);

  @override
  _OtpRouteState createState() => _OtpRouteState();
}

class _OtpRouteState extends State<OtpProfileRoute> {
  TextEditingController _pinController = TextEditingController();
  bool isLoading = false;
  bool canResend = false; // Track if resend is allowed
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer(); // Start the timer when the widget is initialized
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Function to start the timer
  void _startResendTimer() {
    setState(() {
      canResend = false;
    });
    _timer = Timer(Duration(minutes: 1), () {
      setState(() {
        canResend = true;
      });
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

      context.router.replaceNamed('/changepassword_profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.enter_valid_otp),
          backgroundColor: error_color,
        ),
      );
    }
  }

  void _resendOtp() {
    if (canResend) {
      print('Resend OTP button pressed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.resend_otp),
        ),
      );
      _startResendTimer(); // Restart the timer after sending OTP
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(S.of(context)!.wait_before_resend), // Show a message to wait
      //   ),
      // );
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
          onPressed: () => context.router.replaceNamed('/forgot_profile'),
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
                      Center(
                        child: Text(
                          S
                              .of(context)!
                              .verification_code_sent(widget.inputValue),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: fontcolor,
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 72.0),
                        child: PinCodeTextField(
                          appContext: context,
                          length: 4,
                          controller: _pinController,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(5),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeColor: Colors.white,
                            selectedColor: iconcolor,
                            inactiveColor: Colors.grey,
                            activeFillColor: fill_color,
                            selectedFillColor: fill_color,
                            inactiveFillColor: fill_color,
                          ),
                          keyboardType: TextInputType.number,
                          boxShadows: [
                            BoxShadow(
                              offset: Offset(0, 1),
                              color: Colors.black12,
                              blurRadius: 10,
                            ),
                          ],
                          onChanged: (value) {},
                          enableActiveFill: true,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Center(
                        child: TextButton(
                          onPressed: canResend
                              ? _resendOtp
                              : null, // Disable button if canResend is false
                          child: Text(
                            S.of(context)!.resend_otp,
                            style: TextStyle(
                              color: canResend
                                  ? unnecessary_colors
                                  : Colors
                                      .grey, // Change color based on canResend
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.0),
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
