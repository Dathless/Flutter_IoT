import 'package:flutter/material.dart';

class ServoControl extends StatelessWidget {
  final String frontStatus;
  final String backStatus;
  final String frontTitle;
  final String backTitle;
  final bool isBusy;
  final Function(String door, String action) onCommand;

  const ServoControl({
    super.key,
    required this.frontStatus,
    required this.backStatus,
    required this.frontTitle,
    required this.backTitle,
    required this.onCommand,
    this.isBusy = false,
  });

  Widget _buildServoCard(
    BuildContext context,
    String title,
    String status,
    String door,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Trạng thái: $status',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withAlpha(180),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : () => onCommand(door, 'open'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Mở'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : () => onCommand(door, 'close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Đóng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildServoCard(context, frontTitle, frontStatus, 'front'),
        SizedBox(height: 15),
        _buildServoCard(context, backTitle, backStatus, 'back'),
      ],
    );
  }
}
