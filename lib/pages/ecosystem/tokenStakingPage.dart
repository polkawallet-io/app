import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/pages/ecosystem/crosschainTransferPage.dart';
import 'package:app/pages/ecosystem/tokenStakingApi.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_acala/polkawallet_plugin_acala.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPageTitleTaps.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:flutter_svg/svg.dart';

class TokenStaking extends StatefulWidget {
  TokenStaking(this.service, {Key key}) : super(key: key);
  AppService service;

  static final String route = '/ecosystem/tokenStaking';

  @override
  State<TokenStaking> createState() => _TokenStakingState();
}

class _TokenStakingState extends State<TokenStaking> {
  int _tab = 0;

  bool _connecting = false;
  Map<String, TokenBalanceData> _balances;
  Map<String, TokenBalanceData> _lBalances;

  final Map<String, List<String>> _networkNames = {
    "KSM": ["kusama", "moonriver", "bifrost", "parallel heiko"],
    "LKSM": ["bifrost", "parallel heiko"],
    "DOT": ["polkadot", "kusama"],
    "LDOT": ["polkadot"]
  };

  _getBalance() async {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];

    Map<String, TokenBalanceData> balances = await TokenStakingApi.getBalance(
        widget.service, _networkNames[token], token);

    Map<String, TokenBalanceData> lpBalances = await TokenStakingApi.getBalance(
        widget.service, _networkNames["L$token"], "L$token");

    setState(() {
      _connecting = true;
      _balances = balances;
      _lBalances = lpBalances;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getBalance();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)?.getDic(i18n_full_dic_app, 'public');
    final data = ModalRoute.of(context).settings.arguments as Map;
    final String token = data["token"];
    return PluginScaffold(
        appBar: PluginAppBar(
          title: Text("$token ${dic['hub.staking']}"),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
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
              _connecting == false
                  ? Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height / 2,
                          child: PluginLoadingWidget(),
                        )
                      ],
                    )
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
                                icon.contains('.svg')
                                    ? SvgPicture.network(icon)
                                    : Image.network(icon),
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
  String name;
  String convertToKen;
  Widget icon;
  TokenBalanceData balance;
  AppService service;

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
                                child: widget.icon, height: 32, width: 32),
                            padding: EdgeInsets.only(right: 10),
                          ),
                          Text(
                            "${dic['ecosystem.on']} ${widget.name}",
                            style: style,
                          )
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${Fmt.priceFloorBigIntFormatter(Fmt.balanceInt(widget.balance.amount), widget.balance.decimals)} ${widget.balance.symbol}",
                              style: style),
                          Visibility(
                              visible: widget.balance.isCacheChange,
                              child: Container(
                                width: 9,
                                height: 9,
                                margin:
                                    EdgeInsets.only(right: 1, top: 1, left: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.5),
                                    color: Theme.of(context).errorColor),
                              ))
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
                          PluginOutlinedButtonSmall(
                            content: dic['ecosystem.crosschainTransfer'],
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            color: PluginColorsDark.primary,
                            fontSize: 12,
                            minSize: 25,
                            active: true,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                  CrosschainTransferPage.route,
                                  arguments: {
                                    "balance": widget.balance,
                                    "fromNetwork": widget.name,
                                    "convertToKen": widget.convertToKen
                                  });
                            },
                          ),
                          PluginOutlinedButtonSmall(
                            content:
                                "${dic['ecosystem.convertTo']} ${widget.convertToKen}",
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            margin: EdgeInsets.zero,
                            color: PluginColorsDark.headline1,
                            fontSize: 12,
                            minSize: 25,
                            active: true,
                            onPressed: () {
                              if (widget.name ==
                                  widget.service.plugin.basic.name) {
                                if (widget.convertToKen.startsWith("L")) {
                                  //to mint
                                  Navigator.of(context).pushNamed(
                                      "/${widget.service.plugin.basic.name.toLowerCase()}/homa/mint");
                                } else {
                                  //to redeem
                                  Navigator.of(context).pushNamed(
                                      "/${widget.service.plugin.basic.name.toLowerCase()}/homa/redeem");
                                }
                              } else {
                                Navigator.of(context)
                                    .pushNamed(ConverToPage.route, arguments: {
                                  "balance": widget.balance,
                                  "fromNetwork": widget.name,
                                  "convertToKen": widget.convertToKen
                                });
                              }
                            },
                          ),
                        ],
                      )))
            ],
          ),
        ));
  }
}
