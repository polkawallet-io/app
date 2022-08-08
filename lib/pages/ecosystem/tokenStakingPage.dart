import 'dart:convert';

import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/crosschainTransferPage.dart';
import 'package:app/pages/ecosystem/ecosystemPage.dart';
import 'package:app/pages/ecosystem/tokenStakingApi.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/connectionChecker.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';

class TokenStaking extends StatefulWidget {
  TokenStaking(this.service, {Key key}) : super(key: key);
  final AppService service;

  static final String route = '/ecosystem/tokenStaking';

  @override
  State<TokenStaking> createState() => _TokenStakingState();
}

class _TokenStakingState extends State<TokenStaking> {
  int _tab = 0;

  List _fromChains = [];
  bool _connected = false;
  bool _dataLoaded = false;

  Future<bool> _connectFromChains() async {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    final fromChains =
        List.of(widget.service.store.settings.tokenStakingConfig[token]);
    fromChains.addAll(
        List.of(widget.service.store.settings.tokenStakingConfig["L$token"]));
    final connected = await widget.service.plugin.sdk.webView.evalJavascript(
        'xcm.connectFromChain(${json.encode(fromChains.toSet().toList())})');

    _fromChains = fromChains;
    _connected = true;

    return connected != null;
  }

  _getBalance() async {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];

    final connected = await _connectFromChains();

    if (connected) {
      await Future.wait([
        TokenStakingApi.getBalance(widget.service,
            widget.service.store.settings.tokenStakingConfig[token], token),
        TokenStakingApi.getBalance(
            widget.service,
            widget.service.store.settings.tokenStakingConfig["L$token"],
            "L$token"),
      ]);
    }

    setState(() {
      _dataLoaded = true;
    });
  }

  @override
  void dispose() {
    widget.service.plugin.sdk.webView
        .evalJavascript('xcm.disconnectFromChain(${json.encode(_fromChains)})');
    super.dispose();
  }

  @override
  void initState() {
    TokenStakingApi.refresh = () {
      if (mounted) {
        setState(() {});
      }
    };
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectFromChains();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];

    final _balances = TokenStakingApi.balances[token];
    final _lBalances = TokenStakingApi.balances["L$token"];

    final isReady = _connected && _dataLoaded;
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text("$token ${dic['hub.staking']}"),
          centerTitle: true,
          actions: [PluginAccountInfoAction(widget.service.keyring)],
        ),
        body: SafeArea(
          child: Column(
            children: [
              ConnectionChecker(widget.service.plugin,
                  onConnected: _getBalance),
              Container(
                margin: EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: PluginPageTitleTaps(
                  names: [token, "L$token"],
                  isReadDot: [
                    (_balances?.values ?? [])
                            .toList()
                            .indexWhere((element) => element.isCacheChange) >=
                        0,
                    (_lBalances?.values ?? [])
                            .toList()
                            .indexWhere((element) => element.isCacheChange) >=
                        0
                  ],
                  itemPadding:
                      EdgeInsets.symmetric(vertical: 3, horizontal: 40),
                  activeTab: _tab,
                  onTap: (i) {
                    setState(() {
                      _tab = i;
                    });
                  },
                ),
              ),
              isReady == false
                  ? const Expanded(
                      child: PluginPopLoadingContainer(
                      loading: true,
                    ))
                  : Expanded(
                      child: Container(
                        color: Color(0x1affffff),
                        child: ListView.separated(
                          itemCount:
                              _tab == 0 ? _balances.length : _lBalances.length,
                          itemBuilder: (context, index) {
                            var plugin;
                            if (widget.service.plugin is PluginKarura) {
                              plugin = widget.service.plugin as PluginKarura;
                            } else if (widget.service.plugin is PluginAcala) {
                              plugin = widget.service.plugin as PluginAcala;
                            }
                            final name = _tab == 0
                                ? _balances.keys.toList()[index]
                                : _lBalances.keys.toList()[index];
                            final icon = plugin
                                .store.assets.crossChainIcons[name] as String;
                            final balance = _tab == 0
                                ? _balances[_balances.keys.toList()[index]]
                                : _lBalances[_lBalances.keys.toList()[index]];

                            return TokenItemView(
                                name,
                                icon != null
                                    ? icon.contains('.svg')
                                        ? SvgPicture.network(icon)
                                        : Image.network(icon)
                                    : Container(),
                                balance,
                                _tab == 1 ? token : "L$token",
                                widget.service,
                                key: Key(
                                    "${plugin.basic.name}-${balance.symbol}"));
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              color: Color(0xFFFFFFFF).withAlpha(36),
                            ),
                          ),
                        ),
                      ),
                    )
            ],
          ),
        ));
  }
}

class TokenItemView extends StatefulWidget {
  TokenItemView(
      this.name, this.icon, this.balance, this.convertToKen, this.service,
      {Key key})
      : super(key: key);
  final String name;
  final String convertToKen;
  final Widget icon;
  final TokenBalanceData balance;
  final AppService service;

