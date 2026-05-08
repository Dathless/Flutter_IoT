import 'package:flutter/material.dart';
import 'dart:async';

class GasWarningBar extends StatefulWidget {
  final DateTime timestamp;
  final VoidCallback onClose;

  const GasWarningBar({
    super.key,
    required this.timestamp,
    required this.onClose,
  });

  @override
  State<GasWarningBar> createState() => _GasWarningBarState();
}

class _GasWarningBarState extends State<GasWarningBar> {
  late Timer _colorTimer;
  Color _currentColor = Colors.amber;

  @override
  void initState() {
    super.initState();
    _updateColor();
    // Cập nhật màu sắc mỗi 30 giây
    _colorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateColor();
    });
  }

  void _updateColor() {
    final diff = DateTime.now().difference(widget.timestamp).inMinutes;
    setState(() {
      if (diff >= 10) {
        _currentColor = Colors.red;
      } else if (diff >= 5) {
        // Chuyển dần từ Vàng sang Đỏ (Orange)
        _currentColor = Colors.orange;
      } else {
        _currentColor = Colors.amber;
      }
    });
  }

  @override
  void dispose() {
    _colorTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _currentColor,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "CẢNH BÁO GAS NGUY HIỂM",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Phát hiện lúc: ${widget.timestamp.hour}:${widget.timestamp.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }
}
