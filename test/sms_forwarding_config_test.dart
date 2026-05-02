import 'package:flutter_test/flutter_test.dart';
import 'package:sms_forwarder/features/settings/sms_forwarding_config.dart';

void main() {
  group('SmsForwardingConfig validation', () {
    test('accepts enabled config with valid routes', () {
      const config = SmsForwardingConfig(
        enabled: true,
        routes: <SmsRoute>[
          SmsRoute(
            id: 'bank-otp',
            name: 'Bank OTP',
            enabled: true,
            senderPattern: r'^\+15551234567$',
            bodyPattern: r'OTP: \d{6}',
            destinationNumber: '+15557654321',
          ),
        ],
      );

      final result = config.validate();

      expect(result.isValid, isTrue);
      expect(result.routeValidations.single.errors, isEmpty);
    });

    test('requires route name, sender, body, and destination values', () {
      const route = SmsRoute(
        id: 'empty',
        enabled: true,
        name: ' ',
        senderPattern: ' ',
        bodyPattern: ' ',
        destinationNumber: ' ',
      );

      final result = route.validate();

      expect(result.isValid, isFalse);
      expect(result.errorFor(SmsRouteField.name), 'Enter a route name.');
      expect(
        result.errorFor(SmsRouteField.senderPattern),
        'Enter a sender pattern.',
      );
      expect(
        result.errorFor(SmsRouteField.bodyPattern),
        'Enter a message body pattern.',
      );
      expect(
        result.errorFor(SmsRouteField.destinationNumber),
        'Enter the destination phone number.',
      );
    });

    test('reports invalid sender and body regex patterns', () {
      const route = SmsRoute(
        id: 'invalid',
        name: 'Invalid',
        enabled: true,
        senderPattern: '[',
        bodyPattern: '(',
        destinationNumber: '+15557654321',
      );

      final result = route.validate();

      expect(result.isValid, isFalse);
      expect(
        result.errorFor(SmsRouteField.senderPattern),
        'Enter a valid sender regex pattern.',
      );
      expect(
        result.errorFor(SmsRouteField.bodyPattern),
        'Enter a valid message body regex pattern.',
      );
    });

    test('allows empty routes while global forwarding is disabled', () {
      const config = SmsForwardingConfig(enabled: false, routes: <SmsRoute>[]);

      final result = config.validate();

      expect(result.isValid, isTrue);
    });

    test('normalizes whitespace around saved values', () {
      const route = SmsRoute(
        id: 'bank-otp',
        name: '  Bank OTP  ',
        enabled: true,
        senderPattern: '  BankSender  ',
        bodyPattern: '  credited  ',
        destinationNumber: '  +15557654321  ',
      );

      expect(
        route.normalized(),
        const SmsRoute(
          id: 'bank-otp',
          name: 'Bank OTP',
          enabled: true,
          senderPattern: 'BankSender',
          bodyPattern: 'credited',
          destinationNumber: '+15557654321',
        ),
      );
    });

    test('round trips through native channel maps', () {
      const config = SmsForwardingConfig(
        enabled: true,
        routes: <SmsRoute>[
          SmsRoute(
            id: 'bank-otp',
            name: 'Bank OTP',
            enabled: true,
            senderPattern: 'BankSender',
            bodyPattern: r'OTP: \d{6}',
            destinationNumber: '+15557654321',
          ),
          SmsRoute(
            id: 'salary-alerts',
            name: 'Salary Alerts',
            enabled: false,
            senderPattern: 'Payroll',
            bodyPattern: 'credited',
            destinationNumber: '+15550000000',
          ),
        ],
      );

      expect(SmsForwardingConfig.fromMap(config.toMap()), config);
    });

    test('does not migrate legacy single-route maps', () {
      final config = SmsForwardingConfig.fromMap(<String, Object>{
        'enabled': true,
        'senderPattern': 'BankSender',
        'bodyPattern': r'OTP: \d{6}',
        'destinationNumber': '+15557654321',
      });

      expect(
        config,
        const SmsForwardingConfig(enabled: true, routes: <SmsRoute>[]),
      );
    });
  });
}
