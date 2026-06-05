import 'package:flutter/material.dart';

class LedControl extends StatelessWidget {
  final String title;
  final bool isSwitched;
  final Function(bool) onToggle;

  const LedControl({
    super.key,
    required this.title,
    required this.isSwitched,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.lightbulb,
        color: isSwitched ? Colors.yellow : Colors.grey,
        size: 30,
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: isSwitched,
        onChanged: onToggle,
        activeThumbColor: Colors.orangeAccent,
      ),
    );
  }
}
