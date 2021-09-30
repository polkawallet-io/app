class Utils {
  /// enum to String
  static String enumToString(o) => o.toString().split('.').last;

  /// enum from String
  static T enumFromString<T>(Iterable<T> values, String value) {
    return values.firstWhere((type) => type.toString().split('.').last == value,
        orElse: () => null);
  }
}
