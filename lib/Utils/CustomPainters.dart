import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;

class TabPainter extends CustomPainter {
  TabPainter({this.fromLeft, this.height, this.color});
  final double fromLeft;
  final double height;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(size.width, 0);
    path.lineTo(size.width, height);
    path.lineTo(size.width * (fromLeft + 0.015), height);
    path.lineTo(size.width * (fromLeft - 0.015), 0);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = globals.theme.primaryColor.withOpacity(0.2);
    paint.style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width * 0.7, 0);
    path.lineTo(size.width, 0);
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
