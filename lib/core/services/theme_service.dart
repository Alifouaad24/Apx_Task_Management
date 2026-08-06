import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/storage_keys.dart';
import '../storage/storage_service.dart';

/// Owns the app's [ThemeMode] and persists the user's choice.
///
/// Registered permanently in the initial binding so both `GetMaterialApp` (at
/// startup) and the profile screen (at runtime) read the same source.
class ThemeService extends GetxService {
  ThemeService(this._storage);

  final StorageService _storage;

  static const String _light = 'light';
  static const String _dark = 'dark';
  static const String _system = 'system';

  late final Rx<ThemeMode> themeMode = _readStoredMode().obs;

  ThemeMode _readStoredMode() {
    switch (_storage.getString(StorageKeys.themeMode)) {
      case _light:
        return ThemeMode.light;
      case _dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Resolves `system` against the platform brightness — used by widgets that
  /// need to pick a status/priority colour for the current brightness.
  bool get isDarkMode {
    switch (themeMode.value) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return Get.mediaQuery.platformBrightness == Brightness.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;

    themeMode.value = mode;
    Get.changeThemeMode(mode);

    await _storage.setString(StorageKeys.themeMode, switch (mode) {
      ThemeMode.light => _light,
      ThemeMode.dark => _dark,
      ThemeMode.system => _system,
    });
  }

  /// Convenience for a quick light/dark switch in the app bar.
  Future<void> toggle() => setThemeMode(
        isDarkMode ? ThemeMode.light : ThemeMode.dark,
      );
}
