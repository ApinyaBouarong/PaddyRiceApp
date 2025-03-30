import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auto_route/auto_route.dart';
import 'package:paddy_rice/constants/color.dart';

@RoutePage()
class ScanRoute extends StatefulWidget {
  const ScanRoute({Key? key}) : super(key: key);

  @override
  _ScanRouteState createState() => _ScanRouteState();
}

class _ScanRouteState extends State<ScanRoute> {
  bool _torchIsOn = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //       content: Text('Camera permission is required to scan QR codes')),
      // );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  void _openGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Selected image path: ${image.path}');
    }
  }

  Future<void> _toggleTorch() async {
    try {
      // bool? _torchIsOn = await controller?.getFlashStatus();
      // if (_torchIsOn != null && _torchIsOn == true) {
      //   await TorchLight.disableTorch();
      await controller?.toggleFlash();
      // } else {
      // await TorchLight.enableTorch();
      // }
      setState(() {
        _torchIsOn = !_torchIsOn;
      });
    } on Exception catch (e) {
      print('Could not toggle torch: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Could not toggle torch: $e'),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      body: Stack(
        children: [
          Container(
            color: maincolor,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: iconcolor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
                overlayColor: maincolor.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () =>
                    context.router.replaceNamed('/bottom_navigation'),
                icon: Icon(Icons.arrow_back, color: iconcolor),
              ),
              title: Text(
                S.of(context)!.scan,
                style: appBarFont,
              ),
              centerTitle: true,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 376.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.router.replaceNamed('/addDevice');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: fontcolor,
                      backgroundColor: buttoncolor,
                    ),
                    child: Text(
                      S.of(context)!.no_qr_code,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () => _openGallery(context),
                  child: Icon(Icons.image_search_outlined),
                  backgroundColor: buttoncolor,
                ),
                FloatingActionButton(
                  onPressed: _toggleTorch,
                  child: Icon(
                    _torchIsOn
                        ? Icons.flashlight_off_outlined
                        : Icons.flashlight_on_outlined,
                  ),
                  backgroundColor: buttoncolor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
