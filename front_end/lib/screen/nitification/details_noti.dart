import 'package:flutter/material.dart'; // นำเข้าไลบรารี Flutter สำหรับสร้าง UI
import 'package:auto_route/auto_route.dart'; // นำเข้าไลบรารี auto_route สำหรับจัดการการนำทาง
import 'package:paddy_rice/constants/color.dart'; // นำเข้าค่าสีที่กำหนดไว้ในโปรเจกต์
import 'package:paddy_rice/constants/font_size.dart'; // นำเข้าขนาดตัวอักษรที่กำหนดไว้

@RoutePage() // Annotation นี้บอกให้ auto_route รู้ว่า Widget นี้คือหน้าจอที่สามารถนำทางมาได้
class DetailNotiRoute extends StatelessWidget {
  // ตัวแปรที่จะรับข้อมูลที่ส่งมาจากหน้า Notifications
  final String deviceName;
  final String sensorType;

  // Constructor ของ Widget นี้ ที่ต้องรับค่า deviceName และ sensorType เมื่อสร้าง
  const DetailNotiRoute({
    Key? key,
    required this.deviceName,
    required this.sensorType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maincolor, // ใช้สีหลักของแอปสำหรับ AppBar
        title: Text('Analog View', style: appBarFont), // กำหนด Title ของ AppBar และใช้ Style ตัวอักษรที่กำหนดไว้
        centerTitle: true, // จัด Title ให้อยู่ตรงกลาง
      ),
      backgroundColor: maincolor, // ใช้สีหลักของแอปสำหรับพื้นหลังของหน้าจอ
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Analog Data for:',
                style: TextStyle(fontSize: 18, color: fontcolor), // ข้อความอธิบาย
              ),
              SizedBox(height: 8), // เพิ่มพื้นที่ว่าง
              Text(
                'Device: $deviceName',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fontcolor), // แสดงชื่ออุปกรณ์
              ),
              SizedBox(height: 8), // เพิ่มพื้นที่ว่าง
              Text(
                'Sensor: $sensorType',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fontcolor), // แสดงประเภท Sensor
              ),
              SizedBox(height: 20), // เพิ่มพื้นที่ว่าง
              // TODO: เพิ่ม UI สำหรับแสดงผล Analog ที่นี่
              // ตัวอย่าง: วงกลมที่มีตัวเลขตรงกลาง
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, // ทำให้เป็นวงกลม
                  border: Border.all(color: iconcolor, width: 5), // เพิ่มขอบวงกลม
                ),
                child: Center(
                  child: Text(
                    '--', // **ตรงนี้คุณจะต้องใส่ค่า Analog จริงที่ดึงมาได้**
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: iconcolor),
                  ),
                ),
              ),
              SizedBox(height: 20), // เพิ่มพื้นที่ว่าง
              Text(
                'Mockup Analog UI',
                style: TextStyle(fontSize: 16, color: unnecessary_colors), // ข้อความบอกว่าเป็น UI ตัวอย่าง
              ),
            ],
          ),
        ),
      ),
    );
  }
}