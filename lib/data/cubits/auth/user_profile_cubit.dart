import 'dart:developer';

import 'package:eClassify/data/model/user/user_model.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UserProfileState {}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileSuccess extends UserProfileState {
  UserProfileSuccess({required this.user});

  final UserModel user;
}

class UserProfileFailure extends UserProfileState {
  UserProfileFailure({required this.errorMessage});

  final String errorMessage;
}

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit() : super(UserProfileInitial());

  Future<void> getUserProfile() async {
    try {
      emit(UserProfileLoading());

      final response = await Api.get(url: Api.userProfile);

      final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);
      HiveUtils.setUserData(response['data']);

      emit(UserProfileSuccess(user: user));
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'getUserProfile');
      log('$stack', name: 'getUserProfile');
      emit(UserProfileFailure(errorMessage: e.toString()));
    }
  }
}
