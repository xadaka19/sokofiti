import 'dart:async';

import 'package:eClassify/ui/screens/widgets/location_map/location_map_controller.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMapWidget extends StatefulWidget {
  const LocationMapWidget({
    required this.controller,
    this.showCircleArea = true,
    this.showMarker = true,
    this.showMyLocationButton = true,
    this.interactive = true,
    super.key,
  });

  final LocationMapController controller;
  final bool showCircleArea;
  final bool showMarker;
  final bool showMyLocationButton;
  final bool interactive;

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  Timer? _tapCooldown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.init(),
    );
  }

  @override
  void dispose() {
    _tapCooldown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            if (!widget.controller.isReady) {
              return Center(child: UiUtils.progress());
            }

            final mapData = widget.controller.data;

            return GoogleMap(
              initialCameraPosition: mapData.cameraPosition,
              onMapCreated: widget.controller.onMapCreated,
              circles: widget.showCircleArea ? {mapData.circle} : {},
              markers: widget.showMarker ? {mapData.marker} : {},
              onTap: widget.interactive ? widget.controller.onTap : null,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
              compassEnabled: false,
              indoorViewEnabled: true,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
            );
          },
        ),
        if (widget.showMyLocationButton)
          PositionedDirectional(
            end: 15,
            bottom: 15,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: context.color.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                fixedSize: Size.square(40), // Size of a mini FAB
              ),
              onPressed: () {
                if (_tapCooldown?.isActive ?? false) return;

                widget.controller.getLocation(context);

                _tapCooldown = Timer(const Duration(seconds: 3), () {
                  _tapCooldown = null;
                });
              },
              icon: Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
}
