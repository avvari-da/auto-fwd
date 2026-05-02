import 'package:flutter/material.dart';

import '../../brand/autofwd_brand.dart';
import 'sms_forwarding_config.dart';

enum SmsPermissionStatus { granted, denied }

abstract class SmsForwardingConfigRepository {
  Future<SmsForwardingConfig> loadConfig();

  Future<void> saveConfig(SmsForwardingConfig config);

  Future<SmsPermissionStatus> getPermissionStatus();

  Future<SmsPermissionStatus> requestSmsPermissions();

  String createRouteId();
}

class SmsForwardingSettingsPage extends StatefulWidget {
  const SmsForwardingSettingsPage({required this.repository, super.key});

  final SmsForwardingConfigRepository repository;

  @override
  State<SmsForwardingSettingsPage> createState() =>
      _SmsForwardingSettingsPageState();
}

class _SmsForwardingSettingsPageState extends State<SmsForwardingSettingsPage> {
  SmsForwardingConfig _config = SmsForwardingConfig.disabled();
  bool _isLoading = true;
  bool _isSaving = false;
  SmsPermissionStatus _permissionStatus = SmsPermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                const _BrandHeader(),
                const SizedBox(height: 24),
                _PermissionCard(
                  permissionStatus: _permissionStatus,
                  onRequestPermissions: _requestPermissions,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  key: const ValueKey('enabled-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable forwarding'),
                  subtitle: const Text(
                    'Incoming messages are checked against enabled routes.',
                  ),
                  value: _config.enabled,
                  onChanged: _isSaving ? null : _saveEnabled,
                ),
                const SizedBox(height: 8),
                _RoutesHeader(onAddRoute: _openNewRoute),
                const SizedBox(height: 12),
                if (_config.routes.isEmpty)
                  const _EmptyRoutesCard()
                else
                  ..._config.routes.map(
                    (route) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RouteCard(
                        route: route,
                        onTap: () => _openExistingRoute(route),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _loadSettings() async {
    final config = await widget.repository.loadConfig();
    final permissionStatus = await widget.repository.getPermissionStatus();

    if (!mounted) {
      return;
    }

    setState(() {
      _config = config;
      _permissionStatus = permissionStatus;
      _isLoading = false;
    });
  }

  Future<void> _requestPermissions() async {
    final permissionStatus = await widget.repository.requestSmsPermissions();

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = permissionStatus;
    });
  }

  Future<void> _saveEnabled(bool enabled) async {
    final updatedConfig = SmsForwardingConfig(
      enabled: enabled,
      routes: _config.routes,
    );

    await _saveConfig(updatedConfig, message: null);
  }

  Future<void> _openNewRoute() async {
    final route = await Navigator.of(context).push<SmsRoute>(
      MaterialPageRoute<SmsRoute>(
        builder: (context) => RouteEditorPage(
          route: SmsRoute.empty(widget.repository.createRouteId()),
        ),
      ),
    );

    if (route == null) {
      return;
    }

    await _saveConfig(
      SmsForwardingConfig(
        enabled: _config.enabled,
        routes: <SmsRoute>[..._config.routes, route],
      ),
      message: 'Route saved.',
    );
  }

  Future<void> _openExistingRoute(SmsRoute route) async {
    final editedRoute = await Navigator.of(context).push<SmsRoute?>(
      MaterialPageRoute<SmsRoute?>(
        builder: (context) => RouteEditorPage(route: route, allowDelete: true),
      ),
    );

    if (!mounted || editedRoute == null && !_routeWasDeleted(route.id)) {
      return;
    }

    final routes = editedRoute == null
        ? _config.routes
              .where((existingRoute) => existingRoute.id != route.id)
              .toList(growable: false)
        : _config.routes
              .map(
                (existingRoute) => existingRoute.id == editedRoute.id
                    ? editedRoute
                    : existingRoute,
              )
              .toList(growable: false);

    await _saveConfig(
      SmsForwardingConfig(enabled: _config.enabled, routes: routes),
      message: editedRoute == null ? 'Route deleted.' : 'Route saved.',
    );
  }

  bool _routeWasDeleted(String routeId) {
    return RouteEditorPage.deletedRouteIds.remove(routeId);
  }

