import 'package:flutter/material.dart';

class VetConnectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final paintGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.purple, Colors.red],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final dogPath = Path()
      ..moveTo(size.width * 0.9, size.height * 0.15)
      ..cubicTo(size.width * 0.8, size.height * 0.3, size.width * 0.6,
          size.height * 0.1, size.width * 0.5, size.height * 0.3)
      ..cubicTo(size.width * 0.4, size.height * 0.5, size.width * 0.2,
          size.height * 0.3, size.width * 0.1, size.height * 0.5);

    final catPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.85)
      ..cubicTo(size.width * 0.2, size.height * 0.7, size.width * 0.4,
          size.height * 0.9, size.width * 0.5, size.height * 0.7)
      ..cubicTo(size.width * 0.6, size.height * 0.5, size.width * 0.8,
          size.height * 0.7, size.width * 0.9, size.height * 0.5);

    canvas.drawPath(dogPath, paintGradient);
    canvas.drawPath(catPath, paintGradient);

    // Drawing the text
    const textStyle1 = TextStyle(
      color: Colors.red,
      fontSize: 50,
      fontWeight: FontWeight.bold,
    );

    const textStyle2 = TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.normal,
    );

    const textSpan1 = TextSpan(
      text: 'VET',
      style: textStyle1,
    );

    const textSpan2 = TextSpan(
      text: 'connect',
      style: textStyle2,
    );

    final textPainter1 = TextPainter(
      text: textSpan1,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    final textPainter2 = TextPainter(
      text: textSpan2,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    textPainter1.layout();
    textPainter2.layout();

    textPainter1.paint(canvas, Offset(size.width * 0.05, size.height * 0.1));
    textPainter2.paint(canvas, Offset(size.width * 0.2, size.height * 0.16));

    // Drawing the circles
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.red.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 60, paint);

    paint.color = Colors.purple.withOpacity(0.3);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 80, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
