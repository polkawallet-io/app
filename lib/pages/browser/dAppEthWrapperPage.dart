import 'package:app/pages/walletConnect/ethRequestSignPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyringEVM.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_sdk/webviewWithExtension/webviewEthInjected.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginBottomSheetContainer.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginIconButton.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DAppEthWrapperPage extends StatefulWidget {
  const DAppEthWrapperPage(this.plugin, this.keyringEVM,
      {Key key, this.getPassword, this.checkAuth, this.updateAuth})
      : super(key: key);
  final PolkawalletPlugin plugin;
  final KeyringEVM keyringEVM;
  final Future<String> Function(BuildContext, EthWalletData) getPassword;
  final bool Function(String) checkAuth;
  final Function(String) updateAuth;

  static const String route = '/extension/app/eth';

  @override
  _DAppEthWrapperPageState createState() => _DAppEthWrapperPageState();
}

class _DAppEthWrapperPageState extends State<DAppEthWrapperPage> {
  WebViewController _controller;

  bool _isWillClose = false;

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

  Future<bool> _onConnectRequest(DAppConnectParam params) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final uri = Uri.parse(params.url ?? '');

    if (widget.checkAuth != null && widget.checkAuth(uri.host)) {
      return true;
    }

    final res = await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return PluginBottomSheetContainer(
          height: MediaQuery.of(context).size.height / 2,
          title: Text(
            dic['dApp.auth'],
            style: Theme.of(context).textTheme.headline3.copyWith(
                color: Colors.white, fontSize: UI.getTextSize(16, context)),
          ),
          content: Column(
            children: [
              Expanded(
                  child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 24, bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          '${uri.scheme}://${uri.host}/favicon.ico',
                          width: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            if ((ModalRoute.of(context).settings.arguments
                                    is Map) &&
                                (ModalRoute.of(context).settings.arguments
                                        as Map)["icon"] !=
                                    null) {
                              return ((ModalRoute.of(context).settings.arguments
                                          as Map)["icon"] as String)
                                      .contains('.svg')
                                  ? SvgPicture.network((ModalRoute.of(context)
                                      .settings
                                      .arguments as Map)["icon"])
                                  : Image.network((ModalRoute.of(context)
                                      .settings
                                      .arguments as Map)["icon"]);
                            }
                            return Container();
                          },
                        ),
                      ),
                    ),
                    Text(
                      uri.host,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: UI.getTextSize(18, context),
                          fontWeight: FontWeight.bold),
                    ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: Text(
                        dic['dApp.connect.tip'],
                        style: TextStyle(
                            fontSize: UI.getTextSize(14, context),
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
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
                        content: dic['dApp.connect.reject'],
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
                        content: dic['dApp.connect.allow'],
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
    if (res == true && widget.updateAuth != null) {
      widget.updateAuth(uri.host);
    }
    return res ?? false;
  }

  Future<WCCallRequestResult> _onSignRequest(Map params) async {
    final payload = params['data'];
    final humanParams =
        await widget.plugin.sdk.api.eth.keyring.renderEthRequest(payload);
    final res = await Navigator.of(context).pushNamed(EthRequestSignPage.route,
        arguments: EthRequestSignPageParams(
            WCCallRequestData.fromJson(Map<String, dynamic>.from({
              'id': payload['id'],
              'event': 'call_request',
              'params': humanParams,
            })),
            Uri.parse(params['origin']),
            requestRaw: payload));

    return res;
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
                widget.plugin.sdk.api,
                url,
                widget.keyringEVM,
                onWebViewCreated: (controller) {
                  setState(() {
                    _controller = controller;
                  });
                },
                onConnectRequest: _onConnectRequest,
                onSignRequest: _onSignRequest,
                checkAuth: widget.checkAuth,
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
