import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:package_info/package_info.dart';

class Utils {
  static Future<int> getBuildNumber() async {
    return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  }

  static Future<String> getAppVersion() async {
    return "${(await PackageInfo.fromPlatform()).version}-${WalletApp.buildTarget == BuildTargets.dev ? "dev" : "beta"}.${(await PackageInfo.fromPlatform()).buildNumber.substring((await PackageInfo.fromPlatform()).buildNumber.length - 1)}";
  }

  /// enum to String
  static String enumToString(o) => o.toString().split('.').last;

  /// enum from String
  static T enumFromString<T>(Iterable<T> values, String value) {
    return values.firstWhere((type) => type.toString().split('.').last == value,
        orElse: () => null);
  }
}
