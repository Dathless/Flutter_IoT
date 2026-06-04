import 'package:flutter/material.dart';

class UrlSetup extends StatefulWidget {
  final Future<String?> Function(String) onConnect;

  const UrlSetup({super.key, required this.onConnect});

  @override
  _UrlSetupState createState() => _UrlSetupState();
}

class _UrlSetupState extends State<UrlSetup> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Đặt URL mặc định
    _urlController.text = "http://";
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || url == "http://") {
      setState(() {
        _errorMessage = "Vui lòng nhập URL hoặc IP";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final errorMessage = await widget.onConnect(url);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nhập URL hoặc IP Raspberry Pi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: _urlController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: "Ví dụ: http://192.168.1.100:8000",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            suffixIcon: _isLoading
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    onPressed: _isLoading ? null : _handleConnect,
                  ),
            errorText: _errorMessage,
          ),
          onSubmitted: (_) => _handleConnect(),
        ),
        if (_errorMessage != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleConnect,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blue,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Kết nối",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
