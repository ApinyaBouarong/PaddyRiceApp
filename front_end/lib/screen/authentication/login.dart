import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'package:auto_route/auto_route.dart';
import 'package:flag/flag_enum.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/main.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/custom_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class LoginRoute extends StatefulWidget {
  const LoginRoute({Key? key}) : super(key: key);

  @override
  _LoginRouteState createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  TextEditingController _emailOrPhoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isEmailOrPhoneError = false;
  bool _isPasswordError = false;
  String? _token;
  bool _rememberMe = false;
  String? _rememberedEmailOrPhone;
  bool _isLoggingInAutomatically = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _getToken();
    _loadRememberedCredentialsAndAttemptAutoLogin();
  }

  Future<void> _loadRememberedCredentialsAndAttemptAutoLogin() async {
    if (!_isFirstLoad) return;

    final prefs = await SharedPreferences.getInstance();
    bool remembered = prefs.getBool('rememberMe') ?? false;
    String? savedEmail = prefs.getString('emailOrPhone');
    String? savedPassword = prefs.getString('password');

    setState(() {
      _rememberMe = remembered;
    });

    if (remembered && savedEmail != null && savedPassword != null) {
      _emailOrPhoneController.text = savedEmail;
      _passwordController.text = savedPassword;
      _autoLogin(); // Attempt auto login immediately after loading credentials
    }
    _isFirstLoad = false;
  }

  // Future<void> _checkLoginCredentialsAndAutoLogin() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   bool rememberMe = prefs.getBool('rememberMe') ?? false;

  //   setState(() {
  //     _rememberMe = rememberMe;
  //   });

  //   if (rememberMe) {
  //     String? savedEmail = prefs.getString('emailOrPhone');
  //     String? savedPassword = prefs.getString('password');

  //     if (savedEmail != null &&
  //         savedPassword != null &&
  //         savedEmail.isNotEmpty &&
  //         savedPassword.isNotEmpty) {
  //       setState(() {
  //         _emailOrPhoneController.text = savedEmail;
  //         _passwordController.text = savedPassword;
  //       });

  //       await _autoLogin();
  //     }
  //   }
  // }

  String? _errorMessage;
  Locale _locale = Locale('en');
  bool isEnglish = true;

  void _changeLanguage() {
    setState(() {
      isEnglish = !isEnglish;
      _locale = isEnglish ? Locale('en') : Locale('th');
      MyApp.setLocale(context, _locale);
    });
  }

  // Future<void> _autoLogin() async {
  //   if (_emailOrPhoneController.text.isEmpty ||
  //       _passwordController.text.isEmpty) {
  //     return;
  //   }

  //   setState(() {
  //     _isLoggingInAutomatically = true;
  //   });

  //   try {
  //     await login();
  //   } catch (e) {
  //     print('Auto login failed: $e');
  //     setState(() {
  //       _isLoggingInAutomatically = false;
  //     });
  //   }
  // }
  Future<void> _autoLogin() async {
    if (_emailOrPhoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoggingInAutomatically = true;
    });

    try {
      await login();
    } catch (e) {
      print('Auto login failed: $e');
      setState(() {
        _isLoggingInAutomatically = false;
      });
    }
  }

  Future<Null> _getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print('<-----Firebase Token Request Started----->');

      if (token == null) {
        print('Token is null');
      } else {
        setState(() {
          _token = token;
        });
        print('Token successfully retrieved: $token');
      }
      SharedPreferences preferences = await SharedPreferences.getInstance();
      int? userIdInt = preferences.getInt('userId');
      String? idLogin = userIdInt?.toString();

      print("idLogin: $idLogin");
      int? idLoginInt = userIdInt;
      print("idloginInt: $idLoginInt");

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/sendToken'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': idLoginInt,
          'token': token,
        }),
      );
      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Token sent successfully');
      } else {
        print('Failed to send token: ${response.body}');
      }
    } catch (e) {
      print('Error getting token: $e');
    }
  }

  Future<void> login() async {
    String emailOrPhone = _emailOrPhoneController.text;
    String password = _passwordController.text;
    print('Start login APi');
    try {
      final response = await http
          .post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrPhone': emailOrPhone,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        setState(() {
          _errorMessage = S.of(context)!.request_timeout;
        });
        throw TimeoutException(
            'The connection has timed out, please try again!');
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(response.body);
        final userId = responseData['user_id'];
        final deviceId = responseData['deviceId'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', userId);

        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', userId);

        if (_rememberMe) {
          await prefs.setString('emailOrPhone', emailOrPhone);
          await prefs.setString('password', password);
          await prefs.setBool('rememberMe', true);
        } else {
          await prefs.remove('emailOrPhone');
          await prefs.remove('password');
          await prefs.remove('rememberedEmailOrPhone');
          await prefs.setBool('rememberMe', false);
        }

        context.router.replace(BottomNavigationRoute(page: 0));
      } else {
        if (response.statusCode == 401) {
          setState(() {
            _isPasswordError = true;
            _errorMessage = S.of(context)!.incorrect_password;
          });
        } else if (response.statusCode == 404) {
          setState(() {
            _isEmailOrPhoneError = true;
            _errorMessage = S.of(context)!.user_not_found_prompt;
          });
        } else {
          setState(() {
            _errorMessage = 'Error: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = S.of(context)!.something_went_wrong;
      });
      print('Error: $e');
    }
  }

  void _clearEmailOrPhoneError() {
    if (_isEmailOrPhoneError) {
      setState(() {
        _isEmailOrPhoneError = false;
        _errorMessage = null;
      });
    }
  }

  void _clearPasswordError() {
    if (_isPasswordError) {
      setState(() {
        _isPasswordError = false;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor,
      ),
      backgroundColor: maincolor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  S.of(context)!.welcome,
                  style: TextStyle(
                    color: fontcolor,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.0),
                Text(
                  S.of(context)!.login_description,
                  softWrap: true,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fontcolor,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 24.0),
                Image.asset('lib/assets/icon/home.png',
                    height: 214, width: 214),
                SizedBox(height: 24.0),
                CustomTextField(
                  controller: _emailOrPhoneController,
                  labelText: S.of(context)!.email_or_phone,
                  prefixIcon: Icons.person_outline,
                  suffixIcon: Icons.clear,
                  obscureText: false,
                  isError: _isEmailOrPhoneError ||
                      _isPasswordError, // Check both errors
                  errorMessage: S
                      .of(context)!
                      .user_not_found_prompt, // Display general error message
                  onSuffixIconPressed: () {
                    _emailOrPhoneController.clear();
                  },
                  onChanged: (value) {
                    setState(() {
                      _isEmailOrPhoneError = false;
                      _isPasswordError = false;
                      _errorMessage = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.user_not_found_prompt;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                CustomTextField(
                  controller: _passwordController,
                  labelText: S.of(context)!.password,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon:
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                  obscureText: _obscureText,
                  isError: _isPasswordError ||
                      _isEmailOrPhoneError, // Check both errors
                  errorMessage: S
                      .of(context)!
                      .incorrect_password, // Display general error message
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _isEmailOrPhoneError = false;
                      _isPasswordError = false;
                      _errorMessage = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.incorrect_password;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      checkColor: fontcolor,
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return buttoncolor;
                        }
                        return Colors.transparent;
                      }),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    Text(
                      S.of(context)!.remember_me,
                      style: TextStyle(color: fontcolor, fontSize: 12),
                    ),
                    SizedBox(
                      width: 24,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: TextButton(
                          onPressed: () =>
                              context.router.replaceNamed('/forgot'),
                          child: Text(
                            S.of(context)!.forgot_password,
                            style: TextStyle(
                                color: unnecessary_colors, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttoncolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(312, 48),
                  ),
                  onPressed: _isLoggingInAutomatically
                      ? null
                      : () async {
                          print('Login button pressed');
                          if (_formKey.currentState!.validate()) {
                            print("login");
                            await login();
                          } else {
                            print('Validation failed');
                          }
                        },
                  child: Text(
                    S.of(context)!.sign_in,
                    textAlign: TextAlign.center,
                    style: buttonFont.copyWith(color: fontcolor, fontSize: 18),
                  ),
                ),
                SizedBox(height: 8.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          S.of(context)!.no_account_prompt,
                          style: TextStyle(
                            color: unnecessary_colors,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.router.replaceNamed('/signup'),
                          child: Text(
                            S.of(context)!.sign_up,
                            style: TextStyle(
                                color: fontcolor,
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: GestureDetector(
                      onTap: _changeLanguage,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: fill_color,
                                  borderRadius: BorderRadius.circular(13.0),
                                ),
                              ),
                              AnimatedPositioned(
                                duration: Duration(milliseconds: 300),
                                left: isEnglish ? 0 : 24,
                                right: isEnglish ? 24 : 0,
                                child: Flag.fromString(
                                  isEnglish ? 'GB' : 'TH',
                                  height: 26,
                                  width: 26,
                                  fit: BoxFit.cover,
                                  flagSize: FlagSize.size_1x1,
                                  borderRadius: 13,
                                ),
                              ),
                              Positioned(
                                left: isEnglish ? 30 : 5,
                                top: 4,
                                child: Text(
                                  isEnglish ? "TH" : "EN",
                                  style: TextStyle(
                                    color: fontcolor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // SizedBox(height: 8),
                          // Text(
                          //   S.of(context)!.change_language,
                          //   style: TextStyle(
                          //     color: unnecessary_colors,
                          //     fontSize: 12,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _checkLoginStatus() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool rememberMe = prefs.getBool('rememberMe') ?? false;

  //   if (rememberMe) {
  //     String? savedEmail = prefs.getString('emailOrPhone');
  //     String? savedPassword = prefs.getString('password');

  //     if (savedEmail != null && savedPassword != null) {
  //       setState(() {
  //         _emailOrPhoneController.text = savedEmail;
  //         _passwordController.text = savedPassword;
  //         _rememberMe = true;
  //       });

  //       // ไม่ต้องล็อกอินอัตโนมัติที่นี่ เพราะมีการตรวจสอบใน main.dart แล้ว
  //       // และถ้าสถานะ login ยังอยู่ จะไม่มาถึงหน้านี้
  //     }
  //   }
  // }

  // Future<void> _loadRememberMe() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _rememberMe = prefs.getBool('rememberMe') ?? false;
  //   });

  //   if (_rememberMe) {
  //     String? savedEmail = prefs.getString('emailOrPhone');
  //     String? savedPassword = prefs.getString('password');

  //     if (savedEmail != null &&
  //         savedPassword != null &&
  //         savedEmail.isNotEmpty &&
  //         savedPassword.isNotEmpty) {
  //       setState(() {
  //         _emailOrPhoneController.text = savedEmail;
  //         _passwordController.text = savedPassword;
  //       });

  //       Future.delayed(Duration(milliseconds: 500), () {
  //         _autoLogin();
  //       });
  //     }
  //   }
  // }
}
