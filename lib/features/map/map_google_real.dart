import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:para_po/core/models/models.dart';
import 'package:para_po/core/theme/app_theme.dart';

const _kCabuyao = LatLng(14.2724, 121.1241);

GoogleMapController? _ctrl;
MapType _mapType = MapType.normal;
Set<Marker>   _markers   = {};
Set<Polyline> _polylines = {};

void toggleMapType() {
  _mapType = _mapType == MapType.normal ? MapType.satellite : MapType.normal;
}

void goToMyLocation() {
  _ctrl?.animateCamera(CameraUpdate.newCameraPosition(
      const CameraPosition(target: _kCabuyao, zoom: 14)));
}

void updateRoute({
  List<AppLatLng>? polyline,
  AppLatLng? originPin,
  AppLatLng? destPin,
  bool showRoute = false,
}) {
  final markers   = <Marker>{};
  final polylines = <Polyline>{};

  if (originPin != null) {
    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(originPin.lat, originPin.lng),
      infoWindow: const InfoWindow(title: 'Point A – Origin'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));
  }
  if (destPin != null) {
    markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: LatLng(destPin.lat, destPin.lng),
      infoWindow: const InfoWindow(title: 'Point B – Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    ));
  }

  if (polyline != null && polyline.length > 1) {
    final gmPts = polyline.map((p) => LatLng(p.lat, p.lng)).toList();
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points:    gmPts,
      color:     AppColors.blue,
      width:     5,
      startCap:  Cap.roundCap,
      endCap:    Cap.roundCap,
      jointType: JointType.round,
    ));

    final lats = gmPts.map((p) => p.latitude).toList();
    final lngs = gmPts.map((p) => p.longitude).toList();
    _ctrl?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
        northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      ),
      80,
    ));
  }

  _markers   = markers;
  _polylines = polylines;
}

Widget buildGoogleMap({required Function onMapCreated}) {
  return GoogleMap(
    onMapCreated: (c) { _ctrl = c; onMapCreated(c); },
    initialCameraPosition: const CameraPosition(target: _kCabuyao, zoom: 13),
    mapType: _mapType,
    markers: _markers,
    polylines: _polylines,
    myLocationEnabled: true,
    myLocationButtonEnabled: false,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
  );
}
