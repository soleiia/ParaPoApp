import 'package:flutter/foundation.dart';

enum PassengerType { regular, discounted }

class FareProvider extends ChangeNotifier {
  PassengerType _passengerType = PassengerType.regular;

  PassengerType get passengerType => _passengerType;

  bool get isDiscounted => _passengerType == PassengerType.discounted;

  /// LTFRB-mandated 20% discount for students, senior citizens, and PWDs.
  static const double discountRate = 0.20;

  void setPassengerType(PassengerType type) {
    if (_passengerType != type) {
      _passengerType = type;
      notifyListeners();
    }
  }

  /// Returns the fare to display given a base fare.
  double computeFare(double baseFare) {
    if (isDiscounted) {
      return baseFare * (1 - discountRate);
    }
    return baseFare;
  }

  /// Formats the computed fare as a Philippine Peso string.
  String formatFare(double baseFare) {
    final computed = computeFare(baseFare);
    // Round up to nearest centavo (PUV operators collect whole pesos).
    final rounded = computed.ceilToDouble();
    return '₱${rounded.toStringAsFixed(0)}';
  }
}
