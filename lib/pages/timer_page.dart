import 'package:flutter/material.dart';
import 'dart:async';

class TimerInfo {
  final String name;
  final int seconds;
  final int id;

  TimerInfo({required this.name, required this.seconds, required this.id});
}

class TimerPage extends StatefulWidget {
  final Function(int)? onNavigate;
  final int selectedIndex;

  const TimerPage({super.key, this.onNavigate, this.selectedIndex = 2});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  List<TimerInfo> _savedTimers = [
    TimerInfo(name: 'Facial mask', seconds: 900, id: 1), // 15 min
    TimerInfo(name: 'Boil eggs', seconds: 600, id: 2), // 10 min
    TimerInfo(name: 'Timer', seconds: 3001, id: 3), // 50 min 1 sec
    TimerInfo(name: 'Timer', seconds: 1501, id: 4), // 25 min 1 sec
    TimerInfo(name: 'Timer', seconds: 360, id: 5), // 6 min
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds == 0) {
      _remainingSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    }
    
    if (_remainingSeconds > 0) {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _stopTimer();
            // Timer finished - could add sound/notification here
          }
        });
      });
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _hours = 0;
      _minutes = 0;
      _seconds = 0;
    });
  }

  void _incrementValue(String type) {
    setState(() {
      if (type == 'hours' && _hours < 23) {
        _hours++;
      } else if (type == 'minutes' && _minutes < 59) {
        _minutes++;
      } else if (type == 'seconds' && _seconds < 59) {
        _seconds++;
      }
    });
  }

  void _decrementValue(String type) {
    setState(() {
      if (type == 'hours' && _hours > 0) {
        _hours--;
      } else if (type == 'minutes' && _minutes > 0) {
        _minutes--;
      } else if (type == 'seconds' && _seconds > 0) {
        _seconds--;
      }
    });
  }

  void _loadTimer(TimerInfo timer) {
    setState(() {
      _hours = timer.seconds ~/ 3600;
      _minutes = (timer.seconds % 3600) ~/ 60;
      _seconds = timer.seconds % 60;
      _remainingSeconds = 0;
      _isRunning = false;
      _isPaused = false;
    });
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
          'Timer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Timer display/input
                  if (_isRunning || _isPaused)
                    _buildRunningTimer()
                  else
                    _buildTimerInput(),
                  const SizedBox(height: 40),
                  // Start/Pause button
                  if (!_isRunning && !_isPaused && (_hours > 0 || _minutes > 0 || _seconds > 0))
                    GestureDetector(
                      onTap: _startTimer,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  if (_isRunning)
                    GestureDetector(
                      onTap: _pauseTimer,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  if (_isPaused)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _stopTimer,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[900],
                            ),
                            child: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: _startTimer,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  // Frequently used timers
                  if (!_isRunning && !_isPaused) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Frequently used timers',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Add timer functionality
                            },
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _savedTimers.length,
                      itemBuilder: (context, index) {
                        final timer = _savedTimers[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              timer.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(timer.seconds),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _loadTimer(timer),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildTimerInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeColumn('hours', _hours, 23),
        const SizedBox(width: 8),
        const Text(
          ':',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(width: 8),
        _buildTimeColumn('minutes', _minutes, 1),
        const SizedBox(width: 8),
        const Text(
          ':',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(width: 8),
        _buildTimeColumn('seconds', _seconds, 0),
      ],
    );
  }

  Widget _buildTimeColumn(String type, int value, int topValue) {
    return Column(
      children: [
        // Top value (grayed out)
        Text(
          topValue.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 48,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        // Current value (white)
        GestureDetector(
          onTap: () {
            // Could add tap to edit functionality
          },
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Bottom value (grayed out)
        Text(
          ((value == 0 ? (type == 'hours' ? 23 : 59) : value - 1))
              .toString()
              .padLeft(2, '0'),
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 48,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildRunningTimer() {
    return Column(
      children: [
        Text(
          _formatTime(_remainingSeconds),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
      ],
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
