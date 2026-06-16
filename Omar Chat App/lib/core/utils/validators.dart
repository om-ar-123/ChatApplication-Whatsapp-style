class Validators {
  Validators._();

  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? groupName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Group name must be at least 2 characters';
    }
    return null;
  }
}
