import 'package:flutter/material.dart';

// ── AppLatLng ─────────────────────────────────────────────────────────────────
class AppLatLng {
  final double lat;
  final double lng;
  const AppLatLng(this.lat, this.lng);
  @override String toString() => '($lat, $lng)';
}

// ── DirectionStep ─────────────────────────────────────────────────────────────
class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final AppLatLng endLocation;
  final String maneuver;

  const DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.endLocation,
    this.maneuver = '',
  });
}

// ── DirectionsResult ──────────────────────────────────────────────────────────
class DirectionsResult {
  final List<AppLatLng> polylinePoints;
  final List<DirectionStep> steps;
  final String totalDistance;
  final String totalDuration;
  final AppLatLng origin;
  final AppLatLng destination;

  const DirectionsResult({
    required this.polylinePoints,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.origin,
    required this.destination,
  });
}

// ── TransportModel ────────────────────────────────────────────────────────────
class TransportModel {
  final int? id;
  final String name;
  final double fare;
  final bool active;
  final String emoji;
  final double discountRate;

  const TransportModel({
    this.id,
    required this.name,
    required this.fare,
    required this.active,
    required this.emoji,
    this.discountRate = 0.20,
  });

  double fareFor(bool discounted) =>
      discounted ? (fare * (1 - discountRate)) : fare;

  factory TransportModel.fromMap(Map<String, dynamic> m) => TransportModel(
    id:           m['id'] as int?,
    name:         m['name'] as String,
    fare:         (m['fare'] as num).toDouble(),
    active:       (m['active'] as int) == 1,
    emoji:        m['emoji'] as String,
    discountRate: (m['discount_rate'] as num? ?? 0.20).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'fare': fare,
    'active': active ? 1 : 0,
    'emoji': emoji,
    'discount_rate': discountRate,
  };

  TransportModel copyWith({
    String? name, double? fare, bool? active, String? emoji, double? discountRate,
  }) => TransportModel(
    id: id,
    name: name ?? this.name,
    fare: fare ?? this.fare,
    active: active ?? this.active,
    emoji: emoji ?? this.emoji,
    discountRate: discountRate ?? this.discountRate,
  );
}

// ── RouteModel ────────────────────────────────────────────────────────────────
class RouteModel {
  final int? id;
  final String origin;
  final String destination;
  final double fare;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String transportType;
  final double distanceKm;

  const RouteModel({
    this.id,
    required this.origin,
    required this.destination,
    required this.fare,
    this.originLat = 14.2724,
    this.originLng = 121.1241,
    this.destLat   = 14.2724,
    this.destLng   = 121.1241,
    this.transportType = 'Jeepney',
    this.distanceKm = 0,
  });

  double fareFor(bool discounted) =>
      discounted ? (fare * 0.80) : fare;

  AppLatLng get originLatLng => AppLatLng(originLat, originLng);
  AppLatLng get destLatLng   => AppLatLng(destLat, destLng);

  factory RouteModel.fromMap(Map<String, dynamic> m) => RouteModel(
    id:            m['id'] as int?,
    origin:        m['origin'] as String,
    destination:   m['destination'] as String,
    fare:          (m['fare'] as num).toDouble(),
    originLat:     (m['origin_lat'] as num? ?? 14.2724).toDouble(),
    originLng:     (m['origin_lng'] as num? ?? 121.1241).toDouble(),
    destLat:       (m['dest_lat']   as num? ?? 14.2724).toDouble(),
    destLng:       (m['dest_lng']   as num? ?? 121.1241).toDouble(),
    transportType: m['transport_type'] as String? ?? 'Jeepney',
    distanceKm:    (m['distance_km'] as num? ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'origin': origin,
    'destination': destination,
    'fare': fare,
    'origin_lat': originLat,
    'origin_lng': originLng,
    'dest_lat': destLat,
    'dest_lng': destLng,
    'transport_type': transportType,
    'distance_km': distanceKm,
  };
}

// ── TerminalModel ─────────────────────────────────────────────────────────────
class TerminalModel {
  final int? id;
  final String category;
  final String name;
  final String description;
  final String emoji;
  final double lat;
  final double lng;

  const TerminalModel({
    this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.emoji,
    this.lat = 14.2724,
    this.lng = 121.1241,
  });

  AppLatLng get latLng => AppLatLng(lat, lng);

  factory TerminalModel.fromMap(Map<String, dynamic> m) => TerminalModel(
    id:          m['id'] as int?,
    category:    m['category'] as String,
    name:        m['name'] as String,
    description: m['description'] as String,
    emoji:       m['emoji'] as String,
    lat:         (m['lat'] as num? ?? 14.2724).toDouble(),
    lng:         (m['lng'] as num? ?? 121.1241).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category': category,
    'name': name,
    'description': description,
    'emoji': emoji,
    'lat': lat,
    'lng': lng,
  };
}

// ── ZoneModel ─────────────────────────────────────────────────────────────────
class ZoneModel {
  final int? id;
  final String name;
  final String colorHex;
  final int stopCount;

  const ZoneModel({
    this.id,
    required this.name,
    required this.colorHex,
    required this.stopCount,
  });

  factory ZoneModel.fromMap(Map<String, dynamic> m) => ZoneModel(
    id:        m['id'] as int?,
    name:      m['name'] as String,
    colorHex:  m['color_hex'] as String,
    stopCount: m['stop_count'] as int,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'color_hex': colorHex,
    'stop_count': stopCount,
  };

  Color get color => Color(int.parse(colorHex, radix: 16));
}
