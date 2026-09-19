import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/errors.dart';
import 'package:apx_task_management/core/notifications.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/utils.dart';
import 'package:apx_task_management/features/auth/auth_usecases.dart';

// --------------------------------------------------------------------------
// Auth controller
// --------------------------------------------------------------------------

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

  final RxBool isLoading = false.obs;

  /// Server-side error for the email field (e.g. "account disabled").
  final RxnString emailError = RxnString();

  /// Server-side error for the password field.
  final RxnString passwordError = RxnString();

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
  void onEmailChanged(String _) => emailError.value = null;

  void onPasswordChanged(String _) => passwordError.value = null;

  Future<void> submit() async {
    UiHelpers.dismissKeyboard();

    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isLoading.value) return;

    isLoading.value = true;
    emailError.value = null;
    passwordError.value = null;

    final result = await _login(
      LoginParams(
        email: emailController.text,
        password: passwordController.text,
      ),
    );

    isLoading.value = false;

    result.fold(_onLoginFailure, (session) async {
       Get.find<StorageService>().setString(StorageKeys.userId, session.user.id);
      Get.find<AnalyticsService>()
        ..logLogin()
        ..setUser(id: session.user.id, role: session.user.role);
      await Get.find<NotificationService>().registerDevice();

      await Get.offAllNamed(AppRoutes.home);
    });
  }

  void _onLoginFailure(Failure failure) {
    if (failure is ValidationFailure && failure.fieldErrors.isNotEmpty) {
      emailError.value = failure.fieldErrors['email']?.first;
      passwordError.value = failure.fieldErrors['password']?.first;

      if (emailError.value == null && passwordError.value == null) {
        UiHelpers.showFailure(failure);
      }
      return;
    }

    if (failure is UnauthorizedFailure) {
      passwordError.value = 'Incorrect email or password';
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

    isLoading.value = true;
    final result = await _logout(const NoParams());
    isLoading.value = false;

    Get.find<AnalyticsService>()
      ..logLogout()
      ..clearUser();

    // Both branches navigate: a failed remote logout has still cleared the
    // local session, so staying on the current screen would be wrong.
    result.fold(
      (failure) => UiHelpers.showInfo(
        'Signed out locally — ${failure.message.toLowerCase()}',
      ),
      (_) {},
    );

    await Get.offAllNamed(AppRoutes.login);
  }
}

// --------------------------------------------------------------------------
// Auth binding
// --------------------------------------------------------------------------

/// Wires the login screen.
///
/// The auth *data* dependencies (data sources, repository, use cases) are
/// registered permanently in `InitialBinding` because splash, login and profile
/// all need them; this binding only owns the screen-scoped controller.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
      ),
    );
  }
}
