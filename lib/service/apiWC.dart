import 'package:app/pages/walletConnect/dotRequestSignPage.dart';
import 'package:app/pages/walletConnect/ethRequestSignPage.dart';
import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/pages/walletConnect/wcSessionsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ApiWC {
  ApiWC(this.apiRoot);

  final AppService apiRoot;

  void initWalletConnect(String uri, Function getHomePageContext) {
    final cachedSession = apiRoot.store.storage
        .read(apiRoot.store.account.localStorageWCSessionKey);

    final chainId = int.tryParse(apiRoot.plugin.nodeList[0].chainId ?? '1');

    /// subscribe events for v1
    /// v2 was subscribed while plugin start
    if (!uri.contains('@2')) {
      subscribeEvents(getHomePageContext(), uri: uri);

      if (cachedSession == null) {
        apiRoot.store.account.setWCPairing(true);
      }
    }

    apiRoot.plugin.sdk.api.walletConnect.initClient(
        uri, apiRoot.keyringEVM.current.address, chainId,
        cachedSession: cachedSession);
  }

  void subscribeEvents(BuildContext homePageContext, {String uri}) {
    WCProposerMeta peer;
    apiRoot.plugin.sdk.api.walletConnect.subscribeEvents(
        uri: uri,
        onPairing: (WCPairingData pairingData, WCProposerMeta peerMetaData, _) {
          print('get v1 wc pairing');
          _handleWCPairing(homePageContext, peerMetaData);
          peer = peerMetaData;
        },
        onPaired: (Map session) {
          print('wc connected');
          apiRoot.store.account.setWCPairing(false);
          apiRoot.store.account.setWCSession(uri, peer, session);
        },
        onCallRequest: (WCCallRequestData result) {
          print('get wc callRequest');
          apiRoot.store.account.addCallRequest(result);
          handleWCCallRequest(homePageContext, result);
        },
        onDisconnect: (disconnectedUri) {
          print('wc disconnected');
          Navigator.popUntil(homePageContext, ModalRoute.withName('/'));
          if (apiRoot.store.account.wcSessionURI == null ||
              apiRoot.store.account.wcSessionURI.split('?')[0] ==
                  disconnectedUri.split('?')[0]) {
            apiRoot.wc.resetState();
          }
        });
  }

  void subscribeEventsV2(Function getHomePageContext) {
    apiRoot.plugin.sdk.api.walletConnect.subscribeEvents(onPairing:
        (WCPairingData pairingData, WCProposerMeta peerMetaData, String uriV2) {
      print('get v2 wc pairing');
      _handleWCPairingV2(getHomePageContext(), pairingData);
    }, onPaired: (Map session) {
      print('wc v2 connected');
      apiRoot.store.account.addWCSessionV2(session);
    }, onCallRequest: (WCCallRequestData result) {
      print('get wc v2 callRequest');
      apiRoot.store.account.addCallRequest(result);
      handleWCCallRequest(getHomePageContext(), result);
    }, onDisconnect: (topic) {
      print('wc v2 disconnected');
      apiRoot.store.account.deleteWCSessionV2(topic);
      Navigator.popUntil(getHomePageContext(), ModalRoute.withName('/'));
    });
  }

  Future<void> _handleWCPairing(
      BuildContext context, WCProposerMeta peerMetaData) async {
    final navigator = Navigator.of(context);
    final approved = await navigator.pushNamed(WCPairingConfirmPage.route,
        arguments: WCPairingConfirmPageParams(peerMeta: peerMetaData));
    if (approved ?? false) {
      apiRoot.plugin.sdk.api.walletConnect.confirmPairing(true);
      print('wallet connect v1 approved');
      navigator.pushNamed(WCSessionsPage.route);
    } else {
      apiRoot.plugin.sdk.api.walletConnect.confirmPairing(false);
      apiRoot.wc.resetState();
    }
  }

  Future<void> _handleWCPairingV2(
      BuildContext context, WCPairingData pairingData) async {
    bool isNetworkMatch = false;
    if (apiRoot.plugin is PluginEvm) {
      final chainId = apiRoot.plugin.nodeList[0].chainId;
      pairingData.params.requiredNamespaces.forEach((k, v) {
        if (k == 'eip155') {
          for (var e in v.chains) {
            if ('eip155:$chainId' == e) {
              isNetworkMatch = true;
            }
          }
        }
      });
    } else {
      final chainId = apiRoot.plugin.basic.genesisHash.substring(2, 34);
      pairingData.params.requiredNamespaces.forEach((k, v) {
        if (k == 'polkadot') {
          for (var e in v.chains) {
            if ('polkadot:$chainId' == e) {
              isNetworkMatch = true;
            }
          }
        }
      });
    }
    if (!isNetworkMatch) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
      showCupertinoDialog(
          context: context,
          builder: (ctx) {
            return PolkawalletAlertDialog(
              type: DialogType.warn,
              content: Text(dic['wc.pair.notMatch']),
              actions: [
                PolkawalletActionSheetAction(
                  isDefaultAction: true,
                  child: Text(
                    I18n.of(ctx).getDic(i18n_full_dic_ui, 'common')['ok'],
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            );
          });
      apiRoot.plugin.sdk.api.walletConnect.confirmPairingV2(false, '');
      apiRoot.wc.resetState();
      return;
    }

    final navigator = Navigator.of(context);
    final approved = await navigator.pushNamed(WCPairingConfirmPage.route,
        arguments: WCPairingConfirmPageParams(pairingData: pairingData));
    if (approved ?? false) {
      apiRoot.plugin.sdk.api.walletConnect.confirmPairingV2(
          true,
          apiRoot.plugin is PluginEvm
              ? apiRoot.keyringEVM.current.address
              : apiRoot.keyring.current.address);
      print('wallet connect v2 approved');
      navigator.pushNamed(WCSessionsPage.route);
    } else {
      apiRoot.plugin.sdk.api.walletConnect.confirmPairingV2(false, '');
      apiRoot.wc.resetState();
    }
  }

  Future<void> handleWCCallRequest(
      BuildContext context, WCCallRequestData payload) async {
    if (apiRoot.plugin is PluginEvm) {
      Navigator.of(context).pushNamed(EthRequestSignPage.route,
          arguments: EthRequestSignPageParams(payload, Uri()));
    } else {
      Navigator.of(context).pushNamed(DotRequestSignPage.route,
          arguments: DotRequestSignPageParams(payload));
    }
  }

  void resetState() {
    apiRoot.store.account.setWCPairing(false);
    apiRoot.store.account.setWCSession(null, null, null);
  }

  void disconnect() {
    resetState();
    apiRoot.plugin.sdk.api.walletConnect.disconnect();
  }

  void disconnectV2(String topic) {
    apiRoot.store.account.deleteWCSessionV2(topic);
    apiRoot.plugin.sdk.api.walletConnect.disconnectV2(topic);
  }

  Future<void> updateSession(String address, {String chainId}) async {
    final wcVersion = apiRoot.store.account.wcSessionURI != null ? 1 : 2;
    Map v2Storage = {};
    if (chainId != null) {
      if (wcVersion == 2) {
        v2Storage = await apiRoot.plugin.sdk.api.walletConnect
            .changeNetworkV2(chainId, address);
      } else {
        apiRoot.plugin.sdk.api.walletConnect.changeNetwork(chainId, address);
      }
    } else {
      if (wcVersion == 2) {
        v2Storage =
            await apiRoot.plugin.sdk.api.walletConnect.changeAccountV2(address);
      } else {
        apiRoot.plugin.sdk.api.walletConnect.changeAccount(address);
      }
    }

    if (wcVersion == 2) {
      apiRoot.store.storage
          .write(apiRoot.store.account.localStorageWCSessionV2Key, v2Storage);
    } else {
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

  void injectV2StorageData() {
    final Map storageData = apiRoot.store.storage
            .read(apiRoot.store.account.localStorageWCSessionV2Key) ??
        {};
    if (storageData.keys.contains('pairing')) {
      final address = apiRoot.plugin is PluginEvm
          ? apiRoot.keyringEVM.current.address
          : apiRoot.keyring.current.address;
      apiRoot.plugin.sdk.api.walletConnect
          .injectCacheDataV2(storageData, address);
    }
  }

  void deletePairingV2(String topic) {
    Utils.deleteWC2SessionInStorage(apiRoot.store.storage,
        apiRoot.store.account.localStorageWCSessionV2Key, topic);
    apiRoot.plugin.sdk.api.walletConnect.deletePairingV2(topic);
  }
}
