import 'package:flutter/material.dart';

class StepperControl extends StatefulWidget {
  final String status;
  final bool isBusy;
  final Function(String action, int times) onControl;

  const StepperControl({
    super.key,
    required this.status,
    required this.onControl,
    this.isBusy = false,
  });

  @override
  State<StepperControl> createState() => _StepperControlState();
}

class _StepperControlState extends State<StepperControl> {
  String _selectedAction = 'open';
  int _selectedTimes = 1;

  void _setAction(String action) {
    setState(() {
      _selectedAction = action;
    });
  }

  void _setTimes(int times) {
    setState(() {
      _selectedTimes = times;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trạng thái cửa gara: ${widget.status.toUpperCase()}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Hành động', style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isBusy ? null : () => _setAction('open'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedAction == 'open'
                          ? Colors.green.shade100
                          : null,
                    ),
                    child: Text('Mở'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isBusy ? null : () => _setAction('close'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedAction == 'close'
                          ? Colors.red.shade100
                          : null,
                    ),
                    child: Text('Đóng'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Số lần chuyển động',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: List.generate(4, (index) {
                final times = index + 1;
                return ChoiceChip(
                  label: Text(times.toString()),
                  selected: _selectedTimes == times,
                  onSelected: widget.isBusy ? null : (_) => _setTimes(times),
                );
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.isBusy
                  ? null
                  : () => widget.onControl(_selectedAction, _selectedTimes),
              child: Text(widget.isBusy ? 'Đang gửi...' : 'Gửi lệnh'),
            ),
          ],
        ),
      ),
    );
  }
}
