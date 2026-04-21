import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String paymentSessionId;
  final String orderId;

  const PaymentWebviewScreen({
    super.key,
    required this.paymentSessionId,
    required this.orderId,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
        <style>
          body { display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: sans-serif; background: #ffffff; }
          .loader { border: 4px solid #f3f3f3; border-top: 4px solid #4C00C2; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; }
          @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        </style>
    </head>
    <body>
        <div class="loader"></div>
        <script>
            const cashfree = Cashfree({ mode: "production" });
            cashfree.checkout({ paymentSessionId: "${widget.paymentSessionId}" });
        </script>
    </body>
    </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('nlitedu.com/enroll') && request.url.contains('payment_status=')) {
              final uri = Uri.parse(request.url);
              final status = uri.queryParameters['payment_status'];
              
              if (status == 'SUCCESS') {
                Navigator.of(context).pop(true);
              } else {
                Navigator.of(context).pop(false);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Checkout', style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
