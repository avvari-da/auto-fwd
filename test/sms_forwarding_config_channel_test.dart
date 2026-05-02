import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_forwarder/features/settings/sms_forwarding_config.dart';
import 'package:sms_forwarder/features/settings/sms_forwarding_settings.dart';
import 'package:sms_forwarder/services/sms_forwarding_config_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(SmsForwardingConfigChannel.channelName);
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);

          return switch (call.method) {
            'loadConfig' => <String, Object>{
              'enabled': true,
              'routes': <Object>[
                <String, Object>{
                  'id': 'bank-otp',
                  'name': 'Bank OTP',
                  'enabled': true,
                  'senderPattern': 'BankSender',
                  'bodyPattern': r'OTP: \d{6}',
                  'destinationNumber': '+15557654321',
                },
              ],
            },
            'saveConfig' => null,
            'getPermissionStatus' => 'denied',
            'requestSmsPermissions' => 'granted',
            _ => throw PlatformException(
              code: 'missing',
              message: 'Unexpected method ${call.method}',
            ),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads config through the method channel', () async {
    final repository = SmsForwardingConfigChannel();

    final config = await repository.loadConfig();

    expect(
      config,
      const SmsForwardingConfig(
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
        ],
      ),
    );
    expect(calls.single.method, 'loadConfig');
  });

  test('saves config through the method channel', () async {
    final repository = SmsForwardingConfigChannel();

    await repository.saveConfig(
      const SmsForwardingConfig(
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
        ],
      ),
    );

    expect(calls.single.method, 'saveConfig');
    expect(calls.single.arguments, <String, Object>{
      'enabled': true,
      'routes': <Object>[
        <String, Object>{
          'id': 'bank-otp',
          'name': 'Bank OTP',
          'enabled': true,
          'senderPattern': 'BankSender',
          'bodyPattern': r'OTP: \d{6}',
          'destinationNumber': '+15557654321',
        },
      ],
    });
  });

  test('maps permission status strings', () async {
    final repository = SmsForwardingConfigChannel();

    expect(await repository.getPermissionStatus(), SmsPermissionStatus.denied);
    expect(
      await repository.requestSmsPermissions(),
      SmsPermissionStatus.granted,
    );
  });
}
