class AccelerationApiException implements Exception {
  final String errorCode;
  final int? httpStatus;
  const AccelerationApiException(this.errorCode, [this.httpStatus]);
  @override
  String toString() => errorCode;
}

class AccelerationRelease {
  final String id, status;
  final int version;
  AccelerationRelease.fromJson(Map<String, dynamic> json)
      : id = _string(json, 'release_id'),
        status = _string(json, 'status'),
        version = json['version'] as int {
    if (!{'pending', 'ready', 'failed'}.contains(status))
      throw const FormatException('Unknown release state');
  }
}

class AccelerationApplication {
  final String id, name;
  final List<String> domains, processNames, countries, platforms;
  final int priority;
  AccelerationApplication.fromJson(Map<String, dynamic> json)
      : id = _string(json, 'id'),
        name = _string(json, 'name'),
        domains = _strings(json, 'domains'),
        processNames = _strings(json, 'process_names'),
        countries = _strings(json, 'allowed_countries'),
        platforms = _strings(json, 'platforms'),
        priority = json['priority'] as int {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id) ||
        domains.any((d) => !RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(d)) ||
        processNames.any((p) => !RegExp(r'^[a-zA-Z0-9_. -]+$').hasMatch(p))) {
      throw const FormatException('Unsupported application rule');
    }
  }
}

class AccelerationCatalog {
  final String rulesVersion;
  final List<AccelerationApplication> applications;
  AccelerationCatalog.fromJson(Map<String, dynamic> json)
      : rulesVersion = _string(json, 'rules_version'),
        applications = List.unmodifiable((json['applications'] as List).map(
            (app) => AccelerationApplication.fromJson(
                Map<String, dynamic>.from(app as Map)))) {
    if (json['schema_version'] != 1 ||
        applications.map((a) => a.id).toSet().length != applications.length) {
      throw const FormatException('Unsupported catalog schema');
    }
  }
}

class AccelerationConfig {
  final int version;
  final String rulesVersion;
  final DateTime validUntil;
  final List<Map<String, dynamic>> applications, entrances, proxies;
  AccelerationConfig.fromJson(Map<String, dynamic> json)
      : version = json['version'] as int,
        rulesVersion = _string(json, 'rules_version'),
        validUntil = DateTime.parse(_string(json, 'valid_until')).toUtc(),
        applications = _maps(json['applications']),
        entrances = _maps(json['entrances']),
        proxies = _maps((json['mihomo'] as Map)['proxies']) {
    if (json['schema_version'] != 1 || version < 1)
      throw const FormatException('Unsupported configuration schema');
    final names = <String>{};
    for (final proxy in proxies) {
      if (!{'ss', 'vmess', 'vless', 'trojan'}.contains(proxy['type']) ||
          proxy['name'] is! String ||
          !(proxy['name'] as String).startsWith('accel-lane-') ||
          !names.add(proxy['name'] as String) ||
          proxy['server'] is! String ||
          proxy['port'] is! int ||
          (proxy['port'] as int) < 1 ||
          (proxy['port'] as int) > 65535) {
        throw const FormatException('Invalid lane proxy');
      }
    }
    final appIds = <String>{};
    for (final app in applications) {
      if (app['id'] is! String ||
          !appIds.add(app['id'] as String) ||
          app['proxy_names'] is! List ||
          (app['proxy_names'] as List).isEmpty ||
          (app['proxy_names'] as List).any((name) => !names.contains(name))) {
        throw const FormatException('Invalid application binding');
      }
    }
  }
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Missing $key');
  return value;
}

List<String> _strings(Map<String, dynamic> json, String key) =>
    List<String>.unmodifiable(json[key] as List);
List<Map<String, dynamic>> _maps(dynamic value) =>
    List.unmodifiable((value as List)
        .map((row) => Map<String, dynamic>.unmodifiable(row as Map)));
