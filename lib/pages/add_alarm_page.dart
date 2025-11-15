import 'package:flutter_alarmapp/widgets/circle_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddAlarmPage extends StatefulWidget {
  final Map<String, dynamic>? existingAlarm;
  
  const AddAlarmPage({super.key, this.existingAlarm});

  @override
  _AddAlarmPageState createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage> {
  late TimeOfDay _selectedTime;
  bool _notificationEnabled = true;
  bool _vibrateEnabled = true;
  final List<bool> _selectedDays = [true, true, true, true, true, false, false]; // Mon-Sun
  String? _selectedRingtoneUri;
  String _ringtoneName = 'Default alarm sound';

  @override
  void initState() {
    super.initState();
    
    if (widget.existingAlarm != null) {
      // Load existing alarm data
      final time = widget.existingAlarm!['time'] as String;
      final period = widget.existingAlarm!['period'] as String;
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Convert to 24-hour format
      int hour24 = hour;
      if (period == 'PM' && hour != 12) {
        hour24 = hour + 12;
      } else if (period == 'AM' && hour == 12) {
        hour24 = 0;
      }
      
      _selectedTime = TimeOfDay(hour: hour24, minute: minute);
      _selectedRingtoneUri = widget.existingAlarm!['ringtoneUri'] as String?;
      if (_selectedRingtoneUri != null) {
        _ringtoneName = 'Custom ringtone';
      }
    } else {
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingAlarm != null ? 'Edit alarm' : 'Add alarm',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  _selectTime(context);
                },
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDays[index] = !_selectedDays[index];
                      });
                    },
                    child: CircleDay(
                      day: days[index],
                      context: context,
                      isSelected: _selectedDays[index],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white30, height: 1),
              SwitchListTile(
                title: const Text(
                  'Alarm Notification',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                secondary: const Icon(Icons.notifications_none, color: Colors.white),
                value: _notificationEnabled,
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _notificationEnabled = value;
                  });
                },
              ),
              const Divider(color: Colors.white30, height: 1),
              SwitchListTile(
                title: const Text(
                  'Vibrate',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                secondary: const Icon(Icons.vibration, color: Colors.white),
                value: _vibrateEnabled,
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _vibrateEnabled = value;
                  });
                },
              ),
              const Divider(color: Colors.white30, height: 1),
              ListTile(
                leading: const Icon(Icons.music_note, color: Colors.white),
                title: const Text(
                  'Alarm sound',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  _ringtoneName,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white60),
                onTap: _selectRingtone,
              ),
              const Divider(color: Colors.white30, height: 1),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectRingtone() async {
    try {
      // Use platform channel to open Android's ringtone picker
      const platform = MethodChannel('flutter_alarmapp/ringtone');
      final String? result = await platform.invokeMethod('pickRingtone');
      
      if (result != null) {
        setState(() {
          _selectedRingtoneUri = result;
          // Extract ringtone name from URI or use a default name
          final uriParts = result.split('/');
          _ringtoneName = uriParts.isNotEmpty ? uriParts.last : 'Selected ringtone';
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting ringtone: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveAlarm() {
    final now = DateTime.now();
    final hour = _selectedTime.hour;
    final minute = _selectedTime.minute;
    
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If the time is in the past, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    String period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    String hourStr = _selectedTime.hourOfPeriod.toString().padLeft(2, '0');
    String minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    String time = '$hourStr:$minuteStr';
    
    Navigator.pop(context, {
      'time': time,
      'period': period,
      'scheduledTime': scheduledTime,
      'ringtoneUri': _selectedRingtoneUri,
    });
  }
}
