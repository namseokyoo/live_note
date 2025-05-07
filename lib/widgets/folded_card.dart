import 'package:flutter/material.dart';

class FoldedCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double foldSize;

  const FoldedCard({
    required this.child,
    this.color = Colors.white,
    this.foldSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FoldedCardPainter(
        color: color,
        foldSize: foldSize,
      ),
      child: child,
    );
  }
}

class FoldedCardPainter extends CustomPainter {
  final Color color;
  final double foldSize;

  FoldedCardPainter({
    required this.color,
    required this.foldSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - foldSize, 0)
      ..lineTo(size.width, foldSize)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // 접힌 부분 그리기
    final foldPath = Path()
      ..moveTo(size.width - foldSize, 0)
      ..lineTo(size.width, foldSize)
      ..lineTo(size.width - foldSize, foldSize)
      ..close();

    paint.color = color.darken();
    canvas.drawPath(foldPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
