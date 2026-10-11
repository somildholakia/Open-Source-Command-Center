/// Shared, permissive email-format validation for forms and auth events.
///
/// The domain suffix supports modern TLDs longer than four characters.
class EmailValidator {
  EmailValidator._();

  static final RegExp _pattern = RegExp(
    r'^[^\s@]+@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$',
  );

  static bool isValid(String? value) =>
      value != null && _pattern.hasMatch(value.trim());
}
