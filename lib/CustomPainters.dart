import 'package:flutter/material.dart';

class TabPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.grey[300];
    paint.style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(size.width, 0);
    path.lineTo(size.width, 40);
    path.lineTo(size.width*0.2, 36);
    path.lineTo(size.width*0.17, 0);
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
    paint.color = Colors.grey[300];
    paint.style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height*0.3);
    path.lineTo(size.width*0.7, 0);
    path.lineTo(size.width, 0);
    path.moveTo(0, size.height);
    path.lineTo(0, size.height*0.7);
    path.lineTo(size.width*0.3, size.height);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}