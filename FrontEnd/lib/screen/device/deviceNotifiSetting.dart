import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class DeviceNotifiSettingRoute extends StatelessWidget {
  const DeviceNotifiSettingRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          onPressed: () {
            context.router.replaceNamed('/settingNotifi');
          },
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
        title: Text(
          S.of(context)!.device_management,
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
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    S.of(context)!.title,
                    style: TextStyle(
                      color: fontcolor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                buildSwitchTile(S.of(context)!.devices),
                buildSwitchTile(S.of(context)!.temp_alert),
                buildSwitchTile(S.of(context)!.humi_alert),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSwitchTile(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
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
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
          height: 48.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: fontcolor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SwitchMod(),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchMod extends StatefulWidget {
  const SwitchMod({super.key});

  @override
  State<SwitchMod> createState() => _SwitchModState();
}

class _SwitchModState extends State<SwitchMod> {
  bool light = true;

  @override
  Widget build(BuildContext context) {
    final MaterialStateProperty<Color?> trackColor =
        MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Color(0xFF80C080);
        }
        return null;
      },
    );
    final MaterialStateProperty<Color?> overlayColor =
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
    );

    return Switch(
      value: light,
      overlayColor: overlayColor,
      trackColor: trackColor,
      thumbColor: const MaterialStatePropertyAll<Color>(Colors.black),
      onChanged: (bool value) {
        setState(() {
          light = value;
        });
      },
    );
  }
}
