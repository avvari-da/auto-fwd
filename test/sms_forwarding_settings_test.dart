import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_forwarder/features/settings/sms_forwarding_config.dart';
import 'package:sms_forwarder/features/settings/sms_forwarding_settings.dart';

void main() {
  testWidgets('renders route list and permission status', (tester) async {
    final repository = FakeSmsForwardingConfigRepository(
      initialConfig: const SmsForwardingConfig(
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
      permissionStatus: SmsPermissionStatus.granted,
    );

    await tester.pumpSettings(repository);

    expect(find.text('AutoFwd', findRichText: true), findsOneWidget);
    expect(find.text('Pattern-matched SMS forwarding'), findsOneWidget);
    expect(find.text('SMS permissions granted'), findsOneWidget);
    expect(find.text('Routes'), findsOneWidget);
    expect(find.text('Bank OTP'), findsOneWidget);
    expect(find.text('+15557654321'), findsOneWidget);
    expect(find.text('Sender: BankSender'), findsOneWidget);
    expect(find.text(r'Body: OTP: \d{6}'), findsOneWidget);
  });

  testWidgets('shows empty route state', (tester) async {
    final repository = FakeSmsForwardingConfigRepository();

    await tester.pumpSettings(repository);

    expect(find.text('No routes yet'), findsOneWidget);
    expect(
      find.text('Add a route to start forwarding matching SMS messages.'),
      findsOneWidget,
    );
  });

  testWidgets('adds a normalized route', (tester) async {
    final repository = FakeSmsForwardingConfigRepository();

    await tester.pumpSettings(repository);
    await tester.tap(find.text('Add route'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('route-name-field')),
      '  Bank OTP  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sender-pattern-field')),
      '  BankSender  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('body-pattern-field')),
      r'  OTP: \d{6}  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('destination-number-field')),
      '  +15557654321  ',
    );
    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();

    expect(repository.savedConfig?.routes, hasLength(1));
    expect(
      repository.savedConfig?.routes.single,
      const SmsRoute(
        id: 'route-1',
        name: 'Bank OTP',
        enabled: true,
        senderPattern: 'BankSender',
        bodyPattern: r'OTP: \d{6}',
        destinationNumber: '+15557654321',
      ),
    );
    expect(find.text('Bank OTP'), findsOneWidget);
  });

  testWidgets('validates a route before saving', (tester) async {
    final repository = FakeSmsForwardingConfigRepository();

    await tester.pumpSettings(repository);
    await tester.tap(find.text('Add route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a route name.'), findsOneWidget);
    expect(find.text('Enter a sender pattern.'), findsOneWidget);
    expect(find.text('Enter a message body pattern.'), findsOneWidget);
    expect(find.text('Enter the destination phone number.'), findsOneWidget);
    expect(repository.savedConfig, isNull);
  });

  testWidgets('edits and deletes routes', (tester) async {
    final repository = FakeSmsForwardingConfigRepository(
      initialConfig: const SmsForwardingConfig(
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

    await tester.pumpSettings(repository);
    await tester.tap(find.text('Bank OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('route-name-field')),
      'Updated Bank OTP',
    );
    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();

    expect(repository.savedConfig?.routes.single.name, 'Updated Bank OTP');

    await tester.tap(find.text('Updated Bank OTP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete route'));
    await tester.pumpAndSettle();

    expect(repository.savedConfig?.routes, isEmpty);
    expect(find.text('No routes yet'), findsOneWidget);
  });

  testWidgets('saves global forwarding toggle', (tester) async {
    final repository = FakeSmsForwardingConfigRepository();

    await tester.pumpSettings(repository);
    await tester.tap(find.byKey(const ValueKey('enabled-switch')));
    await tester.pumpAndSettle();

    expect(repository.savedConfig?.enabled, isTrue);
  });

  testWidgets('requests SMS permissions from the repository', (tester) async {
    final repository = FakeSmsForwardingConfigRepository();

    await tester.pumpSettings(repository);
    await tester.tap(find.text('Grant SMS permissions'));
    await tester.pumpAndSettle();

    expect(repository.requestPermissionCount, 1);
    expect(find.text('SMS permissions granted'), findsOneWidget);
  });
}

extension on WidgetTester {
  Future<void> pumpSettings(
    FakeSmsForwardingConfigRepository repository,
  ) async {
    await pumpWidget(
      MaterialApp(home: SmsForwardingSettingsPage(repository: repository)),
    );
    await pumpAndSettle();
  }
}

class FakeSmsForwardingConfigRepository
    implements SmsForwardingConfigRepository {
  FakeSmsForwardingConfigRepository({
    SmsForwardingConfig? initialConfig,
    SmsPermissionStatus permissionStatus = SmsPermissionStatus.denied,
  }) : _config = initialConfig ?? SmsForwardingConfig.disabled(),
       _permissionStatus = permissionStatus;

  SmsForwardingConfig _config;
  SmsPermissionStatus _permissionStatus;
  SmsForwardingConfig? savedConfig;
  int requestPermissionCount = 0;
  int _nextId = 1;

  @override
  Future<SmsForwardingConfig> loadConfig() async {
    return _config;
  }

  @override
  Future<void> saveConfig(SmsForwardingConfig config) async {
    savedConfig = config;
    _config = config;
  }

  @override
  String createRouteId() {
    return 'route-${_nextId++}';
  }

  @override
  Future<SmsPermissionStatus> getPermissionStatus() async {
    return _permissionStatus;
  }

  @override
  Future<SmsPermissionStatus> requestSmsPermissions() async {
    requestPermissionCount += 1;
    _permissionStatus = SmsPermissionStatus.granted;
    return _permissionStatus;
  }
}
