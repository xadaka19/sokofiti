import 'package:eClassify/data/model/home/home_slider.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/custom_exception.dart';
import 'package:eClassify/utils/network/network_availability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SliderState {}

class SliderInitial extends SliderState {}

class SliderFetchInProgress extends SliderState {}

class SliderFetchInInternalProgress extends SliderState {}

class SliderFetchSuccess extends SliderState {
  List<HomeSlider> sliderlist = [];

  SliderFetchSuccess(this.sliderlist);

  factory SliderFetchSuccess.fromMap(Map<String, dynamic> map) {
    return SliderFetchSuccess(
      List<HomeSlider>.from(
        (map['sliderlist']).map<HomeSlider>(
          (x) => HomeSlider.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class SliderFetchFailure extends SliderState {
  final String errorMessage;
  final bool isUserDeactivated;

  SliderFetchFailure(this.errorMessage, this.isUserDeactivated);
}

class SliderCubit extends Cubit<SliderState> {
  SliderCubit() : super(SliderInitial());

  void fetchSlider(
    BuildContext context, {
    bool? forceRefresh,
    bool? loadWithoutDelay,
  }) async {
    if (forceRefresh != true) {
      if (state is SliderFetchSuccess) {
        await Future.delayed(
          Duration(
            seconds: loadWithoutDelay == true
                ? 0
                : AppSettings.hiddenAPIProcessDelay,
          ),
        );
      } else {
        emit(SliderFetchInProgress());
      }
    } else {
      emit(SliderFetchInProgress());
    }

    if (forceRefresh == true) {
      fetchSliderFromDb()
          .then((value) => emit(SliderFetchSuccess(value)))
          .catchError((e) {
            if (isClosed) return;
            bool isUserActive = true;
            if (e.toString() ==
                "your account has been deactivate! please contact admin") {
              isUserActive = false;
            } else {
              isUserActive = true;
            }
            emit(
              SliderFetchFailure(e.toString(), isUserActive),
            ); //, isUserActive
          });
    } else {
      if (state is! SliderFetchSuccess) {
        fetchSliderFromDb()
            .then((value) => emit(SliderFetchSuccess(value)))
            .catchError((e) {
              if (isClosed) return;
              bool isUserActive = true;
              if (e.toString() ==
                  "your account has been deactivate! please contact admin") {
                //message from API
                isUserActive = false;
              } else {
                isUserActive = true;
              }
              emit(
                SliderFetchFailure(e.toString(), isUserActive),
              ); //, isUserActive
            });
      } else {
        await CheckInternet.check(
          onInternet: () async {
            fetchSliderFromDb()
                .then((value) => emit(SliderFetchSuccess(value)))
                .catchError((e) {
                  if (isClosed) return;
                  bool isUserActive = true;
                  if (e.toString() ==
                      "your account has been deactivate! please contact admin") {
                    //message from API
                    isUserActive = false;
                  } else {
                    isUserActive = true;
                  }
                  emit(
                    SliderFetchFailure(e.toString(), isUserActive),
                  ); //, isUserActive
                });
          },
          onNoInternet: () {
            emit(SliderFetchSuccess((state as SliderFetchSuccess).sliderlist));
          },
        );
      }
    }

    Future.delayed(Duration.zero, () {});
  }

  Future<List<HomeSlider>> fetchSliderFromDb() async {
    List<HomeSlider> sliderList = [];

    var response = await Api.get(url: Api.getSliderApi, queryParameters: {});

    if (!response[Api.error]) {
      List list = response['data'];
      sliderList = list.map((model) => HomeSlider.fromJson(model)).toList();
    } else {
      throw CustomException(response[Api.message]);
    }

    return sliderList;
  }

  SliderState? fromJson(Map<String, dynamic> json) {
    try {
      return SliderFetchSuccess.fromMap(json);
    } catch (e) {
      return null;
    }
  }
}
