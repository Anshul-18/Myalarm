import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_alarmapp/pages/timer_ended_page.dart';

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
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  static const platform = MethodChannel('flutter_alarmapp/alarm');
  final TextEditingController _hoursController = TextEditingController(text: '00');
  final TextEditingController _minutesController = TextEditingController(text: '00');
  final TextEditingController _secondsController = TextEditingController(text: '00');
  final List<TimerInfo> _savedTimers = [
    TimerInfo(name: 'Facial mask', seconds: 900, id: 1), // 15 min
    TimerInfo(name: 'Boil eggs', seconds: 600, id: 2), // 10 min
    TimerInfo(name: 'Timer', seconds: 3001, id: 3), // 50 min 1 sec
    TimerInfo(name: 'Timer', seconds: 1501, id: 4), // 25 min 1 sec
    TimerInfo(name: 'Timer', seconds: 360, id: 5), // 6 min
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _playTimerAlarm() async {
    try {
      // Play system alarm sound
      await platform.invokeMethod('playTimerAlarm');
      // Vibrate
      HapticFeedback.vibrate();
    } catch (e) {
      print('Error playing timer alarm: $e');
    }
  }

  void _stopTimerAlarm() async {
    try {
      await platform.invokeMethod('stopTimerAlarm');
    } catch (e) {
      print('Error stopping timer alarm: $e');
    }
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
            _timer?.cancel();
            _isRunning = false;
            _isPaused = false;
            // Timer finished - play alarm and show page
            _playTimerAlarm();
            _showTimerEndedPage();
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
    _stopTimerAlarm();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _hours = 0;
      _minutes = 0;
      _seconds = 0;
      _hoursController.text = '00';
      _minutesController.text = '00';
      _secondsController.text = '00';
    });
  }

  void _showTimerEndedPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TimerEndedPage(
          timerName: 'Timer',
        ),
      ),
    );
    
    // If user clicked +1 Min, result will be 60 (seconds)
    if (result != null && result is int) {
      setState(() {
        _remainingSeconds = result;
        _isRunning = false;
        _isPaused = true;
      });
      // Restart timer
      _startTimer();
    } else {
      // User clicked Stop
      _stopTimer();
    }
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
      _hoursController.text = _hours.toString().padLeft(2, '0');
      _minutesController.text = _minutes.toString().padLeft(2, '0');
      _secondsController.text = _seconds.toString().padLeft(2, '0');
      _remainingSeconds = 0;
      _isRunning = false;
      _isPaused = false;
    });
    // Start the timer immediately
    _startTimer();
  }

  void _addCurrentTimer() {
    int hours = _hours;
    int minutes = _minutes;
    int seconds = _seconds;
    
    showDialog(
      context: context,
      builder: (context) {
        String timerName = 'Timer';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Add New Timer',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter timer name',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: (value) {
                        timerName = value.isEmpty ? 'Timer' : value;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Set Time',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialogTimeInput('Hours', hours, 23, (value) {
                          setDialogState(() => hours = value);
                        }),
                        const Text(':', style: TextStyle(color: Colors.white, fontSize: 20)),
                        _buildDialogTimeInput('Min', minutes, 59, (value) {
                          setDialogState(() => minutes = value);
                        }),
                        const Text(':', style: TextStyle(color: Colors.white, fontSize: 20)),
                        _buildDialogTimeInput('Sec', seconds, 59, (value) {
                          setDialogState(() => seconds = value);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (hours == 0 && minutes == 0 && seconds == 0) {
                      // Show error if no time set
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please set a time greater than 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      final totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
                      final newId = _savedTimers.isEmpty ? 1 : _savedTimers.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
                      _savedTimers.insert(0, TimerInfo(
                        name: timerName,
                        seconds: totalSeconds,
                        id: newId,
                      ));
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTimer(int id) {
    setState(() {
      _savedTimers.removeWhere((timer) => timer.id == id);
    });
  }

  void _editTimer(TimerInfo timer) {
    showDialog(
      context: context,
      builder: (context) {
        String timerName = timer.name;
        int hours = timer.seconds ~/ 3600;
        int minutes = (timer.seconds % 3600) ~/ 60;
        int seconds = timer.seconds % 60;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Edit Timer',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(text: timerName)..selection = TextSelection.fromPosition(TextPosition(offset: timerName.length)),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Timer name',
                        labelStyle: TextStyle(color: Colors.white38),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: (value) {
                        timerName = value.isEmpty ? 'Timer' : value;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Set Time',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialogTimeInput('Hours', hours, 23, (value) {
                          setDialogState(() => hours = value);
                        }),
                        const Text(':', style: TextStyle(color: Colors.white, fontSize: 20)),
                        _buildDialogTimeInput('Min', minutes, 59, (value) {
                          setDialogState(() => minutes = value);
                        }),
                        const Text(':', style: TextStyle(color: Colors.white, fontSize: 20)),
                        _buildDialogTimeInput('Sec', seconds, 59, (value) {
                          setDialogState(() => seconds = value);
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (hours == 0 && minutes == 0 && seconds == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please set a time greater than 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      final index = _savedTimers.indexWhere((t) => t.id == timer.id);
                      if (index != -1) {
                        final totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
                        _savedTimers[index] = TimerInfo(
                          name: timerName,
                          seconds: totalSeconds,
                          id: timer.id,
                        );
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTimersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Edit Timers',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _savedTimers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No saved timers',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _savedTimers.length,
                      itemBuilder: (context, index) {
                        final timer = _savedTimers[index];
                        final hours = timer.seconds ~/ 3600;
                        final minutes = (timer.seconds % 3600) ~/ 60;
                        final seconds = timer.seconds % 60;
                        final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                        
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              timer.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              timeString,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _editTimer(timer);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      _deleteTimer(timer.id);
                                    });
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTimeInput(String label, int value, int maxValue, Function(int) onChanged) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (value < maxValue) {
                      onChanged(value + 1);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 20),
                  ),
                ),
                IntrinsicWidth(
                  child: _TimeInputField(
                    value: value,
                    maxValue: maxValue,
                    onChanged: onChanged,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (value > 0) {
                      onChanged(value - 1);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2C2C2C),
            onSelected: (value) {
              if (value == 'edit') {
                // Handle edit action
                _showEditTimersDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text(
                  'Edit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
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
                  // Timer display - always show big numbers
                  if (_isRunning || _isPaused)
                    _buildRunningTimer()
                  else
                    _buildTimerInput(),
                  const SizedBox(height: 40),
                  // Control buttons
                  if (_isRunning || _isPaused)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button
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
                              Icons.refresh,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Play/Pause button
                        GestureDetector(
                          onTap: _isRunning ? _pauseTimer : _startTimer,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            child: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_hours > 0 || _minutes > 0 || _seconds > 0)
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
                            onPressed: _addCurrentTimer,
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
                        return Dismissible(
                          key: Key(timer.id.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteTimer(timer.id);
                          },
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () => _editTimer(timer),
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
    TextEditingController controller;
    int maxValue;
    
    if (type == 'hours') {
      controller = _hoursController;
      maxValue = 23;
    } else if (type == 'minutes') {
      controller = _minutesController;
      maxValue = 59;
    } else {
      controller = _secondsController;
      maxValue = 59;
    }

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
        // Current value (editable)
        IntrinsicWidth(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w300,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (text) {
              if (text.isEmpty) {
                setState(() {
                  if (type == 'hours') {
                    _hours = 0;
                  } else if (type == 'minutes') _minutes = 0;
                  else _seconds = 0;
                });
                return;
              }
              int? newValue = int.tryParse(text);
              if (newValue != null) {
                if (newValue > maxValue) {
                  newValue = maxValue;
                  controller.text = newValue.toString().padLeft(2, '0');
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
                setState(() {
                  if (type == 'hours') {
                    _hours = newValue!;
                  } else if (type == 'minutes') {
                    _minutes = newValue!;
                  } else {
                    _seconds = newValue!;
                  }
                });
              }
            },
            onTap: () {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            },
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

class _TimeInputField extends StatefulWidget {
  final int value;
  final int maxValue;
  final Function(int) onChanged;

  const _TimeInputField({
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  State<_TimeInputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends State<_TimeInputField> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString().padLeft(2, '0'));
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_TimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isEditing) return;
    
    String text = _controller.text;
    if (text.isEmpty) return;
    
    int? newValue = int.tryParse(text);
    if (newValue != null && newValue <= widget.maxValue) {
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        isDense: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      onTap: () {
        _isEditing = true;
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      },
      onEditingComplete: () {
        _isEditing = false;
        String text = _controller.text;
        if (text.isEmpty) {
          widget.onChanged(0);
          _controller.text = '00';
        } else {
          int? newValue = int.tryParse(text);
          if (newValue != null) {
            if (newValue > widget.maxValue) {
              newValue = widget.maxValue;
            }
            widget.onChanged(newValue);
            _controller.text = newValue.toString().padLeft(2, '0');
          }
        }
        FocusScope.of(context).unfocus();
      },
      onSubmitted: (text) {
        _isEditing = false;
        if (text.isEmpty) {
          widget.onChanged(0);
          _controller.text = '00';
        } else {
          int? newValue = int.tryParse(text);
          if (newValue != null) {
            if (newValue > widget.maxValue) {
              newValue = widget.maxValue;
            }
            widget.onChanged(newValue);
            _controller.text = newValue.toString().padLeft(2, '0');
          }
        }
      },
    );
  }
}
