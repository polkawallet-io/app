import 'dart:convert';

import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';

class ApiBridge {
  ApiBridge(this.apiRoot);

  final AppService apiRoot;

  final _tokenStakingAssetsKey = 'token_staking_';

  void setTokenStakingAssets(String pubKey, Map<String, dynamic> data) {
    apiRoot.store.storage
        .write('$_tokenStakingAssetsKey$pubKey', jsonEncode(data));
  }

  Map<String, dynamic> getTokenStakingAssets(String pubKey) {
    final tokenStakingAssets =
        apiRoot.store.storage.read('$_tokenStakingAssetsKey$pubKey');
    return tokenStakingAssets != null ? jsonDecode(tokenStakingAssets) : null;
  }

  Future<void> updateStakingConfig() async {
    WalletApi.getTokenStakingConfig().then((value) {
      apiRoot.store.settings.setTokenStakingConfig(value);
    });
  }

  Future<void> initBridgeRunner() async {
    final useLocalJS = WalletApi.getPolkadotJSVersion(
          apiRoot.store.storage,
          'bridge',
          bridge_sdk_version,
        ) >
        bridge_sdk_version;

    await apiRoot.plugin.sdk.api.bridge.init(
        jsCode: useLocalJS
            ? WalletApi.getPolkadotJSCode(apiRoot.store.storage, 'bridge')
            : null);
  }
}
