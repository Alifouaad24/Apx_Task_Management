import 'package:dartz/dartz.dart';

import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/storage.dart';
import 'package:apx_task_management/features/auth/datasources/auth_datasource.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';

class AuthRepository {
  const AuthRepository(this._datasource, this._storage);

  final AuthDatasource _datasource;
  final AppStorage _storage;

  bool get isLoggedIn => _storage.isLoggedIn;

  UserModel? get currentUser {
    final json = _storage.user;
    return json == null ? null : UserModel.fromJson(json);
  }

  Future<Either<Failure, UserModel>> login({
    required String email,
    required String password,
  }) {
    return safeCall(() async {
      final response = await _datasource.login(
        email: email,
        password: password,
      );
      await _storage.saveToken(response.token);
      await _storage.saveUser(response.user.toJson());
      await _saveBusinesses(response.businesses);
      return response.user;
    });
  }

  List<BusinessModel> get businesses =>
      _storage.businesses.map(BusinessModel.fromJson).toList();

  /// The selected business; the first one when nothing (valid) is selected.
  BusinessModel? get currentBusiness {
    final all = businesses;
    final id = _storage.currentBusinessId;
    for (final business in all) {
      if (business.id == id) return business;
    }
    return all.isEmpty ? null : all.first;
  }

  Future<void> selectBusiness(BusinessModel business) =>
      _storage.saveCurrentBusinessId(business.id);

  /// The stored businesses, fetched from the server when there are none (a
  /// session that started before businesses were stored).
  Future<Either<Failure, List<BusinessModel>>> loadBusinesses() {
    return safeCall(() async {
      final stored = businesses;
      if (stored.isNotEmpty) return stored;

      final fetched = await _datasource.getMyBusinesses();
      await _saveBusinesses(fetched);
      return fetched;
    });
  }

  /// Stores the list and, like the web app, makes the first one current.
  Future<void> _saveBusinesses(List<BusinessModel> list) async {
    await _storage.saveBusinesses([for (final b in list) b.toJson()]);
    if (list.isNotEmpty) await _storage.saveCurrentBusinessId(list.first.id);
  }

  /// Tells the server (best effort), then always clears the local session.
  Future<void> logout() async {
    try {
      await _datasource.logout();
    } catch (e) {
      AppLogger.w('Remote logout failed, clearing locally anyway', e);
    }
    await _storage.clearSession();
  }
}
