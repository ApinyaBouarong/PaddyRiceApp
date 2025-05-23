import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3030';
      // return 'http://192.168.33.87:3030';
      // return 'http://paddyrice.zapto.org:3030';
    } else if (Platform.isIOS) {
      return 'http://192.168.137:3000';
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return 'http://localhost:3000';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
