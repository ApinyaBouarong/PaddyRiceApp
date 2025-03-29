import 'package:auto_route/auto_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  final Map<String, dynamic> localizationsData = {
    "humidity": "Humidity monitoring Senser",
    "temp_back": "Back Tempereture Monitoring Sensor",
    "temp_front": "Front Tempereture Monitoring Sensor",
  };
  final Map<String, dynamic> jsonData = {
    'deviceName': "Device 2",
    'sensorType': "humidity", // ใช้ key จาก localizationsData
    'message': "Monitoring for potential dryness.",
    'date': "13 August 2024",
    'time': "10:30 am",
  };

  final Map<String, dynamic> jsonData2 = {
    'deviceName': "Device 1",
    'sensorType': "temp_front", // ใช้ key จาก localizationsData
    'message':
        "Temperature exceeds ${65}°C, please take action.", // แทรกค่า temperature
    // 'temperature': 65.6,
    'date': "18 August 2024",
    'time': "4:23 PM",
  };

  String getSensorText(String sensorType) {
    return localizationsData[sensorType] ?? sensorType;
  }

  String formatDate(String date) {
    final DateTime dateTime = DateFormat('dd MMMM', 'en_US').parse(date);
    final locale = Localizations.localeOf(context).toString();
    final DateFormat formatter;
    if (locale == 'th') {
      formatter = DateFormat('dd MMMM yyyy', 'th');
      final buddhistYear = dateTime.year + 543;
      return formatter
          .format(dateTime)
          .replaceAll('${dateTime.year}', '$buddhistYear')
          .replaceAll('ค.ศ.', 'พ.ศ.');
    } else {
      formatter = DateFormat('dd MMMM yyyy', 'en_US');
      return formatter.format(dateTime);
    }
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
      ),
      backgroundColor: maincolor,
      body: Stack(
        children: [
          DecoratedImage(),
          ListView(
            children: [
              _buildNotificationCard(jsonData),
              _buildNotificationCard(jsonData2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final String deviceName = data['deviceName'] as String? ?? '';
    final String sensorType = data['sensorType'] as String? ?? '';
    final String message = data['message'] as String? ?? '';
    final String date = data['date'] as String? ?? '';
    final String time = data['time'] as String? ?? '';
    final double? temperature = data['temperature'] as double?;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // อนุญาตให้ BottomSheet ขยายได้
          builder: (context) {
            return Container(
              height: MediaQuery.of(context).size.height *
                  0.9, // กำหนดความสูงเกือบเต็มหน้าจอ (ปรับตามต้องการ)
              decoration: BoxDecoration(
                color: fill_color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(width: 8),
                        Image.asset(
                          'lib/assets/icon/Humidity.jpg',
                          width: 80,
                          height: 80,
                        ),
                        SizedBox(width: 16),
                        Text(
                          '$deviceName',
                          style: TextStyle(
                              fontSize: 20,
                              color: fontcolor,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                // ห่อ Text แรกด้วย Row เพื่อเพิ่ม SizedBox ด้านหน้า
                                children: [
                                  SizedBox(width: 8),
                                  Text(
                                    'Sensor Type:',
                                    style: TextStyle(
                                        fontSize: 16, color: fontcolor,fontWeight: FontWeight.bold ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // SizedBox(width: 8),
                                  Text(
                                    '$sensorType',
                                    style: TextStyle(
                                        fontSize: 16, color: fontcolor,fontWeight: FontWeight.normal),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // ... (ส่วนของ Text อื่นๆ ที่คุณต้องการแสดง) ...
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: fill_color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceName,
                style: TextStyle(
                  color: fontcolor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getSensorText(sensorType),
                style: TextStyle(
                  color: fontcolor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message +
                    (temperature != null
                        ? " ${temperature.toStringAsFixed(0)}°C"
                        : ""),
                style: TextStyle(
                  color: unnecessary_colors,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "${formatDate(date)}, $time",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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
