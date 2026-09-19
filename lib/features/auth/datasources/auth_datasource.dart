import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/features/auth/models/business_model.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';

/// Auth endpoints. Throws on failure; the repository turns that into `Either`.
class AuthDatasource {
  const AuthDatasource(this._api);

  final ApiClient _api;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return LoginResponseModel.fromJson(ApiResponse.object(body));
  }

  Future<void> logout() => _api.post(ApiConstants.logout);

  Future<List<BusinessModel>> getMyBusinesses() async {
    final body = await _api.get(ApiConstants.myData);
    return BusinessModel.listFrom(ApiResponse.object(body)['businesses']);
  }
}
