import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart';

class WalletApi {
  static const String _endpoint = 'https://api.polkawallet.io';
  static const String _karEndpoint = 'https://crowdloan-api.laminar.codes';

  static const String _jsCodeStorageKey = 'js_service_';
  static const String _jsCodeStorageVersionKey = 'js_service_version_';

  static Future<Map> getLatestVersion() async {
    try {
      Response res = await get('$_endpoint/versions.json');
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
      Response res = await get('$_endpoint/jsCodeVersions.json');
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
      Response res = await get('$_endpoint/js_service/$networkName.js');
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
      Response res = await get('$_endpoint/announce.json');
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

  static Future<Map> getTokenPrice(String network) async {
    final url = 'https://${network.toLowerCase()}.subscan.io/api/scan/token';
    try {
      Response res = await get(url);
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

  static Future<Map> getKarCrowdLoanStarted() async {
    try {
      final res = await get('$_endpoint/crowdloan/health');
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

  static Future<Map> getKarCrowdLoanStatement() async {
    try {
      final res = await get('$_karEndpoint/statement');
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

  static Future<List> getKarCrowdLoanHistory(String address) async {
    try {
      final res = await get('$_karEndpoint/contributions/$address');
      if (res == null) {
        return null;
      } else {
        print(jsonDecode(utf8.decode(res.bodyBytes)));
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<Map> verifyKarReferralCode(String code) async {
    try {
      final res = await get('$_karEndpoint/referral/$code');
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

  static Future<Map> postKarCrowdLoan(String address, BigInt amount,
      String email, String referral, String signature) async {
    final headers = {"Content-type": "application/json", "Accept": "*/*"};
    final body = {
      "address": address,
      "amount": amount.toString(),
      "email": email,
      "signature": signature,
    };
    if (referral.isNotEmpty) {
      body.addAll({"referral": referral});
    }
    try {
      final res = await post('$_karEndpoint/sign',
          headers: headers, body: jsonEncode(body));
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

  static Future<Map> postKarSubscribe(String email) async {
    final headers = {"Content-type": "application/json", "Accept": "*/*"};
    final body = {
      "fields": [
        {'name': 'email', 'value': email}
      ],
    };
    try {
      final res = await post(
          'https://api.hsforms.com/submissions/v3/integration/submit/7522932/fc605148-482f-4302-a8d2-cece3251f7fc',
          headers: headers,
          body: jsonEncode(body));
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
}
