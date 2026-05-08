import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
                  Colors.grey,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "$value$unit",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
