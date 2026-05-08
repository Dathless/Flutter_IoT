import 'package:flutter/material.dart';

class LedControl extends StatefulWidget {
  final Function(bool) onToggle;
  const LedControl({super.key, required this.onToggle});

  @override
  // ignore: library_private_types_in_public_api
  _LedControlState createState() => _LedControlState();
}

class _LedControlState extends State<LedControl> {
  bool isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.lightbulb,
        color: isSwitched ? Colors.yellow : Colors.grey,
        size: 30,
      ),
      title: Text(
        "Phòng khách - LED",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Switch(
        value: isSwitched,
        onChanged: (value) {
          setState(() => isSwitched = value);
          widget.onToggle(value);
        },
        activeThumbColor: Colors.orangeAccent,
      ),
    );
  }
}
