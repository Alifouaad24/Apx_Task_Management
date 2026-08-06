import 'dart:async';

import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../constants/app_constants.dart';
import '../services/logger_service.dart';

/// Abstraction over "does this device actually have internet".
///
/// Repositories depend on the interface, which keeps them testable — the
/// concrete implementation reaches out to real hosts through
/// `internet_connection_checker`.
abstract class NetworkInfo {
  /// Performs a live check (DNS/host reachability, not just a radio flag).
  Future<bool> get isConnected;

  /// Broadcasts connectivity transitions for the offline banner.
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl extends GetxService implements NetworkInfo {
  NetworkInfoImpl({InternetConnectionChecker? checker})
      : _checker = checker ?? InternetConnectionChecker.instance;

  final InternetConnectionChecker _checker;

  /// Reactive mirror of the last known status, handy for `Obx` widgets.
  final RxBool connected = true.obs;

  StreamSubscription<InternetConnectionStatus>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _checker.onStatusChange.listen((status) {
      final isOnline = status == InternetConnectionStatus.connected;
      if (connected.value != isOnline) {
        AppLogger.i('Connectivity changed → ${isOnline ? 'online' : 'offline'}');
      }
      connected.value = isOnline;
    });
  }

  @override
  Future<bool> get isConnected async {
    // In mock mode there is no server to reach, so connectivity is irrelevant
    // and a real DNS probe would wrongly block every request on an emulator
    // without internet.
    if (AppConfig.useMockApi) return true;

    try {
      final result = await _checker.hasConnection;
      connected.value = result;
      return result;
    } catch (e) {
      AppLogger.w('Connectivity probe failed, assuming online', e);
      return true;
    }
  }

  @override
  Stream<bool> get onStatusChange => _checker.onStatusChange
      .map((status) => status == InternetConnectionStatus.connected);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
