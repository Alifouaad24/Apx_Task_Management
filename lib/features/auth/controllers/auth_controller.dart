import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/notifications.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/models/user_model.dart';
import 'package:apx_task_management/features/auth/usecases/auth_usecases.dart';

/// Drives the login screen and owns the logout routine used across the app.
class AuthController extends GetxController {
  AuthController({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  }) : _login = loginUseCase,
       _logout = logoutUseCase;

  final LoginUseCase _login;
  final LogoutUseCase _logout;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordFocus = FocusNode();

  bool isLoading = false;

  /// Server-side error for the email field (e.g. "account disabled").
  String? emailError;

  /// Server-side error for the password field.
  String? passwordError;

  @override
  void onInit() {
    super.onInit();

    // With the mock backend there is no real account to type, so prefill a
    // working demo credential pair. Never do this against a real API.
    if (AppConfig.useMockApi) {
      emailController.text = 'yasser.omran@ramaaz.com';
      passwordController.text = 'password';
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  /// Clears server-side errors as soon as the user edits a field.
  void onEmailChanged(String _) {
    if (emailError == null) return;
    emailError = null;
    update();
  }

  void onPasswordChanged(String _) {
    if (passwordError == null) return;
    passwordError = null;
    update();
  }

  Future<void> submit() async {
    UiHelpers.dismissKeyboard();

    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isLoading) return;

    isLoading = true;
    emailError = null;
    passwordError = null;
    update();

    final result = await _login(
      email: emailController.text,
      password: passwordController.text,
    );

    isLoading = false;
    update();

    result.fold(_onLoginFailure, _onLoginSuccess);
  }

  Future<void> _onLoginSuccess(UserModel user) async {
    Get.find<AnalyticsService>()
      ..logLogin()
      ..setUser(id: user.id, role: user.role);
    await Get.find<NotificationService>().registerDevice();

    await Get.offAllNamed(AppRoutes.home);
  }

  void _onLoginFailure(Failure failure) {
    if (failure is ValidationFailure && failure.fieldErrors.isNotEmpty) {
      emailError = failure.fieldErrors['email']?.first;
      passwordError = failure.fieldErrors['password']?.first;
      update();

      if (emailError == null && passwordError == null) {
        UiHelpers.showFailure(failure);
      }
      return;
    }

    if (failure is UnauthorizedFailure) {
      passwordError = 'Incorrect email or password';
      update();
      return;
    }

    UiHelpers.showFailure(failure);
  }

  Future<void> logout({bool askForConfirmation = true}) async {
    if (askForConfirmation) {
      final confirmed = await UiHelpers.confirm(
        title: AppStrings.signOut,
        message: AppStrings.signOutConfirmation,
        confirmLabel: AppStrings.signOut,
        isDestructive: true,
      );
      if (!confirmed) return;
    }

    isLoading = true;
    update();

    await Get.find<NotificationService>().deleteToken();
    await _logout();
    Get.find<AnalyticsService>()
      ..logLogout()
      ..clearUser();

    isLoading = false;
    update();

    await Get.offAllNamed(AppRoutes.login);
  }
}
