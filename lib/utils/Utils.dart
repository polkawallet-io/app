import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:package_info/package_info.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';

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
}
