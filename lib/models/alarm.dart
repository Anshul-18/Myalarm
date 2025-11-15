import 'package:flutter/material.dart';

class Alarm {
  final int id;
  final TimeOfDay time;
  final List<bool> days;
  final bool isEnabled;

  Alarm({
    required this.id,
    required this.time,
    required this.days,
    this.isEnabled = true,
  });
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  String format(BuildContext context) {
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour > 12 ? hour - 12 : hour;
    displayHour = displayHour == 0 ? 12 : displayHour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
