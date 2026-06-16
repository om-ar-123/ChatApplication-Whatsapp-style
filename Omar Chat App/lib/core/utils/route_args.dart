/// Safely read named-route arguments.
Map<String, dynamic> routeArgs(Object? arguments) {
  if (arguments is Map<String, dynamic>) return arguments;
  if (arguments is Map) return Map<String, dynamic>.from(arguments);
  return {};
}

int? routeInt(Map<String, dynamic> args, String key) {
  final value = args[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

String? routeString(Map<String, dynamic> args, String key) {
  final value = args[key];
  return value?.toString();
}
