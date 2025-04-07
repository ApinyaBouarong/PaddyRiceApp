import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      //ใช้ port server
      /// The line `// return 'http://10.0.2.2:3030';` is a commented-out line of code in Dart. Comments
      /// in Dart start with `//` for single-line comments. In this case, the line is providing a sample
      /// URL `http://10.0.2.2:3030` as a placeholder for the base URL when the platform is Android.
      return 'http://10.0.2.2:3030';
      // return 'http://192.168.0.106:3030';
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