  @override
  State<TokenItemView> createState() => _TokenItemViewState();
}

class _TokenItemViewState extends State<TokenItemView> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final style = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.w600, color: Colors.white);

    var plugin;
    if (widget.service.plugin is PluginKarura) {
      plugin = widget.service.plugin as PluginKarura;
    } else if (widget.service.plugin is PluginAcala) {
      plugin = widget.service.plugin as PluginAcala;
    }

    final tokensConfig = plugin.store.setting.remoteConfig['tokens'] ?? {};
    final tokenXcmConfig = List<String>.from(
        (tokensConfig['xcm'] ?? {})[widget.balance.tokenNameId] ?? []);
    final tokenXcmFromConfig = List<String>.from(
        (tokensConfig['xcmFrom'] ?? {})[widget.balance.tokenNameId] ?? []);
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _isOpen = !_isOpen;
          });
        },
        child: Container(
          padding: EdgeInsets.only(left: 16, right: 32),
          child: Column(
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            child: SizedBox(
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: widget.icon),
                                height: 32,
                                width: 32),
                            padding: EdgeInsets.only(right: 10),
                          ),
                          Text(
                            widget.name,
                            style: style,
                          )
                        ],
                      ),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: Text(
                                  "${Fmt.priceFloorBigIntFormatter(Fmt.balanceInt(widget.balance.amount), widget.balance.decimals)} ${widget.balance.symbol}",
                                  style: style)),
                          Visibility(
                            visible: widget.balance.isCacheChange,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.5),
                                  color: Theme.of(context).errorColor),
                            ),
                          )
                        ],
                      )
                    ],
                  )),
              Visibility(
                  visible: _isOpen &&
                      Fmt.balanceInt(widget.balance.amount) != BigInt.zero,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Visibility(
                              visible: (tokenXcmConfig.length > 0 &&
                                      widget.name ==
                                          widget.service.plugin.basic.name) ||
                                  (tokenXcmFromConfig.length > 0 &&
                                      widget.name !=
                                          widget.service.plugin.basic.name),
                              child: PluginOutlinedButtonSmall(
                                content: dic['ecosystem.crosschainTransfer'],
                                padding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                color: PluginColorsDark.primary,
                                fontSize: UI.getTextSize(12, context),
                                minSize: 25,
                                active: true,
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      CrossChainTransferPage.route,
                                      arguments: {
                                        "balance": widget.balance,
                                        "fromNetwork": widget.name
                                      });
                                },
                              )),
                          Visibility(
                              visible: widget.name ==
                                      widget.service.plugin.basic.name ||
                                  (tokenXcmFromConfig.length > 0 &&
                                      widget.name !=
                                          widget.service.plugin.basic.name),
                              child: PluginOutlinedButtonSmall(
                                content:
                                    "${dic['ecosystem.convertTo']} ${widget.convertToKen}",
                                padding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                margin: EdgeInsets.zero,
                                color: PluginColorsDark.headline1,
                                fontSize: UI.getTextSize(12, context),
                                minSize: 25,
                                active: true,
                                onPressed: () async {
                                  if (widget.name ==
                                      widget.service.plugin.basic.name) {
                                    final convertBalance = widget
                                        .service.plugin.noneNativeTokensAll
                                        .firstWhere((element) =>
                                            element.symbol ==
                                            widget.convertToKen);
                                    if (widget.convertToKen.startsWith("L")) {
                                      //to mint
                                      final res = await Navigator.of(context)
                                          .pushNamed(
                                              "/${widget.service.plugin.basic.name.toLowerCase()}/homa/mint");
                                      if (res != null) {
                                        convertBalance.amount = Fmt.tokenInt(
                                                res, convertBalance.decimals)
                                            .toString();
                                        Navigator.of(context).pushNamed(
                                            EcosystemPage.route,
                                            arguments: {
                                              "balance": convertBalance,
                                              "transferBalance": res,
                                              "convertNetwork": widget
                                                  .service.plugin.basic.name,
                                              "type": "minted"
                                            });
                                      }
                                    } else {
                                      //to redeem
                                      final res = await Navigator.of(context)
                                          .pushNamed(
                                              "/${widget.service.plugin.basic.name.toLowerCase()}/homa/redeem");
                                      if (res != null) {
                                        convertBalance.amount = Fmt.tokenInt(
                                                res, convertBalance.decimals)
                                            .toString();
                                        Navigator.of(context).pushNamed(
                                            EcosystemPage.route,
                                            arguments: {
                                              "balance": convertBalance,
                                              "transferBalance": res,
                                              "convertNetwork": widget
                                                  .service.plugin.basic.name,
                                              "type": "redeemed"
                                            });
                                      }
                                    }
                                  } else {
                                    Navigator.of(context).pushNamed(
                                        ConverToPage.route,
                                        arguments: {
                                          "balance": widget.balance,
                                          "fromNetwork": widget.name,
                                          "convertToKen": widget.convertToKen
                                        });
                                  }
                                },
                              )),
                        ],
                      )))
            ],
          ),
        ));
  }
}
