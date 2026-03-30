import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkStatusController extends ChangeNotifier {
  final Connectivity _connectivity;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkStatusController(this._connectivity) {
    _init();
  }

  bool get isOffline => _isOffline;

  Future<void> _init() async {
    // Initial check
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> result) {
    // connectivity_plus 6.0+ returns List<ConnectivityResult>
    final isNowOffline = result.contains(ConnectivityResult.none);
    if (_isOffline != isNowOffline) {
      _isOffline = isNowOffline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
