import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/exceptions.dart';
import '../services/logger_service.dart';

class StorageService extends GetxService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _guard(() => _prefs.setString(key, value), key);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, int value) =>
      _guard(() => _prefs.setInt(key, value), key);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) =>
      _guard(() => _prefs.setBool(key, value), key);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> setDouble(String key, double value) =>
      _guard(() => _prefs.setDouble(key, value), key);



  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException catch (e) {
      AppLogger.w('Corrupt JSON at "$key", dropping it', e);
      _prefs.remove(key);
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) =>
      _guard(() => _prefs.setString(key, jsonEncode(value)), key);


  bool has(String key) => _prefs.containsKey(key);

  Future<bool> remove(String key) => _guard(() => _prefs.remove(key), key);

  Future<void> removeAll(Iterable<String> keys) async {
    for (final key in keys) {
      await remove(key);
    }
  }

  Future<bool> clear() => _guard(_prefs.clear, '*');

  Future<void> reload() => _prefs.reload();

  Future<bool> _guard(Future<bool> Function() action, String key) async {
    try {
      return await action();
    } catch (e, s) {
      AppLogger.e('Storage write failed for "$key"', e, s);
      throw CacheException('Could not persist "$key".');
    }
  }
}
