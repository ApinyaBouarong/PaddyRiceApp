import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class SettingNotifiRoute extends StatefulWidget {
  const SettingNotifiRoute({super.key});

  @override
  _SettingNotifiRouteState createState() => _SettingNotifiRouteState();
}

class _SettingNotifiRouteState extends State<SettingNotifiRoute> {
  bool showManagement = true;
  bool isNotificationEnabled = true;

  void toggleManagementVisibility(bool value) {
    setState(() {
      showManagement = value;
    });
  }

  void toggleNotification() {
    setState(() {
      isNotificationEnabled = !isNotificationEnabled;
      showManagement = isNotificationEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          onPressed: () {
            context.router.replaceNamed('/notifi');
          },
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
        title: Text(
          S.of(context)!.notifications,
          style: appBarFont,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          DecoratedImage(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    S.of(context)!.device_messages,
                    style: TextStyle(
                      color: fontcolor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: toggleNotification,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          S.of(context)!.devices,
                          style: TextStyle(
                            color: fontcolor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: isNotificationEnabled,
                          onChanged: (bool value) {
                            toggleNotification();
                          },
                          trackColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Color(0xFF80C080);
                              }
                              return null;
                            },
                          ),
                          thumbColor: const MaterialStatePropertyAll<Color>(
                              Color.fromRGBO(77, 22, 0, 1)),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Color(0xFF80C080).withOpacity(0.54);
                              }
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.shade400;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                if (showManagement)
                  InkWell(
                    onTap: () =>
                        context.router.replaceNamed('/deviceNotifiSetting'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16,
                      ),
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.of(context)!.device_management,
                            style: TextStyle(
                              color: fontcolor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: iconcolor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
