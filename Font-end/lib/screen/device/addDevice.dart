import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/ble_controller.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/router/routes.gr.dart';
import 'package:paddy_rice/widgets/dialog.dart';

@RoutePage()
class AddDeviceRoute extends StatefulWidget {
  const AddDeviceRoute({Key? key}) : super(key: key);

  @override
  _AddDeviceRouteState createState() => _AddDeviceRouteState();
}

class _AddDeviceRouteState extends State<AddDeviceRoute> {
  bool isScanning = false;
  bool scanComplete = false;
  String ssid = "";

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    bool isBluetoothOn = await flutterBlue.isOn;

    if (!isBluetoothOn) {
      _showBluetoothDialog();
    }
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ShDialog(
          title: S.of(context)!.bluetooth_required,
          content: S.of(context)!.please_turn_on_bluetooth,
          parentContext: context,
          confirmButtonText: S.of(context)!.turn_on_now,
          cancelButtonText: S.of(context)!.cancel,
          onConfirm: () {
            Navigator.of(context).pop();
            // FlutterBlue.instance.turnOn();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildDeviceList(BleController controller) {
    return StreamBuilder<List<ScanResult>>(
      stream: controller.scanResults,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final devices = snapshot.data!;
          return ListView.builder(
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final result = devices[index];
              final deviceName = result.device.name.isNotEmpty
                  ? result.device.name
                  : result.advertisementData.localName.isNotEmpty
                      ? result.advertisementData.localName
                      : 'Unknown Device';
              return Container(
                decoration: BoxDecoration(
                  color: fill_color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(
                    deviceName.isNotEmpty ? deviceName : 'Unknown Device',
                    style: TextStyle(
                      color: fontcolor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    result.device.id.id,
                    style: TextStyle(color: unnecessary_colors),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => controller.connectToDevice(
                        context, result.device, ssid),
                    child: Text(S.of(context)!.connect),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttoncolor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return Center(
            child: Text(
              S.of(context)!.no_devices,
              style: TextStyle(color: fontcolor),
            ),
          );
        }
      },
    );
  }

  Widget _buildUI(BleController controller) {
    return StreamBuilder<List<ScanResult>>(
      stream: controller.scanResults,
      builder: (context, snapshot) {
        if (controller.isScanning) {
          return Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(iconcolor),
          ));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildAutomaticDetectionUI(controller);
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_searching, size: 50, color: iconcolor),
              SizedBox(height: 20),
              Text(
                S.of(context)!.turn_on_bluetooth,
                style: TextStyle(color: fontcolor),
              ),
              Text(
                S.of(context)!.start_searching_for_devices,
                style: TextStyle(color: unnecessary_colors),
              ),
              SizedBox(height: 20),
              _buildScanButton(controller),
            ],
          );
        }
      },
    );
  }

  Widget _buildAutomaticDetectionUI(BleController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: buttoncolor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.bluetooth, color: iconcolor, size: 60),
        ),
        SizedBox(height: 20),
        Text(
          S.of(context)!.automatic_device_detection,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: fontcolor,
          ),
        ),
        Text(
          S.of(context)!.keep_mobile_near_device,
          style: TextStyle(color: unnecessary_colors),
        ),
        SizedBox(height: 30),
        _buildDeviceList(controller),
      ],
    );
  }

  Widget _buildScanButton(BleController controller) {
    return ElevatedButton(
      onPressed: controller.scanDevices,
      child: Text(
        S.of(context)!.turn_on_now,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: fontcolor,
        backgroundColor: buttoncolor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        leading: IconButton(
          onPressed: () =>
              context.router.replace(BottomNavigationRoute(page: 0)),
          icon: Icon(Icons.arrow_back, color: iconcolor),
        ),
        title: Text(S.of(context)!.add_device, style: appBarFont),
        centerTitle: true,
        elevation: 0,
      ),
      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (BleController controller) {
          return Stack(
            children: [
              DecoratedImage(),
              Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: 20),
                child: SingleChildScrollView(
                  child: _buildUI(controller),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
