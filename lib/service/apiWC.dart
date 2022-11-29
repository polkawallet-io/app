import 'package:app/service/index.dart';

class ApiWC {
  ApiWC(this.apiRoot);

  final AppService apiRoot;

  void disconnect() {
    apiRoot.store.account.setWCPairing(false);
    apiRoot.store.account.setWCSession(null, null, null);
    apiRoot.plugin.sdk.api.walletConnect.disconnect();
  }

  void updateSession(String address, {int chainId}) {
    if (chainId != null) {
      apiRoot.plugin.sdk.api.walletConnect.changeNetwork(chainId, address);
    } else {
      apiRoot.plugin.sdk.api.walletConnect.changeAccount(address);
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
