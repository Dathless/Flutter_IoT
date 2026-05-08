import 'package:flutter/material.dart';

class DisplayContentControl extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  DisplayContentControl({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Nhập nội dung hiển thị LCD...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            suffixIcon: IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                onSend(controller.text);
                controller.clear();
              },
            ),
          ),
        ),
      ],
    );
  }
}
