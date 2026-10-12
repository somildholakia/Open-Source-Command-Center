import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/utils/email_validator.dart';

void main() {
  group('EmailValidator', () {
    test(
      'accepts modern long top-level domains and surrounding whitespace',
      () {
        expect(
          EmailValidator.isValid('  developer@example.technology  '),
          isTrue,
        );
        expect(EmailValidator.isValid('dev@sub.example.community'), isTrue);
      },
    );

    test('rejects incomplete addresses and whitespace inside the address', () {
      expect(EmailValidator.isValid(null), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
      expect(EmailValidator.isValid('developer'), isFalse);
      expect(EmailValidator.isValid('dev@localhost'), isFalse);
      expect(EmailValidator.isValid('dev @example.com'), isFalse);
      expect(EmailValidator.isValid('dev@example..com'), isFalse);
    });
  });
}
