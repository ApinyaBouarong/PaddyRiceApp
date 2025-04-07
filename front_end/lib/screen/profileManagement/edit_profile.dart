import 'dart:convert';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/custom_button.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class UserProfile {
  final String name, surname, email, phone;

  UserProfile({
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      phone: json['phone_number'],
    );
  }
}

@RoutePage()
class EditProfileRoute extends StatefulWidget {
  const EditProfileRoute({super.key});

  @override
  _EditProfileRouteState createState() => _EditProfileRouteState();
}

class _EditProfileRouteState extends State<EditProfileRoute> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool isLoading = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _saveImagePath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = _emailController.text;
    await prefs.setString('user_profile_image_$userEmail', imagePath);
  }

  Future<void> _loadImageFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = _emailController.text;
    final savedImagePath = prefs.getString('user_profile_image_$userEmail');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
      setState(() {
        _imagePath = savedImagePath;
      });
    }
  }

  void _openGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(image.path);
      final savedImage =
          await File(image.path).copy('${directory.path}/$fileName');

      await _saveImagePath(savedImage.path);

      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) throw Exception('No user ID found');

    final response =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/profile/$userId'));

    if (response.statusCode == 200) {
      final profile = UserProfile.fromJson(jsonDecode(response.body));
      _nameController.text = profile.name;
      _surnameController.text = profile.surname;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;

      await _loadImageFromLocal();
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      setState(() => isLoading = false);
      return _showDialog(S.of(context)!.error, 'User ID not found');
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _showDialog(
            S.of(context)!.success, S.of(context)!.profile_update_success);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (error) {
      _showDialog(S.of(context)!.error, 'Failed to update profile: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showDialog(String title, String content) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: title,
          content: content,
          parentContext: context,
          confirmButtonText: S.of(context)!.ok,
          onConfirm: () => Navigator.pop(context),
          onCancel: () {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconcolor),
          onPressed: () =>
              context.router.replace(BottomNavigationRoute(page: 1)),
        ),
        title: Text(S.of(context)!.edit_profile, style: appBarFont),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          DecoratedImage(),
          Column(
            children: [
              _buildProfileImage(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          ..._buildTextFields(),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: S.of(context)!.update,
                            onPressed: _onSaveChanges,
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
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          GestureDetector(
            onTap: () => _openGallery(context),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
                image: DecorationImage(
                  image: _imagePath != null
                      ? FileImage(File(_imagePath!))
                      : const AssetImage('lib/assets/icon/profile.jpg')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          _buildEditIcon(),
        ],
      ),
    );
  }

  Widget _buildEditIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: maincolor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.edit,
        size: 16,
        color: iconcolor,
      ),
    );
  }

  List<Widget> _buildTextFields() {
    return [
      TextFieldCustom(
        controller: _nameController,
        labelText: S.of(context)!.name,
        suffixIcon: Icons.clear,
        isError: _nameController.text.isEmpty,
        errorMessage: S.of(context)!.name_error,
        onSuffixIconPressed: () {
          _nameController.clear();
        },
        onChanged: (value) {
          setState(() {});
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return S.of(context)!.name_error;
          } else if (value.length < 2) {
            return S.of(context)!.name_error;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFieldCustom(
        controller: _surnameController,
        labelText: S.of(context)!.surname,
        suffixIcon: Icons.clear,
        isError: _surnameController.text.isEmpty,
        errorMessage: S.of(context)!.surname_error,
        onSuffixIconPressed: () {
          _surnameController.clear();
        },
        onChanged: (value) {
          setState(() {});
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return S.of(context)!.surname_error;
          } else if (value.length < 2) {
            return S.of(context)!.surname_error;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFieldCustom(
        controller: _emailController,
        labelText: S.of(context)!.email,
        suffixIcon: Icons.clear,
        isError: _emailController.text.isEmpty,
        errorMessage: S.of(context)!.email_error,
        onSuffixIconPressed: () {
          _emailController.clear();
        },
        onChanged: (value) {
          setState(() {});
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return S.of(context)!.email_error;
          } else if (!RegExp(
                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
              .hasMatch(value)) {
            return S.of(context)!.email_error;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFieldCustom(
        controller: _phoneController,
        labelText: S.of(context)!.phone,
        suffixIcon: Icons.clear,
        isError: _phoneController.text.isEmpty,
        errorMessage: S.of(context)!.phone_error,
        onSuffixIconPressed: () {
          _phoneController.clear();
        },
        onChanged: (value) {
          setState(() {});
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return S.of(context)!.phone_error;
          } else if (value.length != 10) {
            return S.of(context)!.phone_error;
          }
          return null;
        },
      ),
    ];
  }

  Future<void> _onSaveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      await Future.delayed(const Duration(seconds: 2));

      try {
        await _updateUserProfile();
      } catch (error) {
        _showDialog(S.of(context)!.error, S.of(context)!.profile_update_failed);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }
}

class ShDialog extends StatelessWidget {
  final String title;
  final String content;
  final BuildContext parentContext;
  final String confirmButtonText;
  final String? cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  ShDialog({
    required this.title,
    required this.content,
    required this.parentContext,
    required this.confirmButtonText,
    this.cancelButtonText,
    required this.onConfirm,
    required this.onCancel,
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
            Center(
              // ใช้ Center เพื่อจัดปุ่ม OK ให้อยู่ตรงกลาง
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
