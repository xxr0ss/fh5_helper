import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

class ForzaData {
  bool isRaceOn = false;
  double engineMaxRpm = 0.0;
  double currentEngineRpm = 0.0;
  int gear = 0;
  int accel = 0;
  int brake = 0;

  ForzaData();

  parseJsonStr(String? jsonStr) {
    if (jsonStr == null) return;
    Map<String, dynamic> data = json.decode(jsonStr);
    isRaceOn = data['IsRaceOn'] == 1;
    engineMaxRpm = data['EngineMaxRpm'] ?? 0.0;
    currentEngineRpm = data['CurrentEngineRpm'] ?? 0.0;
    gear = data['Gear'] ?? 0;
    accel = data['Accel'] ?? 0;
    brake = data['Brake'] ?? 0;
  }
}

class DashboardConfig {
  double value;
  Color color;
  Color backgroundColor;
  double radius;
  double strokeWidth;
  String text;

  DashboardConfig({
    required this.value,
    this.color = Colors.blue,
    this.backgroundColor = const Color(0xFFD6D6D6),
    this.radius = 90.0,
    this.strokeWidth = 10.0,
    this.text = "",
  });
}

class DashboardPainter extends CustomPainter {
  final DashboardConfig _config;
  late Paint _paint;
  late double _radius;

  DashboardPainter(this._config) {
    _paint = Paint();
    _radius = _config.radius - _config.strokeWidth / 2;
  }

  drawDashboard(Canvas canvas) {
    canvas.save();
    _paint
      ..style = PaintingStyle.stroke
      ..color = _config.backgroundColor
      ..strokeWidth = _config.strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromLTRB(0, 0, _radius * 2, _radius * 2), 2 / 3 * pi,
        5 / 3 * pi, false, _paint);

    double sweepAngle = _config.value * 300;
    _paint
      ..color = _config.color
      ..strokeWidth = _config.strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTRB(0, 0, _radius * 2, _radius * 2), 2 / 3 * pi,
        sweepAngle / 180 * pi, false, _paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(_config.strokeWidth / 2, _config.strokeWidth / 2);
    drawDashboard(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DashBoard extends StatefulWidget {
  final DashboardConfig config;

  const DashBoard({Key? key, required this.config}) : super(key: key);

  @override
  _DashBoardState createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(widget.config.text),
        SizedBox(
          width: widget.config.radius * 2,
          height: widget.config.radius * 2,
          child: CustomPaint(painter: DashboardPainter(widget.config)),
        ),
      ],
    );
  }
}
