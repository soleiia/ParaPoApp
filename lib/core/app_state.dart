import 'package:flutter/foundation.dart';
import 'package:para_po/core/models/models.dart';

/// Global app state — no external package needed.
/// Use ListenableBuilder(listenable: AppState.instance, ...) to rebuild on change.
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

  // ── Navigation tab ────────────────────────────────────────────────────────
  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  // Optional route to open on the Map page (set from Routes page)
  RouteModel? _pendingRoute;
  RouteModel? get pendingRoute => _pendingRoute;

  void goToMap({RouteModel? route}) {
    _pendingRoute = route;
    _tabIndex = 0;
    notifyListeners();
  }

  void clearPendingRoute() {
    _pendingRoute = null;
    // deliberately no notifyListeners – map page calls this internally
  }

  void setTab(int i) {
    _tabIndex = i;
    notifyListeners();
  }
}
