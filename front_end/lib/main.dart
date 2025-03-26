import 'package:flutter/material.dart';
import 'package:paddy_rice/l10n/locali18n.dart';
import 'package:paddy_rice/router/routes.dart';
import 'package:paddy_rice/constants/api.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

// Fetch both target values and current values for a specific deviceId
Future<void> fetchDeviceTargetValuesAndCurrentValues(String deviceId) async {
  final targetUrl =
      Uri.parse('${ApiConstants.baseUrl}/devices/$deviceId/target-values');
  final currentValuesUrl =
      Uri.parse('${ApiConstants.baseUrl}/devices/$deviceId/current-values');
  try {
    // Fetch target values
    final targetResponse = await http.get(targetUrl);
    if (targetResponse.statusCode == 200) {
      final targetData = jsonDecode(targetResponse.body);

      // Assuming the response contains target_front_temp, target_back_temp, target_humidity
      double targetFrontTemp =
          (targetData['target_front_temp'] as num?)?.toDouble() ?? 0.0;
      double targetBackTemp =
          (targetData['target_back_temp'] as num?)?.toDouble() ?? 0.0;
      double targetHumidity =
          (targetData['target_humidity'] as num?)?.toDouble() ?? 0.0;

      // Fetch current values
      final currentResponse = await http.get(currentValuesUrl);
      if (currentResponse.statusCode == 200) {
        final currentData = jsonDecode(currentResponse.body);

        // Assuming the response contains current_front_temp, current_back_temp, current_humidity
        double currentFrontTemp =
            (currentData['current_front_temp'] as num?)?.toDouble() ?? 0.0;
        double currentBackTemp =
            (currentData['current_back_temp'] as num?)?.toDouble() ?? 0.0;
        double currentHumidity =
            (currentData['current_humidity'] as num?)?.toDouble() ?? 0.0;

        // Check and send notifications based on the target values
        await checkAndSendNotification(
            currentFrontTemp, targetFrontTemp, 'Front Temperature Exceeded');
        await checkAndSendNotification(
            currentBackTemp, targetBackTemp, 'Back Temperature Exceeded');
        await checkAndSendNotification(
            currentHumidity, targetHumidity, 'Humidity Exceeded');
      } else {
        print('Failed to load current values: ${currentResponse.body}');
      }
    } else {
      print('Failed to load target values: ${targetResponse.body}');
    }
  } catch (error) {
    print('Error fetching values: $error');
  }
}

// Compare current values with target values and send a notification if exceeded
Future<void> checkAndSendNotification(
    double currentValue, double setpoint, String title) async {
  if (currentValue > setpoint) {
    final deviceId = "1";
    final url =
        Uri.parse('${ApiConstants.baseUrl}/devices/$deviceId/notifications');

    final data = {
      'title': title,
      'description': 'Value exceeded: $currentValue',
      'setpoint': setpoint,
      'exceededValue': currentValue,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (error) {
      print('Error sending notification: $error');
    }
  }
}

class MyApp extends StatefulWidget {
  MyApp({super.key});
  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  Locale _locale = const Locale('en', '');

  setLocale(Locale locale) async {
    await setLocaleStore(locale.toString());
    if (_locale == locale) return;
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();

    getLocale(context).then((locale) {
      if (_locale == locale) return;
      setState(() {
        _locale = locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Flutter Workshop",
      theme: ThemeData(fontFamily: 'opensans'),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      routerConfig: _appRouter.config(),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
    );
  }
}
