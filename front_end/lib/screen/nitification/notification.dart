import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class NotifiRoute extends StatefulWidget {
  const NotifiRoute({super.key});

  @override
  _NotifiRouteState createState() => _NotifiRouteState();
}

class _NotifiRouteState extends State<NotifiRoute> {
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _onMessageSubscription;
  bool _isLoading = true;
  String? _deviceName;
  String? _userId;

  void _subscribeToFirebaseMessages() {
    if (Platform.isAndroid || Platform.isIOS) {
      _onMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null && message.data.isNotEmpty) {
          final newNotification =
              _mapFirebaseMessageToNotification(message.data);
          setState(() {
            _notifications.insert(0, newNotification);
          });
        }
      });
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  Map<String, dynamic> _mapFirebaseMessageToNotification(
      Map<String, dynamic> data) {
    print('DATA: $data');
    String message = '';
    if (data['sensorType'] == 'humidity') {
      message = S.of(context)!.monitor_dryness;
    } else if (data['sensorType'] == 'back_temp') {
      final currentBackTemp = data['current_value'];
      final targetBackTemp = data['target_value'];
      message = S
          .of(context)!
          .back_temp_exceeded('$currentBackTemp', '$targetBackTemp');
    } else if (data['sensorType'] == 'front_temp') {
      final currentFrontTemp = data['current_value'];
      final targetFrontTemp = data['target_value'];
      message = S
          .of(context)!
          .front_temp_exceeded('$currentFrontTemp', '$targetFrontTemp');
    }

    return {
      'deviceName': data['deviceName'],
      'sensorType': data['sensorType'],
      'message': message,
      'date': data['date'],
      'time': data['time'],
      'temperature': data['current_value'] != null
          ? double.tryParse(data['current_value'].toString())
          : null,
      'target_value': data['target_value'] != null
          ? double.tryParse(data['target_value'].toString())
          : null,
    };
  }

  Future<Map<String, String>?> _fetchDeviceId(String userId) async {
    final String url = '${ApiConstants.baseUrl}/user/devices/$userId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        print('user/device $responseData');
        if (responseData.isNotEmpty &&
            responseData[0]['device_id'] != null &&
            responseData[0]['device_name'] != null) {
          final String deviceId = responseData[0]['device_id'].toString();
          final String deviceName = responseData[0]['device_name'].toString();
          return {'deviceId': deviceId, 'deviceName': deviceName};
        }
      }
    } catch (error) {
      print('Error fetching device ID: $error');
    }
    return null;
  }

  Future<void> _fetchNotifications({String? deviceId}) async {
    setState(() => _isLoading = true);
    if (deviceId == null || deviceId.isEmpty) {
      print('Device ID is missing');
      setState(() => _isLoading = false);
      return;
    }

    final String url = '${ApiConstants.baseUrl}/notification/$deviceId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        print('res: $responseData');
        setState(() {
          _notifications = responseData.map<Map<String, dynamic>>((item) {
            final DateTime timestamp = DateTime.parse(item['timestamp']);
            String message = '';
            if (item['sensor_type'] == 'humidity') {
              message = S.of(context)!.monitor_dryness;
            } else if (item['sensor_type'] == 'back_temp') {
              final currentBackTemp = item['current_value'];
              final targetBackTemp = item['target_value'];
              message = S
                  .of(context)!
                  .back_temp_exceeded('$currentBackTemp', '$targetBackTemp');
            } else if (item['sensor_type'] == 'front_temp') {
              final currentFrontTemp = item['current_value'];
              final targetFrontTemp = item['target_value'];
              message = S
                  .of(context)!
                  .front_temp_exceeded('$currentFrontTemp', '$targetFrontTemp');
            }
            return {
              'deviceName': _deviceName,
              'sensorType': item['sensor_type'],
              'message': message,
              'date': DateFormat('dd MMMM', 'en_US').format(timestamp),
              'time': DateFormat('HH:mm').format(timestamp),
              'temperature': item['current_value'] != null
                  ? double.tryParse(item['current_value'].toString())
                  : null,
              'target_value': item['target_value'] != null
                  ? double.tryParse(item['target_value'].toString())
                  : null,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        print('Failed to load notifications: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('Error fetching notifications: $error');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');
    if (userId != null) {
      _userId = userId.toString();
      final deviceData = await _fetchDeviceId(_userId!);
      if (deviceData != null) {
        _deviceName = deviceData['deviceName'];
        await _fetchNotifications(deviceId: deviceData['deviceId']);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _subscribeToFirebaseMessages();
    _loadData();
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    super.dispose();
  }

  String getSensorText(String sensorType) {
    final localizations = S.of(context)!;
    switch (sensorType) {
      case 'humidity':
        return localizations.humidity_senser;
      case 'back_temp':
        return localizations.back_senser;
      case 'front_temp':
        return localizations.front_senser;
      default:
        return sensorType;
    }
  }

  String formatDate(String dateString) {
    try {
      final DateTime dateTime =
          DateFormat('dd MMMM', 'en_US').parse(dateString);
      final locale = Localizations.localeOf(context).toString();
      final DateFormat formatter = DateFormat('dd MMMM', locale);
      return formatter.format(dateTime);
    } catch (_) {
      return dateString;
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
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) =>
                      _buildNotificationCard(_notifications[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final String deviceName = data['deviceName'] ?? '';
    final String sensorType = data['sensorType'] ?? '';
    final double? target_value = data['target_value'];
    final String message = data['message'] ?? '';
    final String date = data['date'] ?? '';
    final String time = data['time'] ?? '';
    final double? temperature = data['temperature'];

    print('temp: $temperature');
    print('target: $target_value');

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _buildBottomSheet(data),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: fill_color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data['sensorType'] == 'humidity'
                        ? Colors.blue
                        : data['sensorType'] == 'back_temp' ||
                                data['sensorType'] == 'front_temp'
                            ? Colors.red
                            : Colors.grey,
                  ),
                  margin: const EdgeInsets.only(right: 8.0),
                ),
                Text(deviceName,
                    style: TextStyle(
                        color: fontcolor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ]),
              SizedBox(height: 8),
              Text(getSensorText(sensorType),
                  style: TextStyle(color: fontcolor, fontSize: 14)),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: unnecessary_colors, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text("$date, $time",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(Map<String, dynamic> data) {
    final String deviceName = data['deviceName'] ?? '';
    final String sensorType = data['sensorType'] ?? '';
    final String message = data['message'] ?? '';
    final String date = data['date'] ?? '';
    final String time = data['time'] ?? '';
    final double? temperature = data['temperature'];
    final double? target_value = data['target_value'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: fill_color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (sensorType == 'humidity')
              Image.asset('lib/assets/icon/Humidity.jpg', width: 60, height: 60)
            else if (sensorType == 'front_temp' || sensorType == 'back_temp')
              Image.asset('lib/assets/icon/Temp.jpg', width: 60, height: 60),
            SizedBox(width: 16),
            Text(deviceName,
                style: TextStyle(
                    fontSize: 20,
                    color: fontcolor,
                    fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 16),
          _buildDetailRow('Sensor :', getSensorText(sensorType)),
          _buildDetailRow('Date :', date),
          _buildDetailRow('Time :', time),
          if (temperature != null)
            _buildDetailRow('Current :', '${temperature.toStringAsFixed(1)}°C'),
          if (target_value != null)
            _buildDetailRow('Target :', '${target_value.toStringAsFixed(1)}°C'),
          Divider(color: Colors.grey[300]),
          _buildDetailRow('Detail :', message, isDetail: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isDetail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16, color: fontcolor, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 16, color: fontcolor))),
        ],
      ),
    );
  }
}
