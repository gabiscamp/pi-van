class Validators {
  static bool isValidEmail(String value) {
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegExp.hasMatch(value.trim());
  }
  static bool hasMinLength(String value, int min) => value.trim().length >= min;
}