  Future<void> _saveConfig(
    SmsForwardingConfig config, {
    required String? message,
  }) async {
    setState(() {
      _isSaving = true;
    });

    final normalizedConfig = config.normalized();
    await widget.repository.saveConfig(normalizedConfig);

    if (!mounted) {
      return;
    }

    setState(() {
      _config = normalizedConfig;
      _isSaving = false;
    });

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class RouteEditorPage extends StatefulWidget {
  const RouteEditorPage({
    required this.route,
    this.allowDelete = false,
    super.key,
  });

  static final Set<String> deletedRouteIds = <String>{};

  final SmsRoute route;
  final bool allowDelete;

  @override
  State<RouteEditorPage> createState() => _RouteEditorPageState();
}

class _RouteEditorPageState extends State<RouteEditorPage> {
  late bool _enabled;
  late final TextEditingController _nameController;
  late final TextEditingController _senderPatternController;
  late final TextEditingController _bodyPatternController;
  late final TextEditingController _destinationNumberController;
  SmsRouteValidation _validation = const SmsRouteValidation({});

  @override
  void initState() {
    super.initState();
    _enabled = widget.route.enabled;
    _nameController = TextEditingController(text: widget.route.name);
    _senderPatternController = TextEditingController(
      text: widget.route.senderPattern,
    );
    _bodyPatternController = TextEditingController(
      text: widget.route.bodyPattern,
    );
    _destinationNumberController = TextEditingController(
      text: widget.route.destinationNumber,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderPatternController.dispose();
    _bodyPatternController.dispose();
    _destinationNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.allowDelete ? 'Edit route' : 'Add route'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FilledButton(
                onPressed: _saveRoute,
                child: const Text('Save route'),
              ),
              if (widget.allowDelete) ...<Widget>[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _deleteRoute,
                  child: const Text('Delete route'),
                ),
              ],
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Route enabled'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('route-name-field'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Route name',
              errorText: _validation.errorFor(SmsRouteField.name),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('sender-pattern-field'),
            controller: _senderPatternController,
            decoration: InputDecoration(
              labelText: 'Sender pattern',
              helperText:
                  r'Case-insensitive. Example: ^\+15551234567$ or BankSender',
              errorText: _validation.errorFor(SmsRouteField.senderPattern),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('body-pattern-field'),
            controller: _bodyPatternController,
            decoration: InputDecoration(
              labelText: 'Message body pattern',
              helperText: r'Case-insensitive. Example: OTP: \d{6}',
              errorText: _validation.errorFor(SmsRouteField.bodyPattern),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('destination-number-field'),
            controller: _destinationNumberController,
            decoration: InputDecoration(
              labelText: 'Destination phone number',
              helperText: 'The number that receives matching messages.',
              errorText: _validation.errorFor(SmsRouteField.destinationNumber),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  void _saveRoute() {
    final route = widget.route
        .copyWith(
          name: _nameController.text,
          enabled: _enabled,
          senderPattern: _senderPatternController.text,
          bodyPattern: _bodyPatternController.text,
          destinationNumber: _destinationNumberController.text,
        )
        .normalized();
    final validation = route.validate();

    setState(() {
      _validation = validation;
    });

    if (!validation.isValid) {
      return;
    }

    Navigator.of(context).pop(route);
  }

  void _deleteRoute() {
    RouteEditorPage.deletedRouteIds.add(widget.route.id);
    Navigator.of(context).pop(null);
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          AutoFwdBrand.iconAsset,
          width: 56,
          height: 56,
          semanticLabel: '${AutoFwdBrand.appName} logo',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: const <InlineSpan>[
                    TextSpan(text: 'Auto'),
                    TextSpan(
                      text: 'Fwd',
                      style: TextStyle(color: AutoFwdBrand.primary),
                    ),
                  ],
                ),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AutoFwdBrand.tagline,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutesHeader extends StatelessWidget {
  const _RoutesHeader({required this.onAddRoute});

  final VoidCallback onAddRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text('Routes', style: Theme.of(context).textTheme.titleLarge),
        ),
        FilledButton.icon(
          onPressed: onAddRoute,
          icon: const Icon(Icons.add),
          label: const Text('Add route'),
        ),
      ],
    );
  }
}

class _EmptyRoutesCard extends StatelessWidget {
  const _EmptyRoutesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No routes yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a route to start forwarding matching SMS messages.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final SmsRoute route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(route.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(route.destinationNumber),
            Text('Sender: ${route.senderPattern}'),
            Text('Body: ${route.bodyPattern}'),
          ],
        ),
        trailing: Icon(
          route.enabled ? Icons.check_circle : Icons.pause_circle_outline,
          color: route.enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.permissionStatus,
    required this.onRequestPermissions,
  });

  final SmsPermissionStatus permissionStatus;
  final VoidCallback onRequestPermissions;

  @override
  Widget build(BuildContext context) {
    final hasPermission = permissionStatus == SmsPermissionStatus.granted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              hasPermission
                  ? 'SMS permissions granted'
                  : 'SMS permissions required',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              hasPermission
                  ? 'Incoming and outgoing SMS access is available.'
                  : 'Grant SMS receive and send permissions before forwarding '
                        'can run in the background.',
            ),
            if (!hasPermission) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRequestPermissions,
                child: const Text('Grant SMS permissions'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
