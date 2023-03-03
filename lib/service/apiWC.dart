import 'package:app/service/index.dart';

class ApiWC {
  ApiWC(this.apiRoot);

  final AppService apiRoot;

  void resetState() {
    apiRoot.store.account.setWCPairing(false);
    apiRoot.store.account.setWCSession(null, null, null);
  }

  void disconnect() {
    resetState();
    apiRoot.plugin.sdk.api.walletConnect.disconnect();
  }

  void updateSession(String address, {int chainId}) {
    final wcVersion = apiRoot.store.account.wcSessionURI.contains('@2') ? 2 : 1;
    if (chainId != null) {
      if (wcVersion == 2) {
        apiRoot.plugin.sdk.api.walletConnect.changeNetworkV2(chainId, address);
      } else {
        apiRoot.plugin.sdk.api.walletConnect.changeNetwork(chainId, address);
      }
    } else {
      if (wcVersion == 2) {
        apiRoot.plugin.sdk.api.walletConnect.changeAccountV2(address);
      } else {
        apiRoot.plugin.sdk.api.walletConnect.changeAccount(address);
      }
    }

    final cachedWCSession = apiRoot.store.storage
        .read(apiRoot.store.account.localStorageWCSessionKey) as Map;
    final chainIdNew = chainId ?? cachedWCSession['chainId'];
    apiRoot.store.storage
        .write(apiRoot.store.account.localStorageWCSessionKey, {
      ...cachedWCSession,
      'chainId': chainIdNew,
      'accounts': [apiRoot.keyringEVM.current.address]
    });
  }
}
