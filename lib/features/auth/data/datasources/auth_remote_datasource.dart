import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

import 'package:dio/dio.dart' show Options;

/// Talks to the auth endpoints. Throws [AppException]s; never returns
/// `Either` — that translation is the repository's job.
abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> fetchCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
    );

    return AuthSessionModel.fromJson(ApiResponseParser.object(body));
  }

  @override
  Future<void> logout() async {
    // Best effort: the repository clears local state regardless of the result.
    await _client.post(ApiConstants.logout);
  }

  @override
  Future<UserModel> fetchCurrentUser() async {
    final body = await _client.get(ApiConstants.currentUser);
    return UserModel.fromJson(ApiResponseParser.object(body));
  }
}
