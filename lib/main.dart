import 'package:flutter/material.dart';

import 'brand/autofwd_brand.dart';
import 'features/settings/sms_forwarding_settings.dart';
import 'services/sms_forwarding_config_channel.dart';

void main() {
  runApp(MyApp(repository: SmsForwardingConfigChannel()));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.repository, super.key});

  final SmsForwardingConfigRepository repository;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AutoFwdBrand.primary,
      primary: AutoFwdBrand.primary,
      secondary: AutoFwdBrand.secondary,
    );

    return MaterialApp(
      title: AutoFwdBrand.appName,
      theme: ThemeData(
        colorScheme: colorScheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AutoFwdBrand.primary,
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: SmsForwardingSettingsPage(repository: repository),
    );
  }
}
