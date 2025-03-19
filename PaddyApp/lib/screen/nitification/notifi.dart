import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

@RoutePage()
class NotifiRoute extends StatefulWidget {
  const NotifiRoute({super.key});

  @override
  _NotifiRouteState createState() => _NotifiRouteState();
}

class _NotifiRouteState extends State<NotifiRoute> {
  List<NotificationItem> notifications = [];
  late Map<String, List<NotificationItem>> groupedNotifications;

  @override
  void initState() {
    super.initState();
    // Do not initialize notifications here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = S.of(context);
    notifications = [
      NotificationItem("2024-07-19", "01:45 pm", localizations!.temp_front,
          localizations.temp_exceeds,
          temperature: 40.5),
      NotificationItem("2024-08-19", "03:10 pm", localizations.temp_front,
          localizations.temp_exceeds,
          temperature: 38.0),
      NotificationItem("2024-08-18", "10:32 am", localizations.temp_back,
          localizations.temp_exceeds,
          temperature: 39.2),
      NotificationItem("2024-08-18", "11:40 am", localizations.temp_front,
          localizations.temp_exceeds,
          temperature: 41.0),
      NotificationItem("2024-08-18", "04:23 pm", localizations.humidity,
          localizations.monitor_dryness),
    ];
    groupedNotifications = groupNotificationsByDate();
  }

  Map<String, List<NotificationItem>> groupNotificationsByDate() {
    Map<String, List<NotificationItem>> map = {};
    for (var notification in notifications) {
      (map[notification.date] ??= []).add(notification);
    }
    return map;
  }

  bool validateNotifications() {
    if (notifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.no_notifications)),
      );
      return false;
    }
    return true;
  }

  String formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    final locale = Localizations.localeOf(context).toString();
    final DateFormat formatter = DateFormat.yMMMMd(locale);

    String formattedDate = formatter.format(dateTime);

    if (locale == 'th') {
      final buddhistYear = dateTime.year + 543;
      formattedDate = formattedDate
          .replaceAll('${dateTime.year}', '$buddhistYear')
          .replaceAll('ค.ศ.', 'พ.ศ.');
    }

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          onPressed: () =>
              context.router.replace(BottomNavigationRoute(page: 0)),
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
        title: Text(S.of(context)!.notification, style: appBarFont),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.router.replaceNamed('/settingNotifi'),
            icon: Icon(Icons.settings, color: iconcolor),
          ),
        ],
      ),
      backgroundColor: maincolor,
      body: Stack(
        children: [
          DecoratedImage(),
          if (validateNotifications())
            ListView(
              children: groupedNotifications.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        formatDate(entry.key),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: fontcolor),
                      ),
                    ),
                    ...entry.value
                        .map((e) => notificationCard(
                            e.time, e.title, e.description,
                            temperature: e.temperature))
                        .toList(),
                  ],
                );
              }).toList(),
            )
        ],
      ),
    );
  }

  Widget notificationCard(String time, String title, String description,
      {double? temperature}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      // color: fill_color, // ลบออกเพื่อให้ `Container` ภายในกำหนดสีพื้นหลัง
      child: Container(
        decoration: BoxDecoration(
          color: fill_color, // ใส่สีพื้นหลังที่ต้องการ
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(time,
                      style: TextStyle(
                          color: fontcolor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(
                          color: fontcolor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(width: 80),
                  Expanded(
                    child: Text(
                      temperature != null
                          ? "$description ${temperature.toStringAsFixed(1)}°C"
                          : description,
                      style: TextStyle(
                        color: unnecessary_colors,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  String date;
  String time;
  String title;
  String description;
  double? temperature;

  NotificationItem(this.date, this.time, this.title, this.description,
      {this.temperature});
}
