import 'dart:async';
import 'dart:developer';

import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/repositories/location/location_repository.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final class LocationUtility {
  factory LocationUtility() => _instance;

  LocationUtility._internal();

  static final LocationUtility _instance = LocationUtility._internal();

  static final _repo = LocationRepository();

  static LeafLocation? _location;

  LeafLocation? get location => _location;

  set location(LeafLocation? location) {
    // LeafLocation now has proper == and hashCode overrides for value equality
    if (location == _location) return;
    _location = location;
  }

  Future<LocationPermission> _getLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Gets the current GPS location and returns it WITHOUT saving to Hive.
  /// This should only be called when user explicitly requests their current location.
  ///
  /// To save the location, call LeafLocationCubit.setLocation() with the result.
  Future<LeafLocation?> getLocation(BuildContext context, {bool saveToHive = false}) async {
    final permission = await _getLocationPermission();
    final permissionGiven =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (permissionGiven && locationServiceEnabled) {
      await _getLiveLocation(saveToHive: saveToHive);
      return location;
    } else {
      _handlePermissionDenied(
        context,
        permission: permission,
        isLocationServiceEnabled: locationServiceEnabled,
      );
    }
    return null;
  }

  /// Fetches the current GPS location.
  ///
  /// [saveToHive] - If true, saves the location to Hive. Default is false.
  /// This prevents automatic overwriting of user's manually selected location.
  Future<void> _getLiveLocation({bool saveToHive = false}) async {
    // First, try to get last known position for immediate feedback
    // This provides a faster initial experience while we fetch the current position
    Position? lastKnownPosition;
    try {
      lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null && location == null) {
        // Use last known position immediately for faster initial load
        location = await getLeafLocationFromLatLng(
          latitude: lastKnownPosition.latitude,
          longitude: lastKnownPosition.longitude,
        );
        log('Using last known position for initial load', name: '_getLiveLocation');
      }
    } on Exception catch (e) {
      log('Failed to get last known position: $e', name: '_getLiveLocation');
    }

    // Now fetch the current position in the background
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          timeLimit: const Duration(seconds: 30),
        ),
      );
    } on TimeoutException catch (_) {
      // If current position times out, we already have last known position
      log('Current position timed out, using last known', name: '_getLiveLocation');
      position = lastKnownPosition;
    } on Exception catch (e, stack) {
      log('$e', name: '_getLiveLocation');
      log('$stack', name: '_getLiveLocation');
    }

    if (position == null) {
      _getPersistedLocation();
    } else {
      bool shouldFetch = true;
      if (location?.hasCoordinates ?? false) {
        final newCoordinates = LatLng(position.latitude, position.longitude);
        final oldCoordinates = LatLng(
          location!.latitude!,
          location!.longitude!,
        );
        shouldFetch = _shouldReFetch(oldCoordinates, newCoordinates);
      }
      if (shouldFetch) {
        location = await getLeafLocationFromLatLng(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    }

    // Only save to Hive if explicitly requested (when user taps "Use My Location")
    // This prevents automatic overwriting of user's manually selected location
    if (saveToHive && location != null) {
      HiveUtils.setLocationV2(location: location!);
      log('GPS location saved to Hive', name: '_getLiveLocation');
    }
  }

  /// Determines whether the location is far enough from the previous one
  /// to justify re-fetching data from the server.
  ///
  /// This helps avoid unnecessary API calls if the user hasn't moved much,
  /// especially when spamming the "my location" button.
  ///
  /// Returns `true` if the distance between [oldCoordinates] and [newCoordinates]
  /// is greater than 3 km.
  bool _shouldReFetch(LatLng oldCoordinates, LatLng newCoordinates) {
    final distance = Geolocator.distanceBetween(
      oldCoordinates.latitude,
      oldCoordinates.longitude,
      newCoordinates.latitude,
      newCoordinates.longitude,
    );

    return distance > 3000;
  }

  void _getPersistedLocation() {
    location = HiveUtils.getLocationV2() ?? Constant.defaultLocation;
  }

  Future<LeafLocation> getLeafLocationFromLatLng({
    required double latitude,
    required double longitude,
  }) async {
    return await _repo.getLocationFromLatLng(
      latitude: latitude,
      longitude: longitude,
    );
  }

  void _handlePermissionDenied(
    BuildContext context, {
    required LocationPermission permission,
    required bool isLocationServiceEnabled,
  }) {
    LoadingWidgets.hideLoader(context);

    if (permission == LocationPermission.denied) {
      _showPermissionDeniedMessage(context);
    } else if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedForeverDialog(context);
    } else if (!isLocationServiceEnabled) {
      _showLocationServiceDisabledDialog(context);
    }
  }

  void _showPermissionDeniedForeverDialog(BuildContext context) {
    UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        svgImagePath: AppIcons.locationDenied,
        title: 'locationPermissionDenied'.translate(context),
        content: CustomText('weNeedLocationAvailableLbl'.translate(context)),
        cancelButtonName: 'cancelBtnLbl'.translate(context),
        acceptButtonName: 'settingsLbl'.translate(context),
        onAccept: () {
          Geolocator.openAppSettings();
          return Future.value();
        },
      ),
    );
  }

  void _showPermissionDeniedMessage(BuildContext context) {
    HelperUtils.showSnackBarMessage(
      context,
      'locationPermissionDenied'.translate(context),
    );
  }

  void _showLocationServiceDisabledDialog(BuildContext context) {
    UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        svgImagePath: AppIcons.locationDenied,
        title: 'locationServiceDisabled'.translate(context),
        content: CustomText(
          'pleaseEnableLocationServicesManually'.translate(context),
        ),
        cancelButtonName: 'cancelBtnLbl'.translate(context),
        acceptButtonName: 'settingsLbl'.translate(context),
        onAccept: () {
          Geolocator.openLocationSettings();
          return Future.value();
        },
      ),
    );
  }
}
