// import 'package:flutter/material.dart' hide TimeOfDay;
// import '../models/alarm.dart';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:alarm_app/models/alarm.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Alarm> alarms = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alarms'),
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return ListTile(
            title: Text(alarm.time.format(context)),
            subtitle: Text(_getDaysText(alarm.days)),
            trailing: Switch(
              value: alarm.isEnabled,
              onChanged: (value) {
                // Handle alarm toggle
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getDaysText(List<bool> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = <String>[];
    for (var i = 0; i < days.length; i++) {
      if (days[i]) activeDays.add(dayNames[i]);
    }
    return activeDays.isEmpty ? 'One time' : activeDays.join(', ');
  }

  void _showAddAlarmDialog(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((pickedTime) {
      if (pickedTime != null) {
        // Handle new alarm creation
      }
    });
  }
}
