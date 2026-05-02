import 'package:flutter/services.dart';

import '../features/settings/sms_forwarding_config.dart';
import '../features/settings/sms_forwarding_settings.dart';

class SmsForwardingConfigChannel implements SmsForwardingConfigRepository {
  SmsForwardingConfigChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'sms_forwarder/config';

  final MethodChannel _channel;

  @override
  Future<SmsForwardingConfig> loadConfig() async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'loadConfig',
    );
    return SmsForwardingConfig.fromMap(result ?? const <Object?, Object?>{});
  }

  @override
  Future<void> saveConfig(SmsForwardingConfig config) async {
    await _channel.invokeMethod<void>('saveConfig', config.toMap());
  }

  @override
  Future<SmsPermissionStatus> getPermissionStatus() async {
    final status = await _channel.invokeMethod<String>('getPermissionStatus');
    return _parsePermissionStatus(status);
  }

  @override
  Future<SmsPermissionStatus> requestSmsPermissions() async {
    final status = await _channel.invokeMethod<String>('requestSmsPermissions');
    return _parsePermissionStatus(status);
  }

  @override
  String createRouteId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  SmsPermissionStatus _parsePermissionStatus(String? status) {
    return switch (status) {
      'granted' => SmsPermissionStatus.granted,
      _ => SmsPermissionStatus.denied,
    };
  }
}
