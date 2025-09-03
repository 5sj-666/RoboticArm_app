import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({required this.url});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  bool _isLoading = true;
  // late finale WebViewController controller;
  late final WebViewController controller;

  @override
  void initState() {
    controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(Color(0x00000000));
    // controller.setUserAgent(
    //     'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3');
    controller.loadRequest(Uri.parse(widget.url));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller,
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
