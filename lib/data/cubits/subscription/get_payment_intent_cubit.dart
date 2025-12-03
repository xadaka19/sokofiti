import 'dart:developer';

import 'package:eClassify/data/repositories/item/advertisement_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GetPaymentIntentState {}

class GetPaymentIntentInitial extends GetPaymentIntentState {}

class GetPaymentIntentInProgress extends GetPaymentIntentState {}

class GetPaymentIntentInSuccess extends GetPaymentIntentState {
  final Map<String, dynamic> paymentIntent;
  final String? message;

  GetPaymentIntentInSuccess(this.paymentIntent, this.message);
}

class GetPaymentIntentFailure extends GetPaymentIntentState {
  final dynamic error;

  GetPaymentIntentFailure(this.error);
}

class GetPaymentIntentCubit extends Cubit<GetPaymentIntentState> {
  GetPaymentIntentCubit() : super(GetPaymentIntentInitial());
  AdvertisementRepository repository = AdvertisementRepository();

  void getPaymentIntent({
    required int packageId,
    required String paymentMethod,
  }) async {
    try {
      emit(GetPaymentIntentInProgress());

      final intent = await repository.getPaymentIntent(
        packageId: packageId,
        paymentMethod: paymentMethod,
      );

      emit(
        GetPaymentIntentInSuccess(
          intent['data']['payment_intent'] as Map<String, dynamic>? ?? {},
          intent['message'],
        ),
      );
    } on Exception catch (e, st) {
      log(e.toString());
      log('$st');
      emit(GetPaymentIntentFailure(e.toString()));
    }
  }
}
