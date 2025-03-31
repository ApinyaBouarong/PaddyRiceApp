import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      //ใช้ port server
      return 'http://10.0.2.2:3030';
      // return 'http://192.168.0.106:3003';
      // return 'http://192.168.137.91:3003';
    } else if (Platform.isIOS) {
      return 'http://192.168.137:3000';
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return 'http://localhost:3000';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
