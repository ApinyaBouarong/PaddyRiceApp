import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      //ใช้ port server
<<<<<<< HEAD
      return 'http://10.0.2.2:3030';
      // return 'http://192.168.0.106:3003';
      // return 'http://192.168.137.91:3003';
=======
      // return 'http://10.0.2.2:3030';
      // return 'http://192.168.0.106:3003';
      return 'http://192.168.137.91:3030';
>>>>>>> ee6995936689c0aa31e7fc2f33ef4d56d7ac7896
    } else if (Platform.isIOS) {
      return 'http://192.168.137:3000';
    } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return 'http://localhost:3000';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
<<<<<<< HEAD
=======
   
>>>>>>> ee6995936689c0aa31e7fc2f33ef4d56d7ac7896
