import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sms_forwarder/features/settings/sms_forwarding_config.dart';
import 'package:sms_forwarder/features/settings/sms_forwarding_settings.dart';
import 'package:sms_forwarder/main.dart';

void main() {
  testWidgets('renders the SMS forwarding settings home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(repository: FakeSmsForwardingConfigRepository()),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, 'AutoFwd');
    expect(app.theme?.colorScheme.primary, const Color(0xFF6366F1));
    expect(find.text('Enable forwarding'), findsOneWidget);
  });
}

class FakeSmsForwardingConfigRepository
    implements SmsForwardingConfigRepository {
  @override
  Future<SmsForwardingConfig> loadConfig() async {
    return SmsForwardingConfig.disabled();
  }

  @override
  String createRouteId() {
    return 'route-1';
  }

  @override
  Future<void> saveConfig(SmsForwardingConfig config) async {}

  @override
  Future<SmsPermissionStatus> getPermissionStatus() async {
    return SmsPermissionStatus.denied;
  }

  @override
  Future<SmsPermissionStatus> requestSmsPermissions() async {
    return SmsPermissionStatus.granted;
  }
}
