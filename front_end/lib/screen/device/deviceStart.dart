import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paddy_rice/constants/api.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';
import 'package:paddy_rice/widgets/CustomButton.dart';
import 'package:paddy_rice/widgets/decorated_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DevicestartRoute extends StatefulWidget {
  const DevicestartRoute({Key? key, required this.deviceId}) : super(key: key);

  final int deviceId;

  @override
  State<DevicestartRoute> createState() => _DevicestartRouteState();
}

class _DevicestartRouteState extends State<DevicestartRoute> {
  final TextEditingController _initialHumidityController =
      TextEditingController();
  bool _isInitialHumidityError = false;
  bool _isLoading = false;

  Future<void> _startBakingProcess() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${ApiConstants.baseUrl}/start');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'humidity': _initialHumidityController.text,
      'deviceId': widget.deviceId
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('API call successful: ${response.body}');
        Navigator.of(context).pop();
      } else {
        print('API call failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Error during API call: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: maincolor,
      appBar: AppBar(
        backgroundColor: maincolor,
        title: Text(S.of(context)!.bakeRice, style: appBarFont),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          DecoratedImage(),
          Center(
            // padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 32,
                ),
                TextFieldCustom(
                  controller: _initialHumidityController,
                  labelText: S.of(context)!.initialHumidity,
                  suffixIcon: Icons.clear,
                  isError: _isInitialHumidityError,
                  errorMessage: S.of(context)!.pleaseEnterInitialHumidity,
                  onSuffixIconPressed: () {
                    _initialHumidityController.clear();
                    setState(() {
                      _isInitialHumidityError = false;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _isInitialHumidityError = value.isEmpty;
                    });
                  },
                ),
                const SizedBox(height: 32),
                InfoBox(
                  title: S.of(context)!.humidityData,
                  message: S.of(context)!.humidityDataDetail,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: S.of(context)!.startBakingRice,
                  onPressed: () async {
                    if (_initialHumidityController.text.isNotEmpty) {
                      print(
                          "ค่าความชื้นเริ่มต้น: ${_initialHumidityController.text}");
                      await _startBakingProcess();
                    } else {
                      setState(() {
                        _isInitialHumidityError = true;
                      });
                    }
                  },
                  // isLoading: isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TextFieldCustom extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData suffixIcon;
  final bool obscureText;
  final bool isError;
  final String errorMessage;
  final void Function()? onSuffixIconPressed;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  TextFieldCustom({
    required this.controller,
    required this.labelText,
    required this.suffixIcon,
    this.obscureText = false,
    required this.isError,
    required this.errorMessage,
    this.onSuffixIconPressed,
    this.validator,
    this.onChanged,
  });

  @override
  _TextFieldCustomState createState() => _TextFieldCustomState();
}

class _TextFieldCustomState extends State<TextFieldCustom> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTextChange() {
    setState(() {
      _hasText = widget.controller.text.isNotEmpty;
      widget.onChanged?.call(widget.controller.text);
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 312,
          height: 48,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: fill_color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _isFocused ? iconcolor : fill_color),
          ),
          child: Row(
            children: [
              Text(
                widget.labelText + " : ",
                style: TextStyle(
                  fontSize: 16,
                  color: unnecessary_colors,
                ),
              ),
              Expanded(
                child: TextFormField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  validator: widget.validator,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: iconcolor, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    suffixIcon: (_isFocused || _hasText)
                        ? IconButton(
                            icon: Icon(widget.suffixIcon,
                                color: unnecessary_colors),
                            onPressed: widget.onSuffixIconPressed,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.isError)
          Container(
            width: 312,
            child: Row(
              children: [
                Text(
                  widget.errorMessage,
                  style: TextStyle(color: error_color, fontSize: 12),
                ),
              ],
            ),
          )
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String message;

  const InfoBox({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 312,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8.0),
          border: Border(
              left: BorderSide(
                  color: Color.fromRGBO(215, 168, 110, 1), width: 5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
              ),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            message,
            style: const TextStyle(fontSize: 14.0),
          ),
        ],
      ),
    );
  }
}
