import 'package:flutter/material.dart';

class CircleDay extends StatelessWidget {
  const CircleDay(
      {Key? key,
      required this.day,
      required this.context,
      required this.isSelected})
      : super(key: key);

  final String day;
  final BuildContext context;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.white38,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
