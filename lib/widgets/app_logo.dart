import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool animate;
  const AppLogo({Key? key, this.size = 32, this.animate = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xff10b981), Color(0xff059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff10b981).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.white.withOpacity(0.9),
              size: size * 0.7,
            ),
            Icon(
              Icons.bolt,
              color: Colors.white,
              size: size * 0.45,
            ),
          ],
        ),
      ),
    );
  }
}
