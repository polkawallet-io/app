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
import 'package:polkawallet_sdk/api/types/bridge/bridgeChainData.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class TokenStaking extends StatefulWidget {
  const TokenStaking(this.service, {Key key}) : super(key: key);
  final AppService service;

  static String route = '/ecosystem/tokenStaking';

  @override
  State<TokenStaking> createState() => _TokenStakingState();
}

class _TokenStakingState extends State<TokenStaking> {
  ///handle androidOnRenderProcessGone crash
  static const String reloadKey = 'BridgeWebReloadKey';

  int _tab = 0;

  List _fromChains = [];
  List<BridgeRouteData> _routes = [];
  bool _connected = false;
  bool _dataLoaded = false;

  final Map<String, TokenBalanceData> _tokenBalances = {}; // DOT/KSM
  final Map<String, TokenBalanceData> _stakingTokenBalances = {}; // LDOT/LKSM

  Future<bool> _connectFromChains() async {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];

    await widget.service.bridge.initBridgeRunner();
    widget.service.plugin.sdk.api.bridge
        .subscribeReloadAction(reloadKey, _connectFromChains);

    _routes = await widget.service.plugin.sdk.api.bridge.getRoutes();

    final List<String> fromChains = [widget.service.plugin.basic.name];

    fromChains.addAll(List<String>.from(
        widget.service.store.settings.tokenStakingConfig[token]));
    fromChains.addAll(List<String>.from(
        widget.service.store.settings.tokenStakingConfig["L$token"]));
    final chains = fromChains.toSet().toList();
    final connected =
        await widget.service.plugin.sdk.api.bridge.connectFromChains(chains);

    _fromChains = chains;
    _connected = true;

    for (int i = 0; i < chains.length; i++) {
      _subscribeBalance(chains[i], token);
    }

    return connected != null;
  }

  Future<void> _subscribeBalance(String chain, String token) async {
    if (_connected) {
      widget.service.plugin.sdk.api.bridge.subscribeBalances(
          chain, widget.service.keyring.current.address, (res) async {
        final tokenData = res[token];
        final lTokenData = res['L$token'];
        if (tokenData != null) {
          _tokenBalances[chain] = TokenBalanceData(
              amount: tokenData.available,
              tokenNameId: tokenData.token,
              symbol: tokenData.token,
              decimals: tokenData.decimals);
        }
        if (lTokenData != null) {
          _stakingTokenBalances[chain] = TokenBalanceData(
              amount: lTokenData.available,
              tokenNameId: lTokenData.token,
              symbol: lTokenData.token,
              decimals: lTokenData.decimals);
        }

        TokenStakingApi.formatBalanceData(
            widget.service, _fromChains.toSet().toList(), token,
            balances: _tokenBalances);
        TokenStakingApi.formatBalanceData(
            widget.service, _fromChains.toSet().toList(), 'L$token',
            balances: _stakingTokenBalances);

        setState(() {
          _dataLoaded = true;
        });
      });
    }
  }

  @override
  void dispose() {
    widget.service.plugin.sdk.api.bridge.unsubscribeReloadAction(reloadKey);
    widget.service.plugin.sdk.api.bridge.dispose();
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

    final balances = TokenStakingApi.balances[token];
    final lBalances = TokenStakingApi.balances["L$token"];

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
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: PluginPageTitleTaps(
                  names: [token, "L$token"],
                  isReadDot: [
                    (balances?.values ?? [])
                            .toList()
                            .indexWhere((element) => element.isCacheChange) >=
                        0,
                    (lBalances?.values ?? [])
                            .toList()
                            .indexWhere((element) => element.isCacheChange) >=
                        0
                  ],
                  itemPadding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 40),
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
                        color: const Color(0x1affffff),
                        child: ListView.separated(
                          itemCount:
                              _tab == 0 ? balances.length : lBalances.length,
                          itemBuilder: (context, index) {
                            var plugin;
                            if (widget.service.plugin is PluginKarura) {
                              plugin = widget.service.plugin as PluginKarura;
                            } else if (widget.service.plugin is PluginAcala) {
                              plugin = widget.service.plugin as PluginAcala;
                            }
                            final name = _tab == 0
                                ? balances.keys.toList()[index]
                                : lBalances.keys.toList()[index];
                            final icon = plugin
                                .store.assets.crossChainIcons[name] as String;
                            final balance = _tab == 0
                                ? balances[balances.keys.toList()[index]]
                                : lBalances[lBalances.keys.toList()[index]];

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
                                _routes,
                                key: Key(
                                    "${plugin.basic.name}-${balance.symbol}"));
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              color: const Color(0xFFFFFFFF).withAlpha(36),
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
  const TokenItemView(this.name, this.icon, this.balance, this.convertToKen,
      this.service, this.routes,
      {Key key})
      : super(key: key);
  final String name;
  final String convertToKen;
  final Widget icon;
  final TokenBalanceData balance;
  final AppService service;
  final List<BridgeRouteData> routes;

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

    final routesOut = widget.routes.where((e) =>
        e.from == widget.service.plugin.basic.name &&
        e.token == widget.balance.tokenNameId);
    final routesIn = widget.routes.where((e) =>
        e.to == widget.service.plugin.basic.name &&
        e.token == widget.balance.tokenNameId);

    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _isOpen = !_isOpen;
          });
        },
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 32),
          child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SizedBox(
                                height: 32,
                                width: 32,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: widget.icon)),
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
                              padding: const EdgeInsets.only(right: 3),
                              child: Text(
                                  "${Fmt.priceFloorBigIntFormatter(Fmt.balanceInt(widget.balance.amount), widget.balance.decimals, lengthMax: 6)} ${widget.balance.symbol}",
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
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Visibility(
                              visible: (routesOut.isNotEmpty &&
                                      widget.name ==
                                          widget.service.plugin.basic.name) ||
                                  (routesIn.isNotEmpty &&
                                      widget.name !=
                                          widget.service.plugin.basic.name),
                              child: PluginOutlinedButtonSmall(
                                content: dic['ecosystem.crosschainTransfer'],
                                padding: const EdgeInsets.symmetric(
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
                                  (routesIn.isNotEmpty &&
                                      widget.name !=
                                          widget.service.plugin.basic.name),
                              child: PluginOutlinedButtonSmall(
                                content:
                                    "${dic['ecosystem.convertTo']} ${widget.convertToKen}",
                                padding: const EdgeInsets.symmetric(
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
                                        ConvertPage.route,
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
