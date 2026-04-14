import 'package:flutter/foundation.dart';
import 'package:para_po/core/models/models.dart';

/// Global app state shared across all pages.
/// Widgets listen via: ListenableBuilder(listenable: AppState.instance, ...)
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  // ── Fare discount toggle ──────────────────────────────────────────────────
  bool _isDiscounted = false;
  bool get isDiscounted => _isDiscounted;

  void toggleDiscount() {
    _isDiscounted = !_isDiscounted;
    notifyListeners();
  }

  // ── Active tab index ──────────────────────────────────────────────────────
  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  void setTab(int i) {
    _tabIndex = i;
    notifyListeners();
  }

  // ── Pending route (set from Routes page → opens Map page) ─────────────────
  String?  _pendingOrigin;
  String?  _pendingDestination;
  double?  _pendingFare;
  double?  _pendingOriginLat;
  double?  _pendingOriginLng;
  double?  _pendingDestLat;
  double?  _pendingDestLng;

  String?  get pendingOrigin      => _pendingOrigin;
  String?  get pendingDestination => _pendingDestination;
  double?  get pendingFare        => _pendingFare;
  double?  get pendingOriginLat   => _pendingOriginLat;
  double?  get pendingOriginLng   => _pendingOriginLng;
  double?  get pendingDestLat     => _pendingDestLat;
  double?  get pendingDestLng     => _pendingDestLng;

  bool get hasPendingRoute =>
      _pendingOrigin != null && _pendingDestination != null;

  void goToMap({RouteModel? route}) {
    if (route != null) {
      _pendingOrigin      = route.origin;
      _pendingDestination = route.destination;
      _pendingFare        = route.fare;
      _pendingOriginLat   = route.originLat;
      _pendingOriginLng   = route.originLng;
      _pendingDestLat     = route.destLat;
      _pendingDestLng     = route.destLng;
    }
    _tabIndex = 0;
    notifyListeners();
  }

  void clearPendingRoute() {
    _pendingOrigin      = null;
    _pendingDestination = null;
    _pendingFare        = null;
    _pendingOriginLat   = null;
    _pendingOriginLng   = null;
    _pendingDestLat     = null;
    _pendingDestLng     = null;
    // No notifyListeners — called internally by the map page
  }
}
