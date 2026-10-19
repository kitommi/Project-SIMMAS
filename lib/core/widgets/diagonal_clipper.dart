import 'package:flutter/material.dart';

/// Meniru `clip-path: polygon(x% 0, 100% 0, 100% 100%, 0 100%)`.
class DiagonalClipper extends CustomClipper<Path> {
  const DiagonalClipper({this.topLeft = .4});

  final double topLeft;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * topLeft, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant DiagonalClipper oldClipper) =>
      oldClipper.topLeft != topLeft;
}
