import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_alarm_page.dart';
import 'alarm_ringing_page.dart';
import 'stopwatch_page.dart';
import 'timer_page.dart';
import '../services/alarm_service.dart';

class AlarmInfo {
  final String time;
  final String period;
  bool isEnabled;
  final int id;
  final DateTime scheduledTime;
  final String? ringtoneUri;

  AlarmInfo({
    required this.time,
    required this.period,
    this.isEnabled = true,
    required this.id,
    required this.scheduledTime,
    this.ringtoneUri,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AlarmInfo> alarms = [];
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  static const platform = MethodChannel('flutter_alarmapp/alarm');

  @override
  void initState() {
    super.initState();
    AlarmService.initialize();
    _setupAlarmListener();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setupAlarmListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showAlarmRinging') {
        final int alarmId = call.arguments['alarmId'] ?? 0;
        final String time = call.arguments['time'] ?? 'Alarm';
        
        // Find the alarm to get its time
        AlarmInfo? alarm;
        try {
          alarm = alarms.firstWhere((a) => a.id == alarmId);
        } catch (e) {
          alarm = null;
        }
        
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlarmRingingPage(
                alarmId: alarmId,
                time: alarm?.time ?? time,
              ),
            ),
          );
        }
      }
    });
  }

  void _addAlarm(String time, String period, DateTime scheduledTime, {String? ringtoneUri}) {
    setState(() {
      final id = DateTime.now().millisecondsSinceEpoch % 100000;
      alarms.add(AlarmInfo(
        time: time,
        period: period,
        id: id,
        scheduledTime: scheduledTime,
        ringtoneUri: ringtoneUri,
      ));

      if (scheduledTime.isAfter(DateTime.now())) {
        AlarmService.scheduleAlarm(
          id,
          'Alarm',
          'Time to wake up!',
          scheduledTime,
          ringtoneUri: ringtoneUri,
          displayTime: '$time $period',
        );
      }
    });
  }

  void _toggleAlarm(int index, bool value) {
    setState(() {
      alarms[index].isEnabled = value;
      if (value) {
        AlarmService.scheduleAlarm(
          alarms[index].id,
          'Alarm',
          'Time to wake up!',
          alarms[index].scheduledTime,
          ringtoneUri: alarms[index].ringtoneUri,
          displayTime: '${alarms[index].time} ${alarms[index].period}',
        );
      } else {
        AlarmService.cancelAlarm(alarms[index].id);
      }
    });
  }

  void _deleteAlarm(int index) {
    AlarmService.cancelAlarm(alarms[index].id);
    setState(() {
      alarms.removeAt(index);
    });
  }

  void _editAlarm(int index) async {
    final alarm = alarms[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAlarmPage(
          existingAlarm: {
            'time': alarm.time,
            'period': alarm.period,
            'scheduledTime': alarm.scheduledTime,
            'ringtoneUri': alarm.ringtoneUri,
          },
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      // Cancel old alarm first
      await AlarmService.cancelAlarm(alarm.id);
      
      // Update alarm
      setState(() {
        alarms[index] = AlarmInfo(
          time: result['time']!,
          period: result['period']!,
          id: alarm.id, // Keep same ID
          scheduledTime: result['scheduledTime'] as DateTime,
          ringtoneUri: result['ringtoneUri'] as String?,
          isEnabled: true,
        );
      });
      
      // Schedule updated alarm with the new time
      final scheduledTime = result['scheduledTime'] as DateTime;
      if (scheduledTime.isAfter(DateTime.now())) {
        await AlarmService.scheduleAlarm(
          alarm.id,
          'Alarm',
          'Time to wake up!',
          scheduledTime,
          ringtoneUri: result['ringtoneUri'] as String?,
          displayTime: '${result['time']} ${result['period']}',
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alarm updated'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.grey[800],
        ),
      );
    }
  }

  void _showDeleteAllDialog() {
    if (alarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No alarms to delete'),
          backgroundColor: Colors.grey[800],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Delete all alarms?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will delete all ${alarms.length} alarm(s).',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              for (var alarm in alarms) {
                AlarmService.cancelAlarm(alarm.id);
              }
              setState(() {
                alarms.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All alarms deleted'),
                  backgroundColor: Colors.grey[800],
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        children: [
          _buildAlarmPage(),
          StopwatchPage(
            selectedIndex: _selectedTabIndex,
            onNavigate: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          TimerPage(
            selectedIndex: _selectedTabIndex,
            onNavigate: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmPage() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Alarm',
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
              if (value == 'delete_all') {
                _showDeleteAllDialog();
              } else if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings - Coming soon!'),
                    backgroundColor: Colors.grey[800],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Delete all alarms', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: alarms.isEmpty
                    ? const Center(
                        child: Text(
                          'No alarms',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        itemCount: alarms.length,
                        itemBuilder: (context, index) {
                          return _buildAlarmCard(index);
                        },
                      ),
              ),
              _buildBottomNavigation(),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddAlarmPage()),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    _addAlarm(
                      result['time']!,
                      result['period']!,
                      result['scheduledTime'] as DateTime,
                      ringtoneUri: result['ringtoneUri'] as String?,
                    );
                  }
                },
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(int index) {
    final alarm = alarms[index];
    return Dismissible(
      key: Key(alarm.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteAlarm(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Alarm deleted'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey[800],
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: GestureDetector(
        onLongPress: () {
          _showAlarmOptions(index);
        },
        onTap: () {
          _editAlarm(index);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.time,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            alarm.period,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ring once',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                onChanged: (value) => _toggleAlarm(index, value),
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.5),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlarmOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text('Edit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _editAlarm(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAlarm(index);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
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
