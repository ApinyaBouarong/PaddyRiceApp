import 'package:flutter/material.dart';

class DecoratedImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: 0.5,
            image: AssetImage('lib/assets/icon/home.png'),
            alignment: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
