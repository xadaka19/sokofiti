import 'dart:developer';

import 'package:eClassify/settings.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/payment/gateaways/payment_webview.dart';
import 'package:flutter/material.dart';

/// PayStack payment service for handling payments in Africa
/// Supports M-Pesa, card payments, and bank transfers
class PayStackService {
  /// Initialize PayStack with public key from settings
  static void initPayStack() {
    if (AppSettings.payStackStatus != 1) {
      log('PayStack is disabled', name: 'PayStackService');
      return;
    }
    if (AppSettings.payStackKey.isEmpty) {
      log('PayStack public key is not set', name: 'PayStackService');
      return;
    }
    log('PayStack initialized with key: ${AppSettings.payStackKey.substring(0, 10)}...', 
        name: 'PayStackService');
  }

  /// Start PayStack payment via WebView
  /// 
  /// [context] - BuildContext for navigation
  /// [authorizationUrl] - The authorization URL from backend
  /// [reference] - Transaction reference
  /// [onSuccess] - Callback when payment is successful
  /// [onFailed] - Callback when payment fails
  /// [onCancel] - Callback when user cancels payment
  static Future<void> startPayment({
    required BuildContext context,
    required String authorizationUrl,
    required String reference,
    required Function(String reference) onSuccess,
    required Function(String reference) onFailed,
    required VoidCallback onCancel,
  }) async {
    if (AppSettings.payStackStatus != 1) {
      HelperUtils.showSnackBarMessage(
        context,
        'PayStack is not enabled',
        type: MessageType.error,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebView(
          authorizationUrl: authorizationUrl,
          reference: reference,
          onSuccess: onSuccess,
          onFailed: onFailed,
          onCancel: onCancel,
        ),
      ),
    );
  }

  /// Get user email for PayStack (required field)
  static String getUserEmail() {
    final userDetails = HiveUtils.getUserDetails();
    return userDetails.email ?? 'customer@sokofiti.com';
  }

  /// Get user phone for M-Pesa payments
  static String? getUserPhone() {
    final userDetails = HiveUtils.getUserDetails();
    return userDetails.mobile;
  }

  /// Format amount for PayStack (amount in smallest currency unit - cents/kobo)
  static int formatAmount(double amount) {
    // PayStack expects amount in smallest currency unit
    // For KES: 1 KES = 100 cents
    return (amount * 100).round();
  }

  /// Handle successful payment
  static void handleSuccess(BuildContext context, String reference) {
    HelperUtils.showSnackBarMessage(
      context,
      'paymentSuccessfullyCompleted'.translate(context),
    );
    log('PayStack payment successful. Reference: $reference', 
        name: 'PayStackService');
  }

  /// Handle failed payment
  static void handleFailure(BuildContext context, String reference) {
    HelperUtils.showSnackBarMessage(
      context,
      'purchaseFailed'.translate(context),
      type: MessageType.error,
    );
    log('PayStack payment failed. Reference: $reference', 
        name: 'PayStackService');
  }

  /// Verify payment status (should be done on backend)
  /// This is just a placeholder - actual verification should happen server-side
  static Future<bool> verifyPayment(String reference) async {
    // Payment verification should be done on the backend
    // This method is here for reference only
    log('Payment verification should be done on backend for reference: $reference',
        name: 'PayStackService');
    return true;
  }

  /// Get supported PayStack channels for Kenya
  static List<String> getSupportedChannels() {
    return [
      'card',           // Card payments
      'bank',           // Bank transfers
      'mobile_money',   // M-Pesa
      'ussd',           // USSD
    ];
  }
}

