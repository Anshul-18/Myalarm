import 'package:flutter_alarmapp/widgets/circle_day.dart';
import 'package:flutter/material.dart';

class AddAlarmPage extends StatefulWidget {
  const AddAlarmPage({super.key});

  @override
  _AddAlarmPageState createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage> {
  late TimeOfDay _selectedTime;
  bool _notificationEnabled = true;
  bool _vibrateEnabled = true;
  final List<bool> _selectedDays = [true, true, true, true, true, false, false]; // Mon-Sun

  @override
  void initState() {
    _selectedTime = TimeOfDay.now();
    super.initState();
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
        title: const Text(
          'Add alarm',
          style: TextStyle(
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
    });
  }
}
