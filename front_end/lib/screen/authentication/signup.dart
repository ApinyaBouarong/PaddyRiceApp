import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/custom_text_field.dart';
import 'package:paddy_rice/widgets/ChoiceDialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class SignupRoute extends StatefulWidget {
  const SignupRoute({Key? key}) : super(key: key);

  @override
  _SignupRouteState createState() => _SignupRouteState();
}

class _SignupRouteState extends State<SignupRoute> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _surnameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _isNameError = false;
  bool _isSurnameError = false;
  bool _isPhoneError = false;
  bool _isEmailError = false;
  bool _isPasswordError = false;
  bool _isConfirmPasswordError = false;

  bool isLoading = false;

  FocusNode _nameFocusNode = FocusNode();
  FocusNode _surnameFocusNode = FocusNode();
  FocusNode _phoneFocusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _nameFocusNode.addListener(() {
      setState(() {});
    });

    _surnameFocusNode.addListener(() {
      setState(() {});
    });

    _phoneFocusNode.addListener(() {
      setState(() {});
    });

    _emailFocusNode.addListener(() {
      setState(() {});
    });

    _passwordFocusNode.addListener(() {
      setState(() {});
    });

    _confirmPasswordFocusNode.addListener(() {
      setState(() {});
    });

    _nameController.addListener(() {
      if (_isNameError) {
        setState(() {
          _isNameError = false;
        });
      }
    });

    _surnameController.addListener(() {
      if (_isSurnameError) {
        setState(() {
          _isSurnameError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _surnameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: S.of(context)!.error,
          content: message,
          parentContext: context,
          confirmButtonText: S.of(context)!.ok,
          cancelButtonText: S.of(context)!.cancel,
          onConfirm: () {
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: S.of(context)!.success,
          content: message,
          parentContext: context,
          confirmButtonText: S.of(context)!.ok,
          cancelButtonText: S.of(context)!.cancel,
          onConfirm: () {
            Navigator.of(context).pop();
            context.router.replaceNamed('/login');
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  bool _validateFields() {
    // เริ่มตรวจสอบทีละฟิลด์จากบนลงล่าง

    // ตรวจสอบชื่อ
    if (_nameController.text.isEmpty) {
      setState(() {
        _isNameError = true;
      });
      _showErrorDialog(S.of(context)!.name_error);
      return false;
    }

    if (!nameRegex.hasMatch(_nameController.text)) {
      setState(() {
        _isNameError = true;
      });
      _showErrorDialog(S.of(context)!.name_invalid_error);
      return false;
    }

    // ตรวจสอบนามสกุล
    if (_surnameController.text.isEmpty) {
      setState(() {
        _isSurnameError = true;
      });
      _showErrorDialog(S.of(context)!.surname_error);
      return false;
    }

    if (!nameRegex.hasMatch(_surnameController.text)) {
      setState(() {
        _isSurnameError = true;
      });
      _showErrorDialog(S.of(context)!.surname_invalid_error);
      return false;
    }

    // ตรวจสอบเบอร์โทรศัพท์
    if (_phoneController.text.isEmpty) {
      setState(() {
        _isPhoneError = true;
      });
      _showErrorDialog(S.of(context)!.phone_error);
      return false;
    }

    if (!phoneRegex.hasMatch(_phoneController.text)) {
      setState(() {
        _isPhoneError = true;
      });
      _showErrorDialog(S.of(context)!.phone_error);
      return false;
    }

    // ตรวจสอบอีเมล
    if (_emailController.text.isEmpty) {
      setState(() {
        _isEmailError = true;
      });
      _showErrorDialog(S.of(context)!.email_error);
      return false;
    }

    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _isEmailError = true;
      });
      _showErrorDialog(S.of(context)!.email_error);
      return false;
    }

    // ตรวจสอบรหัสผ่าน
    if (_passwordController.text.isEmpty) {
      setState(() {
        _isPasswordError = true;
      });
      _showErrorDialog(S.of(context)!.password_error);
      return false;
    }

    // ตรวจสอบยืนยันรหัสผ่าน
    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _isConfirmPasswordError = true;
      });
      _showErrorDialog(S.of(context)!.password_error);
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _isPasswordError = true;
        _isConfirmPasswordError = true;
      });
      _showErrorDialog(S.of(context)!.password_error);
      return false;
    }

    // ถ้าผ่านทุกการตรวจสอบ ให้คืนค่า true
    return true;
  }

  Future<void> signup() async {
    if (_validateFields()) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _nameController.text,
            'surname': _surnameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        setState(() {
          isLoading = false;
        });

        if (response.statusCode == 201) {
          _showSuccessDialog(S.of(context)!.success_message);
        } else if (response.statusCode == 409) {
          _showErrorDialog(S.of(context)!.email_phone_exists);
        } else {
          _showErrorDialog(S.of(context)!.error);
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(S.of(context)!.network_error);
      }
    }
  }

  final phoneRegex = RegExp(r'^[0-9]{10}$');
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  // เพิ่มเติม RegEx สำหรับชื่อและนามสกุล อนุญาตเฉพาะตัวอักษรภาษาอังกฤษ ภาษาไทย และช่องว่างเท่านั้น
  final nameRegex = RegExp(r'^[a-zA-Z\u0E00-\u0E7F\s]+$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          onPressed: () => context.router.replaceNamed('/login'),
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
        title: Text(
          S.of(context)!.create_new_account,
          style: appBarFont,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 16.0,
                ),
                Image.asset(
                  'lib/assets/icon/home.png',
                  height: 152.0,
                  width: 152.0,
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _nameController,
                  labelText: S.of(context)!.name,
                  prefixIcon: Icons.person_outline_outlined,
                  suffixIcon: Icons.clear,
                  obscureText: false,
                  isError: _isNameError,
                  errorMessage: S.of(context)!.name_invalid_error,
                  onSuffixIconPressed: () {
                    _nameController.clear();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.name_invalid_error;
                    }
                    // if (!nameRegex.hasMatch(value)) {
                    //   setState(() {
                    //     _isNameError = true;
                    //   });
                    //   return S.of(context)!.name_invalid_error;
                    // }
                    setState(() {
                      _isNameError = false;
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _surnameController,
                  labelText: S.of(context)!.surname,
                  prefixIcon: Icons.person_outline,
                  suffixIcon: Icons.clear,
                  obscureText: false,
                  isError: _isSurnameError,
                  errorMessage: S.of(context)!.surname_invalid_error,
                  onSuffixIconPressed: () {
                    _surnameController.clear();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.surname_invalid_error;
                    }
                    // if (!nameRegex.hasMatch(value)) {
                    //   setState(() {
                    //     _isSurnameError = true;
                    //   });
                    //   return S.of(context)!.surname_invalid_error;
                    // }
                    setState(() {
                      _isSurnameError = false;
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _phoneController,
                  labelText: S.of(context)!.phone_number,
                  prefixIcon: Icons.phone_outlined,
                  suffixIcon: Icons.clear,
                  obscureText: false,
                  isError: _isPhoneError,
                  errorMessage: S.of(context)!.phone_error,
                  onSuffixIconPressed: () {
                    _phoneController.clear();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.phone_error;
                    }
                    setState(() {
                      _isPhoneError = false;
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _emailController,
                  labelText: S.of(context)!.email,
                  prefixIcon: Icons.email_outlined,
                  suffixIcon: Icons.clear,
                  obscureText: false,
                  isError: _isEmailError,
                  errorMessage: S.of(context)!.email_error,
                  onSuffixIconPressed: () {
                    _emailController.clear();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.email_error;
                    }
                    setState(() {
                      _isEmailError = false;
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _passwordController,
                  labelText: S.of(context)!.password,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon:
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                  obscureText: _obscureText,
                  isError: _isPasswordError,
                  errorMessage: S.of(context)!.password_error,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.email_error;
                    }
                    setState(() {
                      _isPasswordError = false;
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: S.of(context)!.confirm_password,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon:
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                  obscureText: _obscureText,
                  isError: _isConfirmPasswordError,
                  errorMessage: S.of(context)!.password_error,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context)!.password_error;
                    }
                    setState(() {
                      _isConfirmPasswordError = false;
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: CustomButton(
                      text: S.of(context)!.sign_up, onPressed: signup),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
