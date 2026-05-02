enum SmsRouteField { name, senderPattern, bodyPattern, destinationNumber }

class SmsForwardingConfig {
  const SmsForwardingConfig({required this.enabled, required this.routes});

  factory SmsForwardingConfig.disabled() {
    return const SmsForwardingConfig(enabled: false, routes: <SmsRoute>[]);
  }

  factory SmsForwardingConfig.fromMap(Map<Object?, Object?> map) {
    return SmsForwardingConfig(
      enabled: map['enabled'] == true,
      routes: _routesFromMap(map['routes']),
    );
  }

  final bool enabled;
  final List<SmsRoute> routes;

  Map<String, Object> toMap() {
    return <String, Object>{
      'enabled': enabled,
      'routes': routes.map((route) => route.toMap()).toList(growable: false),
    };
  }

  SmsForwardingConfig normalized() {
    return SmsForwardingConfig(
      enabled: enabled,
      routes: routes.map((route) => route.normalized()).toList(growable: false),
    );
  }

  SmsForwardingConfigValidation validate() {
    final normalizedConfig = normalized();
    return SmsForwardingConfigValidation(
      normalizedConfig.routes
          .map((route) => route.validate())
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmsForwardingConfig &&
            runtimeType == other.runtimeType &&
            enabled == other.enabled &&
            _listEquals(routes, other.routes);
  }

  @override
  int get hashCode {
    return Object.hash(enabled, Object.hashAll(routes));
  }

  @override
  String toString() {
    return 'SmsForwardingConfig('
        'enabled: $enabled, '
        'routes: $routes'
        ')';
  }
}

class SmsForwardingConfigValidation {
  const SmsForwardingConfigValidation(this.routeValidations);

  final List<SmsRouteValidation> routeValidations;

  bool get isValid =>
      routeValidations.every((validation) => validation.isValid);
}

class SmsRoute {
  const SmsRoute({
    required this.id,
    required this.name,
    required this.enabled,
    required this.senderPattern,
    required this.bodyPattern,
    required this.destinationNumber,
  });

  factory SmsRoute.empty(String id) {
    return SmsRoute(
      id: id,
      name: '',
      enabled: true,
      senderPattern: '',
      bodyPattern: '',
      destinationNumber: '',
    );
  }

  factory SmsRoute.fromMap(Map<Object?, Object?> map) {
    return SmsRoute(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      enabled: map['enabled'] != false,
      senderPattern: map['senderPattern'] as String? ?? '',
      bodyPattern: map['bodyPattern'] as String? ?? '',
      destinationNumber: map['destinationNumber'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final bool enabled;
  final String senderPattern;
  final String bodyPattern;
  final String destinationNumber;

  Map<String, Object> toMap() {
    return <String, Object>{
      'id': id,
      'name': name,
      'enabled': enabled,
      'senderPattern': senderPattern,
      'bodyPattern': bodyPattern,
      'destinationNumber': destinationNumber,
    };
  }

  SmsRoute normalized() {
    return SmsRoute(
      id: id,
      name: name.trim(),
      enabled: enabled,
      senderPattern: senderPattern.trim(),
      bodyPattern: bodyPattern.trim(),
      destinationNumber: destinationNumber.trim(),
    );
  }

  SmsRoute copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? senderPattern,
    String? bodyPattern,
    String? destinationNumber,
  }) {
    return SmsRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      senderPattern: senderPattern ?? this.senderPattern,
      bodyPattern: bodyPattern ?? this.bodyPattern,
      destinationNumber: destinationNumber ?? this.destinationNumber,
    );
  }

  SmsRouteValidation validate() {
    final normalizedRoute = normalized();
    final errors = <SmsRouteField, String>{};

    _validateRequired(
      errors,
      SmsRouteField.name,
      normalizedRoute.name,
      'Enter a route name.',
    );
    _validateRequired(
      errors,
      SmsRouteField.senderPattern,
      normalizedRoute.senderPattern,
      'Enter a sender pattern.',
    );
    _validateRequired(
      errors,
      SmsRouteField.bodyPattern,
      normalizedRoute.bodyPattern,
      'Enter a message body pattern.',
    );
    _validateRequired(
      errors,
      SmsRouteField.destinationNumber,
      normalizedRoute.destinationNumber,
      'Enter the destination phone number.',
    );

    _validateRegex(
      errors,
      SmsRouteField.senderPattern,
      normalizedRoute.senderPattern,
      'Enter a valid sender regex pattern.',
    );
    _validateRegex(
      errors,
      SmsRouteField.bodyPattern,
      normalizedRoute.bodyPattern,
      'Enter a valid message body regex pattern.',
    );

    return SmsRouteValidation(errors);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmsRoute &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            enabled == other.enabled &&
            senderPattern == other.senderPattern &&
            bodyPattern == other.bodyPattern &&
            destinationNumber == other.destinationNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      enabled,
      senderPattern,
      bodyPattern,
      destinationNumber,
    );
  }

  @override
  String toString() {
    return 'SmsRoute('
        'id: $id, '
        'name: $name, '
        'enabled: $enabled, '
        'senderPattern: $senderPattern, '
        'bodyPattern: $bodyPattern, '
        'destinationNumber: $destinationNumber'
        ')';
  }
}

class SmsRouteValidation {
  const SmsRouteValidation(this.errors);

  final Map<SmsRouteField, String> errors;

  bool get isValid => errors.isEmpty;

  String? errorFor(SmsRouteField field) {
    return errors[field];
  }
}

void _validateRequired(
  Map<SmsRouteField, String> errors,
  SmsRouteField field,
  String value,
  String message,
) {
  if (value.isEmpty) {
    errors[field] = message;
  }
}

void _validateRegex(
  Map<SmsRouteField, String> errors,
  SmsRouteField field,
  String pattern,
  String message,
) {
  if (pattern.isEmpty || errors.containsKey(field)) {
    return;
  }

  try {
    RegExp(pattern);
  } on FormatException {
    errors[field] = message;
  }
}

List<SmsRoute> _routesFromMap(Object? value) {
  final routeMaps = value is List<Object?> ? value : const <Object?>[];

  return routeMaps
      .whereType<Map<Object?, Object?>>()
      .map(SmsRoute.fromMap)
      .toList(growable: false);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}
