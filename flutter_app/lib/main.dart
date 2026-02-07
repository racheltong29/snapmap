import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const SmappedApp());
}

class SmappedApp extends StatelessWidget {
  const SmappedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smapped',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SmappedHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SmappedHome extends StatefulWidget {
  const SmappedHome({Key? key}) : super(key: key);

  @override
  State<SmappedHome> createState() => _SmappedHomeState();
}

class _SmappedHomeState extends State<SmappedHome> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://localhost:5173')); // Dev server
      // For production, replace with: Uri.parse('https://your-domain.com')
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
