import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class StopwatchPage extends StatefulWidget {
  final Function(int)? onNavigate;
  final int selectedIndex;
  
  const StopwatchPage({super.key, this.onNavigate, this.selectedIndex = 1});

  @override
  _StopwatchPageState createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = '00:00.00';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _formattedTime = _formatTime(_stopwatch.elapsedMilliseconds);
      });
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    setState(() {
      _formattedTime = '00:00.00';
    });
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr.$hundredsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Stopwatch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Stopwatch display
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: StopwatchPainter(
                        elapsedMilliseconds: _stopwatch.elapsedMilliseconds,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Time display
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button
                        if (_stopwatch.elapsedMilliseconds > 0 && !_stopwatch.isRunning)
                          GestureDetector(
                            onTap: _resetStopwatch,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[900],
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        if (_stopwatch.elapsedMilliseconds > 0 && !_stopwatch.isRunning)
                          const SizedBox(width: 40),
                        // Play/Pause button
                        GestureDetector(
                          onTap: () {
                            if (_stopwatch.isRunning) {
                              _stopStopwatch();
                            } else if (_stopwatch.elapsedMilliseconds > 0) {
                              _startStopwatch();
                            } else {
                              _startStopwatch();
                            }
                            setState(() {});
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: Icon(
                              _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey.shade900, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.alarm, 'Alarm', 0),
              _buildNavItem(Icons.timer_outlined, 'Stopwatch', 1),
              _buildNavItem(Icons.hourglass_empty, 'Timer', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = widget.selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StopwatchPainter extends CustomPainter {
  final int elapsedMilliseconds;

  StopwatchPainter({required this.elapsedMilliseconds});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final outerCirclePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerCirclePaint);

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * 3.14159 / 180;
      final isMainTick = i % 5 == 0;
      final tickLength = isMainTick ? 15.0 : 8.0;
      final tickWidth = isMainTick ? 3.0 : 2.0;

      tickPaint.strokeWidth = tickWidth;

      final startX = center.dx + (radius - tickLength) * math.cos(angle);
      final startY = center.dy + (radius - tickLength) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);

      // Draw numbers for main ticks
      if (isMainTick) {
        final number = i == 0 ? 60 : i;
        final textPainter = TextPainter(
          text: TextSpan(
            text: number.toString(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        final textX = center.dx + (radius - 35) * math.cos(angle) - textPainter.width / 2;
        final textY = center.dy + (radius - 35) * math.sin(angle) - textPainter.height / 2;
        
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }

    // Draw elapsed time hand (blue)
    final seconds = (elapsedMilliseconds / 1000) % 60;
    final secondAngle = (seconds * 6 - 90) * 3.14159 / 180;

    final handPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final handLength = radius - 40;
    final handEndX = center.dx + handLength * math.cos(secondAngle);
    final handEndY = center.dy + handLength * math.sin(secondAngle);

    canvas.drawLine(center, Offset(handEndX, handEndY), handPaint);

    // Draw center circle
    final centerCirclePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerCirclePaint);

    // Draw small second counter at bottom
    final smallSeconds = (elapsedMilliseconds / 1000).floor();
    final smallSecondAngle = ((smallSeconds % 30) * 12 - 90) * 3.14159 / 180;
    
    final smallCircleCenter = Offset(center.dx, center.dy + 80);
    final smallRadius = 30.0;
    
    // Small circle background
    final smallCircleBgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(smallCircleCenter, smallRadius, smallCircleBgPaint);
    
    // Small circle border
    final smallCircleBorderPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(smallCircleCenter, smallRadius, smallCircleBorderPaint);

    // Small ticks
    for (int i = 0; i < 30; i++) {
      if (i % 5 == 0) {
        final tickAngle = (i * 12 - 90) * 3.14159 / 180;
        final tickStart = 25.0;
        final tickEnd = 28.0;
        
        final startX = smallCircleCenter.dx + tickStart * math.cos(tickAngle);
        final startY = smallCircleCenter.dy + tickStart * math.sin(tickAngle);
        final endX = smallCircleCenter.dx + tickEnd * math.cos(tickAngle);
        final endY = smallCircleCenter.dy + tickEnd * math.sin(tickAngle);
        
        final smallTickPaint = Paint()
          ..color = Colors.white60
          ..strokeWidth = 1;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), smallTickPaint);
      }
    }

    // Small hand
    final smallHandPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final smallHandLength = 20.0;
    final smallHandEndX = smallCircleCenter.dx + smallHandLength * math.cos(smallSecondAngle);
    final smallHandEndY = smallCircleCenter.dy + smallHandLength * math.sin(smallSecondAngle);

    canvas.drawLine(smallCircleCenter, Offset(smallHandEndX, smallHandEndY), smallHandPaint);

    // Draw numbers on small circle
    for (int i = 0; i < 30; i += 5) {
      final angle = (i * 12 - 90) * 3.14159 / 180;
      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final textX = smallCircleCenter.dx + 15 * math.cos(angle) - textPainter.width / 2;
      final textY = smallCircleCenter.dy + 15 * math.sin(angle) - textPainter.height / 2;
      
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(StopwatchPainter oldDelegate) {
    return oldDelegate.elapsedMilliseconds != elapsedMilliseconds;
  }
}
