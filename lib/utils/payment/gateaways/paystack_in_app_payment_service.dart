import 'dart:developer';

import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/payment/gateaways/paystack_service.dart';
import 'package:flutter/material.dart';

/// PayStack In-App Payment Service
/// Handles the complete payment flow for subscriptions and in-app purchases
class PayStackInAppPaymentService {
  /// Process a subscription payment via PayStack
  /// 
  /// [context] - BuildContext for UI operations
  /// [packageId] - The subscription package ID
  /// [amount] - Amount to charge
  /// [paymentIntentData] - Data from backend containing authorization_url
  static Future<void> processSubscriptionPayment({
    required BuildContext context,
    required int packageId,
    required double amount,
    required Map<String, dynamic> paymentIntentData,
  }) async {
    try {
      // Extract authorization URL from payment intent response
      final authorizationUrl = paymentIntentData['payment_gateway_response']
          ?['authorization_url'] as String?;
      final reference = paymentIntentData['payment_gateway_response']
          ?['reference'] as String? ?? 
          paymentIntentData['id']?.toString() ?? '';

      if (authorizationUrl == null || authorizationUrl.isEmpty) {
        throw Exception('Authorization URL not provided');
      }

      log('Starting PayStack payment with reference: $reference',
          name: 'PayStackInAppPaymentService');

      // Start the PayStack payment flow
      await PayStackService.startPayment(
        context: context,
        authorizationUrl: authorizationUrl,
        reference: reference,
        onSuccess: (ref) async {
          await _handlePaymentSuccess(context, ref, packageId);
        },
        onFailed: (ref) {
          _handlePaymentFailure(context, ref);
        },
        onCancel: () {
          _handlePaymentCancelled(context);
        },
      );
    } catch (e) {
      log('PayStack payment error: $e', name: 'PayStackInAppPaymentService');
      HelperUtils.showSnackBarMessage(
        context,
        'Payment initialization failed: ${e.toString()}',
        type: MessageType.error,
      );
    }
  }

  /// Handle successful payment
  static Future<void> _handlePaymentSuccess(
    BuildContext context,
    String reference,
    int packageId,
  ) async {
    log('Payment successful. Reference: $reference, Package: $packageId',
        name: 'PayStackInAppPaymentService');

    PayStackService.handleSuccess(context, reference);

    // Navigate back to home or subscription screen
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Handle payment failure
  static void _handlePaymentFailure(BuildContext context, String reference) {
    log('Payment failed. Reference: $reference',
        name: 'PayStackInAppPaymentService');

    PayStackService.handleFailure(context, reference);
  }

  /// Handle payment cancellation
  static void _handlePaymentCancelled(BuildContext context) {
    log('Payment cancelled by user', name: 'PayStackInAppPaymentService');

    HelperUtils.showSnackBarMessage(
      context,
      'paymentCancelled'.translate(context),
      type: MessageType.warning,
    );
  }

  /// Process featured ad payment via PayStack
  static Future<void> processFeaturedAdPayment({
    required BuildContext context,
    required int itemId,
    required double amount,
    required Map<String, dynamic> paymentIntentData,
  }) async {
    try {
      final authorizationUrl = paymentIntentData['payment_gateway_response']
          ?['authorization_url'] as String?;
      final reference = paymentIntentData['payment_gateway_response']
          ?['reference'] as String? ?? 
          paymentIntentData['id']?.toString() ?? '';

      if (authorizationUrl == null || authorizationUrl.isEmpty) {
        throw Exception('Authorization URL not provided');
      }

      await PayStackService.startPayment(
        context: context,
        authorizationUrl: authorizationUrl,
        reference: reference,
        onSuccess: (ref) async {
          log('Featured ad payment successful. Reference: $ref',
              name: 'PayStackInAppPaymentService');
          PayStackService.handleSuccess(context, ref);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        onFailed: (ref) => PayStackService.handleFailure(context, ref),
        onCancel: () => _handlePaymentCancelled(context),
      );
    } catch (e) {
      log('Featured ad payment error: $e', name: 'PayStackInAppPaymentService');
      HelperUtils.showSnackBarMessage(
        context,
        'Payment failed: ${e.toString()}',
        type: MessageType.error,
      );
    }
  }
}

