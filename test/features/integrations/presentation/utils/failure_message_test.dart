import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/integrations/presentation/utils/failure_message.dart';

void main() {
  group('failureMessage', () {
    test('covers every ProviderFailure variant with non-empty copy', () {
      const failures = <ProviderFailure>[
        ProviderNotConnected(),
        AuthenticationFailed(),
        AuthorizationExpired(),
        RateLimited(),
        NetworkUnavailable(),
        ApiUnavailable(),
        PermissionDenied(),
        UnknownProviderError(),
      ];

      for (final failure in failures) {
        expect(failureMessage(failure), isNotEmpty);
      }
    });

    test('uses provided auth detail when present', () {
      expect(
        failureMessage(const AuthenticationFailed(detail: 'Denied by user')),
        'Denied by user',
      );
    });

    test('explains reconnect for expired authorization', () {
      expect(
        failureMessage(const AuthorizationExpired()),
        contains('Reconnect'),
      );
    });

    test('includes the reset time for rate limits when known', () {
      final message = failureMessage(
        RateLimited(resetAt: DateTime(2026, 10, 3, 18, 45)),
      );

      expect(message, contains('18:45'));
    });

    test('stays generic for rate limits without a reset time', () {
      expect(failureMessage(const RateLimited()), contains('rate limit'));
    });

    test('never leaks internal details for unknown errors', () {
      final message = failureMessage(
        const UnknownProviderError(detail: 'Bad state: SocketException 42'),
      );

      expect(message, 'Something went wrong. Please try again.');
      expect(message.contains('SocketException'), isFalse);
    });
  });

  group('formatClock', () {
    test('formats times with zero padding', () {
      expect(formatClock(DateTime(2026, 10, 3, 9, 5)), '09:05');
      expect(formatClock(DateTime(2026, 10, 3, 23, 59)), '23:59');
    });
  });
}
