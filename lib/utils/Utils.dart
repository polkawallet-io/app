import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info/package_info.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_ui/utils/format.dart';

class Utils {
  static Future<int> getBuildNumber() async {
    return int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  }

  static Future<String> getAppVersion() async {
    return "${(await PackageInfo.fromPlatform()).version}-${WalletApp.buildTarget == BuildTargets.dev ? "dev" : "beta"}.${(await PackageInfo.fromPlatform()).buildNumber.substring((await PackageInfo.fromPlatform()).buildNumber.length - 1)}";
  }

  static List<BigInt> calcGasFee(EvmGasParams params, int gasLevel) {
    if (params?.estimatedFee == null) return [BigInt.zero, BigInt.zero];

    /// [_level]: 0|1|2|3 for fast|medium|slow|custom.
    /// custom(level 3) not supported.
    final levels = [
      EstimatedFeeLevel.high,
      EstimatedFeeLevel.medium,
      EstimatedFeeLevel.low,
    ];
    final base = BigInt.from(params.gasLimit *
        (params.estimatedBaseFee +
            params.estimatedFee[levels[gasLevel]].maxPriorityFeePerGas -
            0.5) *
        1000000000);
    final max = BigInt.from(params.gasLimit *
        params.estimatedFee[levels[gasLevel]].maxFeePerGas *
        1000000000);
    return [base, max];
  }

  static Map getGasOptionsForTx(
    int gasLimit,
    EvmGasParams gasParams,
    int gasLevel,
    bool isGasEditable,
  ) {
    if (!isGasEditable) {
      /// in acala/karura we use const gasLimit & gasPrice
      return {
        'gas': gasLimit,
        'gasPrice': Fmt.tokenInt(gasParams.gasPrice.toString(), 9).toString(),
      };
    }

    /// in ethereum we use dynamic gas estimate
    final levels = [
      EstimatedFeeLevel.high,
      EstimatedFeeLevel.medium,
      EstimatedFeeLevel.low,
    ];
    return {
      'gas': gasLimit,
      'gasPrice': Fmt.tokenInt(gasParams.gasPrice.toString(), 9).toString(),
      'maxFeePerGas': Fmt.tokenInt(
              gasParams.estimatedFee[levels[gasLevel]].maxFeePerGas.toString(),
              9)
          .toString(),
      'maxPriorityFeePerGas': Fmt.tokenInt(
              gasParams.estimatedFee[levels[gasLevel]].maxPriorityFeePerGas
                  .toString(),
              9)
          .toString(),
    };
  }

  static Map deleteWC2SessionInStorage(
      GetStorage storage, String localStorageKey, String topic) {
    Map cached = storage.read(localStorageKey);

    final aliveSessions = jsonDecode(cached['session']) as List;
    final pairings = jsonDecode(cached['pairing']) as List;
    final subscription = jsonDecode(cached['subscription']) as List;
    final keychain = jsonDecode(cached['keychain']) as Map;

    aliveSessions.removeWhere((e) => e['topic'] == topic);
    pairings.removeWhere((e) => e['topic'] == topic);
    subscription.removeWhere((e) => e['topic'] == topic);
    keychain.removeWhere((k, _) => k == topic);

    cached = {
      'session': jsonEncode(aliveSessions),
      'pairing': jsonEncode(pairings),
      'subscription': jsonEncode(subscription),
      'keychain': jsonEncode(keychain),
    };
    storage.write(localStorageKey, cached);
    return cached;
  }
}
