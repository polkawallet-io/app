import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/browser/authAccountBottomSheetContent.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/pages/walletConnect/ethRequestSignPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_evm/common/constants.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/service/eth/rpcApi.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_sdk/webviewWithExtension/webviewEthInjected.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginBottomSheetContainer.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/DAppWrapperPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DAppEthWrapperPage extends StatefulWidget {
  const DAppEthWrapperPage(this.service, this.keyring, this.keyringEVM,
      {Key key,
      this.getPassword,
      this.getPasswordEVM,
      this.updateAuth,
      this.changeNetwork})
      : super(key: key);
  final AppService service;
  final Keyring keyring;
  final KeyringEVM keyringEVM;
  final Future<String> Function(BuildContext, EthWalletData) getPasswordEVM;
  final Future<String> Function(BuildContext, KeyPairData) getPassword;
  final Function(String, {List<String> accounts, bool isEvm}) updateAuth;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  static const String route = '/extension/app/eth';

  @override
  _DAppEthWrapperPageState createState() => _DAppEthWrapperPageState();
}

class _DAppEthWrapperPageState extends State<DAppEthWrapperPage> {
  WebViewController _controller;

  bool _isWillClose = false;
  bool _signing = false;

  List<KeyPairData> _authedAccounts = [];

  Widget _buildScaffold(
      {Function onBack, Widget body, Function() actionOnPressed}) {
    String url;
    if (ModalRoute.of(context).settings.arguments is Map) {
      url = (ModalRoute.of(context).settings.arguments as Map)["url"];
    } else {
      url = ModalRoute.of(context).settings.arguments as String;
    }
    return PluginScaffold(
      appBar: PluginAppBar(
        title: Text(
          url.split("://").length > 1 ? url.split("://")[1] : url,
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
              fontSize: UI.getTextSize(16, context), color: Colors.white),
        ),
        leadingWidth: 88,
        leading: Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 26, right: 25),
                child: GestureDetector(
                  child: Image.asset(
                    "packages/polkawallet_ui/assets/images/icon_back_plugin.png",
                    width: 9,
                  ),
                  onTap: () {
                    onBack();
                  },
                )),
            GestureDetector(
              child: Image.asset(
                "packages/polkawallet_ui/assets/images/dapp_clean.png",
                width: 14,
              ),
              onTap: () {
                _isWillClose = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: PluginIconButton(
              onPressed: actionOnPressed,
              color: Colors.transparent,
              icon: const Icon(
                Icons.more_horiz,
                color: PluginColorsDark.headline1,
                size: 25,
              ),
            ),
          )
        ],
      ),
      body: body,
    );
  }

  List<KeyPairData> _checkDAppAuth(String url, {bool isEvm = false}) {
    final accountsAll = isEvm
        ? widget.keyringEVM.keyPairs.map((e) => e.toKeyPairData()).toList()
        : widget.keyring.keyPairs.toList();
    if (!isEvm) {
      accountsAll.retainWhere((e) => e.encoding['content'][1] == 'sr25519');
    }

    final authed = isEvm
        ? (widget.service.store.settings.websiteAccessEVM[url] ?? [])
        : (widget.service.store.settings.websiteAccess[url] ?? []);

    accountsAll.retainWhere((e) => authed.contains(e.pubKey));
    return accountsAll;
  }

  Future<List<KeyPairData>> _onConnectRequest(DAppConnectParam params,
      {bool isEvm = false}) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final uri = Uri.parse(params.url ?? '');

    final accountsAll = isEvm
        ? widget.keyringEVM.keyPairs.map((e) => e.toKeyPairData()).toList()
        : widget.keyring.keyPairs.toList();

    final authed = _checkDAppAuth(uri.host, isEvm: isEvm);
    if (authed.isNotEmpty) {
      return authed;
    }

    final res = await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PluginBottomSheetContainer(
          height: MediaQuery.of(context).size.height / 5 * 4,
          title: Text(
            dic['dApp.auth'],
            style: Theme.of(context).textTheme.headline3.copyWith(
                color: Colors.white, fontSize: UI.getTextSize(16, context)),
          ),
          content: AuthAccountBottomSheetContent(uri, accountsAll,
              isEvm: isEvm,
              onChanged: (selected) {
                setState(() {
                  _authedAccounts = selected;
                });
              },
              onCancel: () => Navigator.of(context).pop(false),
              onConfirm: () => Navigator.of(context).pop(true)),
        );
      },
      context: context,
    );
    if (res == true && widget.updateAuth != null) {
      widget.updateAuth(uri.host,
          accounts: _authedAccounts.map((e) => e.pubKey).toList(),
          isEvm: isEvm);
    }
    return _authedAccounts.toList();
  }

  Future<WCCallRequestResult> _onSignRequestEVM(Map params) async {
    final payload = params['data'];
    final humanParams = await widget.service.plugin.sdk.api.eth.keyring
        .renderEthRequest(payload);
    final res = await Navigator.of(context).pushNamed(EthRequestSignPage.route,
        arguments: EthRequestSignPageParams(
            WCCallRequestData.fromJson(Map<String, dynamic>.from({
              'id': payload['id'],
              'event': 'call_request',
              'params': humanParams,
            })),
            Uri.parse(params['origin']),
            network_native_token[widget.service.store.settings.evmNetwork],
            requestRaw: payload));

    return res;
  }

  Future<ExtensionSignResult> _onSignRequest(
      SignAsExtensionParam params) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final address = params.msgType == 'pub(bytes.sign)'
        ? SignBytesRequest.fromJson(
                Map<String, dynamic>.from(params.request ?? {}))
            .address
        : SignExtrinsicRequest.fromJson(
                Map<String, dynamic>.from(params.request ?? {}))
            .address;
    dynamic acc = widget.keyring.keyPairs.firstWhere((acc) {
      bool matched = false;
      widget.keyring.store.pubKeyAddressMap.values.forEach((e) {
        e.forEach((k, v) {
          if (acc.pubKey == k && address == v) {
            matched = true;
          }
        });
      });
      return matched;
    });

    if (acc == null) {
      final decoded =
          await widget.service.plugin.sdk.api.account.decodeAddress([address]);
      acc = widget.keyring.keyPairs.firstWhere((acc) {
        return decoded?.keys?.first == acc.pubKey;
      });
    }

    final ExtensionSignResult res = await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return PluginBottomSheetContainer(
          height: MediaQuery.of(context).size.height / 2,
          title: Text(
            dic[params.msgType == 'pub(extrinsic.sign)'
                ? 'submit.sign.tx'
                : 'submit.sign.msg'],
            style: Theme.of(context).textTheme.headline3.copyWith(
                color: Colors.white, fontSize: UI.getTextSize(16, context)),
          ),
          content: Column(
            children: [
              Expanded(
                  child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 4,
                              child: Text(
                                dic['submit.signer'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    .copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: AddressIcon(address,
                                  svg: acc?.icon, size: 18),
                            ),
                            Expanded(
                                child: Text(
                              Fmt.address(address, pad: 8),
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300),
                            ))
                          ],
                        ),
                      ),
                      params.msgType == 'pub(extrinsic.sign)'
                          ? SignExtrinsicInfo(params)
                          : SignBytesInfo(params),
                    ],
                  ),
                ),
              )),
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: PluginOutlinedButtonSmall(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        content: dic['dApp.connect.reject'],
                        fontSize: UI.getTextSize(16, context),
                        color: const Color(0xFFD8D8D8),
                        active: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: PluginOutlinedButtonSmall(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        content: dic['dApp.confirm'],
                        fontSize: UI.getTextSize(16, context),
                        color: PluginColorsDark.primary,
                        active: !_signing,
                        onPressed: _signing
                            ? null
                            : () async {
                                final res = await _doSign(acc, params);
                                if (res != null) {
                                  Navigator.of(context).pop(res);
                                }
                              },
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
      context: context,
    );
    return res;
  }

  Future<ExtensionSignResult> _doSign(
      KeyPairData acc, SignAsExtensionParam params) async {
    setState(() {
      _signing = true;
    });
    final password = await widget.getPassword(context, acc);
    if (password == null) return null;

    final res = await widget.service.plugin.sdk.api.keyring
        .signAsExtension(password, params);
    if (mounted) {
      setState(() {
        _signing = false;
      });
    }
    return ExtensionSignResult.fromJson({
      'id': params.id,
      'signature': res?.signature,
    });
  }

  Future<bool> _onSwitchEvmNetwork(String chainId) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final chainIdHuman = int.tryParse(chainId).toString();
    String supportedNetwork;
    network_node_list.forEach((key, value) {
      if (value[0]['chainId'] == chainIdHuman) {
        supportedNetwork = key;
      }
    });
    if (supportedNetwork == null) {
      await showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return PluginBottomSheetContainer(
            height: MediaQuery.of(context).size.height / 2,
            title: Text(
              dic['evm.network.switch'],
              style: Theme.of(context).textTheme.headline3.copyWith(
                  color: Colors.white, fontSize: UI.getTextSize(16, context)),
            ),
            content: Column(
              children: [
                Expanded(
                    child: Text(
                        '${dic['evm.network.unsupported']}: $chainIdHuman')),
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: PluginOutlinedButtonSmall(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          content: dicCommon['cancel'],
                          fontSize: UI.getTextSize(16, context),
                          color: const Color(0xFFD8D8D8),
                          active: true,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      Expanded(
                        child: PluginOutlinedButtonSmall(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          content: dicCommon['ok'],
                          fontSize: UI.getTextSize(16, context),
                          color: PluginColorsDark.primary,
                          active: true,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
        context: context,
      );
      return false;
    }

    final res = await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PluginBottomSheetContainer(
          height: MediaQuery.of(context).size.height / 2,
          title: Text(
            dic['evm.network.switch'],
            style: Theme.of(context).textTheme.headline3.copyWith(
                color: Colors.white, fontSize: UI.getTextSize(16, context)),
          ),
          content: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  dic['evm.network.confirm'],
                  style: Theme.of(context).textTheme.headline3.copyWith(
                      color: Colors.white,
                      fontSize: UI.getTextSize(16, context)),
                ),
              ),
              Expanded(
                  child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.service.store.settings.evmNetwork.toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: UI.getTextSize(18, context),
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '>',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: UI.getTextSize(18, context),
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      supportedNetwork.toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: UI.getTextSize(18, context),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: PluginOutlinedButtonSmall(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        content: dicCommon['dApp.connect.reject'],
                        fontSize: UI.getTextSize(16, context),
                        color: const Color(0xFFD8D8D8),
                        active: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    Expanded(
                      child: PluginOutlinedButtonSmall(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        content: dicCommon['dApp.connect.allow'],
                        fontSize: UI.getTextSize(16, context),
                        color: PluginColorsDark.primary,
                        active: true,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
      context: context,
    );

    if (res == true) {
      await _switchEvmNetwork(supportedNetwork);
    }
    return res;
  }

  Future<void> _switchEvmNetwork(String chainName) async {
    final chainInfo = network_node_list[chainName][0];
    final res = await widget.service.plugin.sdk.webView
        ?.evalJavascript('eth.settings.connect("${chainInfo['endpoint']}")');
    if (res != null && res['chainId'] != null) {
      final isWalletConnectAlive =
          widget.service.store.account.wcV2Sessions.isNotEmpty;
      if (isWalletConnectAlive) {
        _disconnectWC();
      }

      widget.service.store.account.setAccountType(AccountType.Evm);
      if (widget.service.plugin is! PluginEvm) {
        widget.service.plugin
            .changeAccount(widget.keyringEVM.keyPairs.first.toKeyPairData());
      }

      final plugin = PluginEvm(
          networkName: chainName,
          config: widget.service.store.settings.ethConfig);
      // TODO: changeNetwork after evm connect will trigger re-connect, maybe effect dApp messaging
      widget.changeNetwork(plugin);
    }
  }

  Future<Map> _onEvmRpcCall(Map payload) async {
    final chainInfo =
        network_node_list[widget.service.store.settings.evmNetwork][0];
    final res = await EvmRpcApi.getRpcCall(chainInfo['endpoint'], payload);
    return res;
  }

  Future<void> _onAccountEmpty(String accType) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final confirm = await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PluginBottomSheetContainer(
          height: MediaQuery.of(context).size.height / 2,
          title: Text(
            dic['evm.empty.$accType'],
            style: Theme.of(context).textTheme.headline3.copyWith(
                color: Colors.white, fontSize: UI.getTextSize(16, context)),
          ),
          content: Column(
            children: [
              Expanded(
                  child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(
                      dic['evm.empty.require.$accType'],
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: UI.getTextSize(16, context),
                          fontWeight: FontWeight.bold),
                    )),
                  ],
                ),
              )),
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: PluginOutlinedButtonSmall(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        content: dicCommon['cancel'],
                        fontSize: UI.getTextSize(16, context),
                        color: const Color(0xFFD8D8D8),
                        active: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    Expanded(
                      child: PluginOutlinedButtonSmall(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        content: dicCommon['ok'],
                        fontSize: UI.getTextSize(16, context),
                        color: PluginColorsDark.primary,
                        active: true,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
      context: context,
    );
    if (confirm == true) {
      await Navigator.of(context).pushNamed(NetworkSelectPage.route,
          arguments: NetworkSelectPageParams(isEvm: accType == 'evm'));
    }
  }

  void _disconnectWC() {
    if (widget.service.store.account.wcSessionURI != null) {
      widget.service.wc.disconnect();
    }
    final v2sessions = widget.service.store.account.wcV2Sessions.toList();
    if (v2sessions.isNotEmpty) {
      for (var e in v2sessions) {
        widget.service.wc.disconnectV2(e.topic);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.service.plugin is! PluginEvm &&
          widget.keyringEVM.keyPairs.isNotEmpty) {
        _switchEvmNetwork(network_ethereum);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String url = "";
    String name = "";
    String icon = "";
    String isPlugin = "";
    if (ModalRoute.of(context).settings.arguments is Map) {
      url = (ModalRoute.of(context).settings.arguments as Map)["url"];
      name = (ModalRoute.of(context).settings.arguments as Map)["name"] ?? "";
      icon = (ModalRoute.of(context).settings.arguments as Map)["icon"] ?? "";
      isPlugin =
          "${(ModalRoute.of(context).settings.arguments as Map)["isPlugin"]}";
    } else {
      url = ModalRoute.of(context).settings.arguments as String;
    }
    return WillPopScope(
      child: _buildScaffold(
        onBack: () async {
          final canGoBack = await _controller?.canGoBack();
          if (canGoBack ?? false) {
            _controller?.goBack();
          } else {
            Navigator.of(context).pop();
          }
        },
        actionOnPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (contextPopup) {
              return DAppBrowserActionButton(
                  url, _controller, icon, name, isPlugin, context);
            },
          );
        },
        body: SafeArea(
          child: Stack(
            children: [
              WebViewEthInjected(
                widget.service.plugin.sdk.api,
                url,
                widget.keyringEVM,
                keyring: widget.keyring,
                onWebViewCreated: (controller) {
                  setState(() {
                    _controller = controller;
                  });
                },
                onConnectRequest: _onConnectRequest,
                onSignRequestEVM: _onSignRequestEVM,
                onSignRequest: _onSignRequest,
                checkAuth: _checkDAppAuth,
                onSwitchEvmChain: _onSwitchEvmNetwork,
                onEvmRpcCall: _onEvmRpcCall,
                onAccountEmpty: _onAccountEmpty,
              ),
              // Visibility(
              //     visible: _loading,
              //     child: Center(child: PluginLoadingWidget()))
            ],
          ),
        ),
      ),
      onWillPop: () async {
        if (_isWillClose) {
          return true;
        } else {
          final canGoBack = await _controller?.canGoBack();
          if (canGoBack ?? false) {
            _controller?.goBack();
            return false;
          } else {
            return true;
          }
        }
      },
    );
  }
}
