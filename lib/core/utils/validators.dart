import '../constants/app_strings.dart';

/// Reusable form validators wired into [AppTextField.validator].
///
/// Every validator returns `null` when the value is acceptable, matching the
/// `FormFieldValidator<String>` signature.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppStrings.emailRequired;
    if (!_emailPattern.hasMatch(input)) return AppStrings.emailInvalid;
    return null;
  }

  static String? password(String? value, {int minLength = 5}) {
    final input = value ?? '';
    if (input.isEmpty) return AppStrings.passwordRequired;
    if (input.length < minLength) return AppStrings.passwordTooShort;
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field is required';
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'This field'}) {
    if ((value ?? '').length > max) {
      return '$field must be at most $max characters';
    }
    return null;
  }

  /// Runs validators in order and returns the first error found.
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validate in validators) {
      final error = validate(value);
      if (error != null) return error;
    }
    return null;
  }
}
