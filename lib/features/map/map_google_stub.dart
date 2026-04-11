import 'package:flutter/material.dart';
import 'package:para_po/core/models/models.dart';

void toggleMapType() {}
void goToMyLocation() {}
void updateRoute({
  List<AppLatLng>? polyline,
  AppLatLng? originPin,
  AppLatLng? destPin,
  bool showRoute = false,
}) {}
Widget buildGoogleMap({required Function onMapCreated}) =>
    const SizedBox.shrink();
