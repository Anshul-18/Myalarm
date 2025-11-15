import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerEndedPage extends StatefulWidget {
  final String timerName;

  const TimerEndedPage({
    super.key,
    required this.timerName,
  });

  @override
  State<TimerEndedPage> createState() => _TimerEndedPageState();
}

class _TimerEndedPageState extends State<TimerEndedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  static const platform = MethodChannel('flutter_alarmapp/alarm');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _stopTimer() async {
    try {
      await platform.invokeMethod('stopTimerAlarm');
    } catch (e) {
      debugPrint('Error stopping timer alarm: $e');
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addOneMinute() async {
    // Stop the current alarm
    try {
      await platform.invokeMethod('stopTimerAlarm');
    } catch (e) {
      debugPrint('Error stopping timer alarm: $e');
    }
    
    if (mounted) {
      Navigator.of(context).pop(60); // Return 60 seconds to add
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added 1 minute to timer'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Animated timer icon
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2),
                  border: Border.all(color: Colors.blue, width: 3),
                ),
                child: const Icon(
                  Icons.timer,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Timer ended text
            const Text(
              '00:00:00',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Timer name
            Text(
              widget.timerName.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 4,
              ),
            ),
            const Spacer(),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  // Add 1 minute button
                  Expanded(
                    child: GestureDetector(
                      onTap: _addOneMinute,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '+1 Min',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stop button
                  Expanded(
                    child: GestureDetector(
                      onTap: _stopTimer,
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Stop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
