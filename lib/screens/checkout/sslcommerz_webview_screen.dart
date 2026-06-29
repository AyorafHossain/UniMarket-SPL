import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/sslcommerz_config.dart';

class SSLCommerzWebViewScreen extends StatefulWidget {
  final String url;

  const SSLCommerzWebViewScreen({super.key, required this.url});

  @override
  State<SSLCommerzWebViewScreen> createState() => _SSLCommerzWebViewScreenState();
}

class _SSLCommerzWebViewScreenState extends State<SSLCommerzWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('SSLCommerz redirect URL: $url');
            
            // Check for success URL
            if (url.startsWith(SSLCommerzConfig.successUrl) || url.contains('/success')) {
              Navigator.pop(context, 'success');
              return NavigationDecision.prevent;
            }
            // Check for fail URL
            if (url.startsWith(SSLCommerzConfig.failUrl) || url.contains('/fail')) {
              Navigator.pop(context, 'failed');
              return NavigationDecision.prevent;
            }
            // Check for cancel URL
            if (url.startsWith(SSLCommerzConfig.cancelUrl) || url.contains('/cancel')) {
              Navigator.pop(context, 'cancelled');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Treat explicit close as cancellation
            Navigator.pop(context, 'cancel');
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
