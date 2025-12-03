import 'package:eClassify/ui/screens/widgets/location_map/location_map_controller.dart';
import 'package:eClassify/ui/screens/widgets/location_map/location_map_widget.dart';
import 'package:flutter/material.dart';

class GoogleMapScreen extends StatelessWidget {
  const GoogleMapScreen({super.key, required this.controller});

  final LocationMapController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LocationMapWidget(
          controller: controller,
          showMyLocationButton: false,
          interactive: false,
          showMarker: false,
        ),
      ),
    );
  }
}
