import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:auto_route/auto_route.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/main.dart';
import 'package:paddy_rice/widgets/ChoiceDialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:paddy_rice/constants/api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

class UserProfile {
  String name;
  String surname;
  String email;

  UserProfile({
    required this.name,
    required this.surname,
    required this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
    );
  }
}

@RoutePage()
class ProfileRoute extends StatefulWidget {
  const ProfileRoute({super.key});

  @override
  _ProfileRouteState createState() => _ProfileRouteState();
}

class _ProfileRouteState extends State<ProfileRoute> {
  late Future<UserProfile> _userProfile;

  Future<void> _updateUserLanguageOnServer(
      int userId, String languageCode) async {
    try {
      print("----------API update language----------");
      print('userID: $userId');
      print('language: $languageCode');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/updateUserLanguage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'language': languageCode}),
      );

      print("----------API update language----------");
      if (response.statusCode == 200) {
        print('Language updated on server: $languageCode');
      } else {
        print('Failed to update language on server: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending language to server: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _userProfile = _fetchUserProfile();
  }

  Future<UserProfile> _fetchUserProfile() async {
    print('----------start _fetchUserProfile----------');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      throw Exception('No user ID found');
    }
    print('User id: $userId');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/profile/$userId'),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else {
      print('Error: ${response.statusCode} - ${response.reasonPhrase}');
      print('Response Body: ${response.body}');
      throw Exception('Failed to load profile');
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: S.of(context)!.log_out,
          content: S.of(context)!.logout_confirmation,
          parentContext: context,
          confirmButtonText: S.of(context)!.log_out,
          cancelButtonText: S.of(context)!.cancel,
          onConfirm: () async {
            Navigator.of(context).pop();

            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('emailOrPhone');
            await prefs.remove('password');
            await prefs.remove('rememberedEmailOrPhone');
            await prefs.setBool('rememberMe', false);
            await prefs.setBool('isLoggedIn', false);

            // **เคลียร์ค่าซ้ำอีกครั้งเพื่อความแน่ใจ**
            await prefs.remove('emailOrPhone');
            await prefs.remove('password');
            context.router.replaceNamed('/login');
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
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
        title: Text(S.of(context)!.my_profile, style: appBarFont),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<UserProfile>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(iconcolor)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ProfileContent(
                user: snapshot.data!, onLogout: _showLogoutDialog);
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }
}

// LanguageChangeTile
class LanguageChangeTile extends StatefulWidget {
  @override
  _LanguageChangeTileState createState() => _LanguageChangeTileState();
}

class _LanguageChangeTileState extends State<LanguageChangeTile> {
  Locale? _currentLocale;

  Future<void> _updateUserLanguageOnServer(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      await _ProfileRouteState()
          ._updateUserLanguageOnServer(userId, newLocale.languageCode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLocale = Localizations.localeOf(context); // โหลด locale ปัจจุบัน
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.translate, color: fontcolor),
      title: Text(S.of(context)!.language,
          style: TextStyle(color: fontcolor, fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: iconcolor),
      onTap: () => _showLanguageChangeSheet(context),
    );
  }

  void _showLanguageChangeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildLanguageOption("English", Locale('en')),
            _buildLanguageOption("ไทย", Locale('th')),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language, Locale locale) {
    bool isSelected = _currentLocale == locale;

    return Container(
      color: fill_color,
      child: ListTile(
        leading: Icon(
          Icons.language,
          color: isSelected ? iconcolor : unnecessary_colors,
        ),
        title: Text(language,
            style: TextStyle(
              color: isSelected ? iconcolor : unnecessary_colors,
            )),
        trailing: _currentLocale == locale
            ? Icon(Icons.check, color: iconcolor)
            : null,
        tileColor: _currentLocale == locale ? fill_color : Colors.transparent,
        onTap: () {
          _changeLanguage(locale);
        },
      ),
    );
  }

  void _changeLanguage(Locale locale) async {
    if (locale != _currentLocale) {
      setState(() {
        _currentLocale = locale;
        MyApp.setLocale(context, locale);
      });
      await _updateUserLanguageOnServer(locale); // เรียก API เมื่อเปลี่ยนภาษา
      Navigator.of(context).pop();
    }
  }
}

class ProfileContent extends StatelessWidget {
  final UserProfile user;
  final Function(BuildContext) onLogout;

  ProfileContent({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ProfileHeader(user: user),
          const SizedBox(
            height: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 288, bottom: 8),
            child: Text(
              S.of(context)!.account,
              style: TextStyle(
                  color: fontcolor, fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: fill_color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: iconcolor),
                  title: Text(
                    S.of(context)!.personal_settings,
                    style: TextStyle(fontSize: 16, color: fontcolor),
                  ),
                  trailing: Icon(Icons.chevron_right, color: iconcolor),
                  onTap: () => context.router.replaceNamed('/edit_profile'),
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: iconcolor),
                  title: Text(
                    S.of(context)!.change_password,
                    style: TextStyle(fontSize: 16, color: fontcolor),
                  ),
                  trailing: Icon(Icons.chevron_right, color: iconcolor),
                  onTap: () =>
                      context.router.replaceNamed('/change_password_profile'),
                ),
                LanguageChangeTile(),
              ],
            ),
          ),
          const SizedBox(
            height: 32.0,
          ),
          Container(
            decoration: BoxDecoration(
              color: fill_color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: error_color),
              title: Text(
                S.of(context)!.log_out,
                style: TextStyle(color: error_color, fontSize: 16),
              ),
              onTap: () => onLogout(context),
            ),
          ),
          SizedBox(
            height: 32,
          ),
        ],
      ),
    );
  }
}

class ProfileHeader extends StatefulWidget {
  final UserProfile user;
  ProfileHeader({required this.user});

  @override
  _ProfileHeaderState createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadImageFromLocal();
  }

  void _openGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final savedImagePath = await _saveImageToLocal(File(image.path));
      setState(() {
        _imagePath = savedImagePath;
      });
      print('Selected image path: $savedImagePath');
    }
  }

  String _generateImageKey(String input) {
    var bytes = utf8.encode(input);
    var hash = sha256.convert(bytes);
    return hash.toString();
  }

  // บันทึกรูปภาพลงในเครื่อง
  Future<String> _saveImageToLocal(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateImageKey(widget.user.email) + '.jpg';
    final savedImage = await image.copy('${directory.path}/$fileName');

    // บันทึก path ของรูปใน SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user_profile_image_${widget.user.email}', savedImage.path);

    return savedImage.path;
  }

  // โหลดรูปจากเครื่องเมื่อเปิดแอป
  Future<void> _loadImageFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath =
        prefs.getString('user_profile_image_${widget.user.email}');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
      setState(() {
        _imagePath = savedImagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: fill_color,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                InkWell(
                  onTap: () => _openGallery(context),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: iconcolor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                      image: DecorationImage(
                        image: _imagePath != null
                            ? FileImage(File(_imagePath!))
                            : AssetImage('lib/assets/icon/profile.png')
                                as ImageProvider,
                        alignment: Alignment.center,
                        scale: 1.2,
                      ),
                    ),
                  ),
                ),
                Container(
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
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: iconcolor,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.user.name} ${widget.user.surname}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: fontcolor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      widget.user.email.length > 30
                          ? '${widget.user.email.substring(0, 30)}...'
                          : widget.user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: unnecessary_colors,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
