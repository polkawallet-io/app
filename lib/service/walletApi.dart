import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';

const post_headers = {"Content-type": "application/json", "Accept": "*/*"};

class WalletApi {
  static const String _endpoint = 'https://api.polkawallet.io';
  static const String _configEndpoint = 'https://acala.polkawallet-cloud.com';
  static const String _cdnEndpoint = 'https://cdn.polkawallet-cloud.com';
  static const String vercelEndpoint = 'https://polkawallet-docs.vercel.app';

  static const String _jsCodeStorageKey = 'js_service_';
  static const String _jsCodeStorageVersionKey = 'js_service_version_';

  static Uri getUrl(String realmName, String path, {BuildTargets targets}) {
    String url = "$realmName$path";
    targets = targets ?? WalletApp.buildTarget;
    if (targets == BuildTargets.dev) {
      if (!path.endsWith(".json")) {
        path = "$path.json";
      }
      url = "$_endpoint/devConfiguration$path";
    }
    return Uri.parse(url);
  }

  static String getSnEndpoint(String relayChainName) {
    return 'https://$relayChainName.api.subscan.io/api/scan';
  }

  static Future<Map> getMarketPriceList(String token, int totalCount) async {
    final url =
        '$_endpoint/price-server/?token=$token&from=market&totalCount=$totalCount&intervalUnit=D';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return {};
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
      }
    } catch (err) {
      print(err);
      return {};
    }
  }

  static Future<Map> getXcmEnabledConfig() async {
    try {
      Response res =
          await get(getUrl(_configEndpoint, "/wallet/nativeTokenXCM.json"));
      // await get(getUrl(_endpoint, "/config/nativeTokenXCM.json"));
      if (res == null) {
        return {};
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
      }
    } catch (err) {
      print(err);
      return {};
    }
  }

  static Future<Map> getDisabledCalls() async {
    try {
      Response res =
          await get(getUrl(_configEndpoint, "/wallet/disabledCalls.json"));
      if (res == null) {
        return {};
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
      }
    } catch (err) {
      print(err);
      return {};
    }
  }

  static Future<Map> getLatestVersion() async {
    try {
      Response res =
          await get(getUrl(_configEndpoint, "/wallet/versions.json"));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> fetchPolkadotJSVersion() async {
    try {
      Response res =
          await get(getUrl(_configEndpoint, "/wallet/jsCodeVersions.json"));
      if (res == null) {
        return null;
      } else {
        return Map.of(jsonDecode(res.body));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<String> fetchPolkadotJSCode(String networkName) async {
    try {
      Response res =
          await get(getUrl(_configEndpoint, "/wallet/js/$networkName.js"));
      if (res == null || res.statusCode != 200) {
        return null;
      } else {
        return utf8.decode(res.bodyBytes);
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static int getPolkadotJSVersion(
    GetStorage jsStorage,
    String networkName,
    int appJSVersion,
  ) {
    final String version =
        jsStorage.read('$_jsCodeStorageVersionKey$networkName');
    if (version != null) {
      final updatedVersion = int.parse(version);
      return updatedVersion > appJSVersion ? updatedVersion : appJSVersion;
    }
    // default version
    return appJSVersion;
  }

  static String getPolkadotJSCode(
    GetStorage jsStorage,
    String networkName,
  ) {
    final String jsCode = jsStorage.read('$_jsCodeStorageKey$networkName');
    return jsCode;
  }

  static void setPolkadotJSCode(
    GetStorage jsStorage,
    String networkName,
    String code,
    int version,
  ) {
    jsStorage.write('$_jsCodeStorageKey$networkName', code);
    jsStorage.write(
        '$_jsCodeStorageVersionKey$networkName', version.toString());
  }

  static Future<List> getAnnouncements() async {
    try {
      Response res = await get(getUrl(_endpoint, '/announce.json'));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> getTokenPrices() async {
    final url =
        '$_cdnEndpoint/lastPrice.json?t=${DateTime.now().millisecondsSinceEpoch}';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> getAdBannerList() async {
    try {
      final res = await get(getUrl(_configEndpoint, '/wallet/banners.json'));
      // final res = await get(getUrl(_endpoint, '/config/banners.json'));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> getPluginsConfig(BuildTargets targets) async {
    try {
      Response res = await get(
          getUrl(_configEndpoint, '/wallet/plugins.json', targets: targets));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(res.body) as Map;
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> fetchBlocksFromSn(String relayChainName,
      {int count = 1}) async {
    final url = '${getSnEndpoint(relayChainName)}/blocks';
    final body = jsonEncode({
      "page": 0,
      "row": count,
    });
    final Response res =
        await post(Uri.parse(url), headers: post_headers, body: body);
    if (res.body != null) {
      final obj = await compute(jsonDecode, res.body);
      return obj['data'];
    }
    return {};
  }

  static Future<Map> getTokenPriceFromSubScan(String network) async {
    final url =
        'https://${network.toLowerCase()}.api.subscan.io/api/scan/token';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  //$=>￥
  static Future<Map> getRate() async {
    final url = '$_endpoint/price-server/rate';
    try {
      Response res = await get(Uri.parse(url));
      if (res == null) {
        return {};
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map;
      }
    } catch (err) {
      print(err);
      return {};
    }
  }

  static Future<List> getMessage(String _type, String _languageCode) async {
    try {
      Response res = await get(
          Uri.parse("$vercelEndpoint/api/$_type?lang=$_languageCode"));
      if (res == null) {
        return null;
      } else {
        return jsonDecode(utf8.decode(res.bodyBytes)) as List;
      }
    } catch (err) {
      print(err);
      return null;
    }
  }
}
