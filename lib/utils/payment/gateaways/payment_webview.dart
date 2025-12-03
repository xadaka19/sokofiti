import 'dart:developer';

import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String authorizationUrl;
  final String? reference;
  final Function(String) onSuccess;
  final Function(String) onFailed;
  final Function() onCancel;

  const PaymentWebView({
    Key? key,
    required this.authorizationUrl,
    this.reference,
    required this.onSuccess,
    required this.onFailed,
    required this.onCancel,
  }) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onUrlChange: (UrlChange change) {
            final url = change.url ?? '';
            log('$url');
            if (url.contains("Completed") ||
                url.contains("completed") ||
                url.toLowerCase().contains("success")) {
              widget.onSuccess(widget.reference ?? '');
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the WebView
            } else if (url.contains("Failed") ||
                url.contains("failed") ||
                url.contains("cancel")) {
              widget.onFailed(widget.reference ?? '');

              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the WebView
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = request.url;
            log('${uri.toString()}', name: 'NAVIGATION');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText('payment'.translate(context)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
