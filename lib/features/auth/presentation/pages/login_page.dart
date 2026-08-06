import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

/// Email + password sign-in.
class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Let the gradient header run under the status bar.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LoginHeader(),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.welcomeBack,
                        style: AppTextStyles.headlineMedium
                            .copyWith(color: theme.colorScheme.onSurface),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        AppStrings.signInSubtitle,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      SizedBox(height: 28.h),

                      // ---- Email -------------------------------------------
                      Obx(
                        () => AppTextField(
                          controller: controller.emailController,
                          label: AppStrings.email,
                          hint: 'you@company.com',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          validator: Validators.email,
                          errorText: controller.emailError.value,
                          onChanged: controller.onEmailChanged,
                          onSubmitted: (_) =>
                              controller.passwordFocus.requestFocus(),
                          enabled: !controller.isLoading.value,
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // ---- Password ----------------------------------------
                      Obx(
                        () => AppTextField(
                          controller: controller.passwordController,
                          focusNode: controller.passwordFocus,
                          label: AppStrings.password,
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: Validators.password,
                          errorText: controller.passwordError.value,
                          onChanged: controller.onPasswordChanged,
                          onSubmitted: (_) => controller.submit(),
                          enabled: !controller.isLoading.value,
                        ),
                      ),

                      SizedBox(height: 12.h),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppButton.text(
                          label: 'Forgot password?',
                          size: AppButtonSize.small,
                          onPressed: () => Get.snackbar(
                            'Coming soon',
                            'Password recovery is not part of this build.',
                            snackPosition: SnackPosition.BOTTOM,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ---- Submit ------------------------------------------
                      Obx(
                        () => AppButton(
                          label: AppStrings.signIn,
                          isLoading: controller.isLoading.value,
                          onPressed: controller.submit,
                        ),
                      ),

                      if (AppConfig.useMockApi) ...[
                        SizedBox(height: 24.h),
                        const _DemoModeNotice(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient brand header with the app mark.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260.h,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          // Soft decorative circles.
          Positioned(
            top: -40.h,
            right: -30.w,
            child: _Blob(size: 160.w, opacity: 0.16),
          ),
          Positioned(
            bottom: -50.h,
            left: -40.w,
            child: _Blob(size: 190.w, opacity: 0.12),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  AppConfig.appName,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Plan, track and ship your team’s work',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Explains that the app is running against the in-memory mock API.
class _DemoModeNotice extends StatelessWidget {
  const _DemoModeNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.science_outlined,
            size: 18.sp,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  const TextSpan(
                    text: 'Demo mode — the app is served by an in-memory mock '
                        'API. Any email with a 6+ character password works. '
                        'Build with ',
                  ),
                  TextSpan(
                    text: '--dart-define=USE_MOCK_API=false',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ' to use the real backend.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
