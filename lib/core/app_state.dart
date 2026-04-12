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
  // Stores origin + destination text for the map input fields.
  // Routes no longer carry lat/lng — OSRM geocodes from text or we search DB.
  String? _pendingOrigin;
  String? _pendingDestination;
  String? get pendingOrigin      => _pendingOrigin;
  String? get pendingDestination => _pendingDestination;

  bool get hasPendingRoute =>
      _pendingOrigin != null && _pendingDestination != null;

  void goToMap({RouteModel? route}) {
    if (route != null) {
      _pendingOrigin      = route.origin;
      _pendingDestination = route.destination;
    }
    _tabIndex = 0;
    notifyListeners();
  }

  void clearPendingRoute() {
    _pendingOrigin      = null;
    _pendingDestination = null;
    // No notifyListeners — called internally by the map page
  }
}
