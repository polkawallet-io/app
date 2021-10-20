import 'package:package_info/package_info.dart';

class Utils {
  static Future<int> getBuildNumber() async {
    return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  }

  static Future<String> getAppVersion() async {
    return "${(await PackageInfo.fromPlatform()).version}-beta.${(await PackageInfo.fromPlatform()).buildNumber.substring((await PackageInfo.fromPlatform()).buildNumber.length - 1)}";
  }
}
