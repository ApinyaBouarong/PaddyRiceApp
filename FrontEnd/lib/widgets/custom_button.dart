import 'package:flutter/material.dart';
import 'package:paddy_rice/constants/color.dart';
import 'package:paddy_rice/constants/font_size.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final bool isLoading;

  CustomButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttoncolor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(312, 48),
      ),
      onPressed: isLoading
          ? null
          : () async {
              setState(() {
                isLoading = true;
              });
              await widget.onPressed();
              setState(() {
                isLoading = false;
              });
            },
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(iconcolor),
              ),
            )
          : Text(
              widget.text,
              textAlign: TextAlign.center,
              style: buttonFont.copyWith(color: fontcolor, fontSize: 18.0),
            ),
    );
  }
}
