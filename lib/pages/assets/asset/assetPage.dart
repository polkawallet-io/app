import 'package:app/common/consts.dart';
import 'package:app/pages/assets/asset/locksDetailPage.dart';
import 'package:app/pages/assets/asset/rewardsChart.dart';
import 'package:app/pages/assets/transfer/detailPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/store/types/transferData.dart';
import 'package:app/utils/ShowCustomAlterWidget.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/cardButton.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

class AssetPage extends StatefulWidget {
  AssetPage(this.service);
  final AppService service;

  static final String route = '/assets/detail';

  @override
  _AssetPageState createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

  bool _loading = false;

  int _tab = 0;
  String history = 'all';
  int _txsPage = 0;
  bool _isLastPage = false;
  ScrollController _scrollController;

  List<dynamic> _marketPriceList;

  double _rate = 1.0;

  Future<void> _updateData() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    widget.service.plugin.updateBalances(widget.service.keyring.current);

    final res = await widget.service.assets.updateTxs(_txsPage);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _txsPage += 1;
    });

    if (res['transfers'] == null ||
        res['transfers'].length < tx_list_page_size) {
      setState(() {
        _isLastPage = true;
      });
    }
  }

  Future<void> _refreshData() async {
    if (widget.service.plugin.sdk.api.connectedNode == null) return;

    setState(() {
      _txsPage = 0;
      _isLastPage = false;
    });

    widget.service.assets
        .fetchMarketPrices(widget.service.plugin.networkState.tokenSymbol);

    await _updateData();
  }

  void _showAction() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => PolkawalletActionSheet(
        actions: <Widget>[
          PolkawalletActionSheetAction(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(I18n.of(context)
                    .getDic(i18n_full_dic_app, 'assets')['address.subscan']),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              ],
            ),
            onPressed: () {
              String networkName = widget.service.plugin.basic.name;
              if (widget.service.plugin.basic.isTestNet) {
                networkName = '${networkName.split('-')[0]}-testnet';
              }
              final snLink =
                  'https://$networkName.subscan.io/account/${widget.service.keyring.current.address}';
              UI.launchURL(snLink);
              Navigator.of(context).pop();
            },
          ),
        ],
        cancelButton: PolkawalletActionSheetAction(
          child: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WalletApi.getMarketPriceList(
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0], 7)
        .then((value) {
      if (mounted) {
        setState(() {
          if (value['data'] != null) {
            _marketPriceList = value['data']['price'] as List;
          }
        });
      }
    });

    if (widget.service.plugin.basic.name == para_chain_name_acala ||
        widget.service.plugin.basic.name == para_chain_name_karura) return;

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        if (_tab == 0 && !_isLastPage) {
          _updateData();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
      getRate();
    });
  }

  Future<void> getRate() async {
    var rate = await widget.service.store.settings.getRate();
    setState(() {
      this._rate = rate;
    });
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  List<Widget> _buildTxList() {
    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final txs = widget.service.store.assets.txs.toList();
    txs.retainWhere((e) {
      switch (_tab) {
        case 1:
          return e.to == widget.service.keyring.current.address;
        case 2:
          return e.from == widget.service.keyring.current.address;
        default:
          return true;
      }
    });
    final List<Widget> res = [];
    res.addAll(txs.map((i) {
      return Column(
        children: [
          TransferListItem(
            data: i,
            token: symbol,
            isOut: i.from == widget.service.keyring.current.address,
            crossChain: i.to == bridge_account['acala'] ? 'Acala Bridge' : null,
            hasDetail: true,
          ),
          Divider(
            height: 1,
          )
        ],
      );
    }));

    res.add(ListTail(
      isEmpty: txs.length == 0,
      isLoading: _loading,
    ));

    return res;
  }

  List<TimeSeriesAmount> getTimeSeriesAmounts(List<dynamic> marketPriceList) {
    List<TimeSeriesAmount> datas = [];
    for (int i = 0; i < marketPriceList.length; i++) {
      datas.add(TimeSeriesAmount(
          DateTime.now().add(Duration(days: -1 * i)), i * 1.0));
    }
    return datas;
  }

  List<Color> getBgColors() {
    switch (widget.service.plugin.basic.name) {
      case relay_chain_name_ksm:
      case para_chain_name_statemine:
        return [Color(0xFF767575), Color(0xFF2A2A2B)];
      case para_chain_name_karura:
        return [Color(0xFF2B292A), Color(0xFFCD4337)];
      case para_chain_name_acala:
        return [Color(0xFFFD4732), Color(0xFF645AFF)];
      case para_chain_name_bifrost:
        return [
          Color(0xFF5AAFE1),
          Color(0xFF596ED2),
          Color(0xFFB358BD),
          Color(0xFFFFAE5E)
        ];
      case relay_chain_name_dot:
        return [Color(0xFFDD1878), Color(0xFF72AEFF)];
      case chain_name_edgeware:
        return [Color(0xFF21C1D5), Color(0xFF057AA9)];
      case chain_name_dbc:
        return [Color(0xFF5BC1D3), Color(0xFF374BD4)];
      default:
        return [Theme.of(context).primaryColor, Theme.of(context).hoverColor];
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: UI.isDarkTheme(context)
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        title: Text(symbol),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackBtn(),
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: v3.IconButton(
                  isBlueBg: true,
                  icon: Icon(
                    Icons.more_horiz,
                    color: Theme.of(context).cardColor,
                    size: 22,
                  ),
                  onPressed: _showAction)),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Observer(
        builder: (_) {
          BalanceData balancesInfo = widget.service.plugin.balances.native;
          final txs = widget.service.plugin.getNativeTokenTransfers(
              address: widget.service.keyring.current.address,
              transferType: _tab);
          return Column(
            children: <Widget>[
              BalanceCard(
                balancesInfo,
                symbol: symbol,
                decimals: decimals,
                marketPrices:
                    (widget.service.store.assets.marketPrices[symbol] ?? 0) *
                        (widget.service.store.settings.priceCurrency == "CNY"
                            ? _rate
                            : 1.0),
                // backgroundImage: widget.service.plugin.basic.backgroundImage,
                bgColors: getBgColors(),
                icon: widget.service.plugin.tokenIcons[symbol],
                marketPriceList: _marketPriceList,
                priceCurrency: widget.service.store.settings.priceCurrency,
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: CardButton(
                            icon: Padding(
                              padding: EdgeInsets.only(left: 3),
                              child: Image.asset(
                                "assets/images/send${UI.isDarkTheme(context) ? "_dark" : ""}.png",
                                width: 32,
                                color: UI.isDarkTheme(context)
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                            text: dic['transfer'],
                            onPressed: () {
                              if (widget.service.plugin.basic.name ==
                                      para_chain_name_karura ||
                                  widget.service.plugin.basic.name ==
                                      para_chain_name_acala) {
                                final symbol = (widget.service.plugin
                                        .networkState.tokenSymbol ??
                                    [''])[0];
                                Navigator.of(context).pushNamed(
                                    '/assets/token/transfer',
                                    arguments: {'tokenNameId': symbol});
                                return;
                              }
                              Navigator.pushNamed(context, TransferPage.route);
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: CardButton(
                            icon: Image.asset(
                              "assets/images/qr${UI.isDarkTheme(context) ? "_dark" : ""}.png",
                              width: 32,
                              color:
                                  UI.isDarkTheme(context) ? Colors.white : null,
                            ),
                            text: dic['receive'],
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AccountQrCodePage.route);
                            },
                          ),
                        ),
                      ),
                      Fmt.balanceInt((balancesInfo?.lockedBalance ?? 0)
                                  .toString()) >
                              BigInt.one
                          ? Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 3.w),
                                child: CardButton(
                                  icon: Image.asset(
                                    "assets/images/unlock${UI.isDarkTheme(context) ? "_dark" : ""}.png",
                                    width: 32,
                                    color: UI.isDarkTheme(context)
                                        ? Colors.white
                                        : null,
                                  ),
                                  text: dic['unlock'],
                                  onPressed: Fmt.balanceInt(
                                              (balancesInfo?.lockedBalance ?? 0)
                                                  .toString()) >
                                          BigInt.one
                                      ? () {
                                          Navigator.pushNamed(
                                              context, LocksDetailPage.route);
                                        }
                                      : null,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  )),
              Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BorderedTitle(title: dic['history']),
                      Row(
                        children: [
                          Container(
                            width: 36.w,
                            height: 28.h,
                            margin: EdgeInsets.only(right: 8.w),
                            decoration: BoxDecoration(
                              color: UI.isDarkTheme(context)
                                  ? Color(0x52000000)
                                  : Colors.transparent,
                              borderRadius: UI.isDarkTheme(context)
                                  ? BorderRadius.all(Radius.circular(5))
                                  : null,
                              border: UI.isDarkTheme(context)
                                  ? Border.all(
                                      color: Color(0x26FFFFFF), width: 1)
                                  : null,
                              image: UI.isDarkTheme(context)
                                  ? null
                                  : DecorationImage(
                                      image: AssetImage(
                                          "assets/images/bg_tag.png"),
                                      fit: BoxFit.fill),
                            ),
                            child: Center(
                              child: Text(
                                  dic[_tab == 0
                                      ? 'all'
                                      : _tab == 1
                                          ? "in"
                                          : "out"],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5
                                      .copyWith(
                                          color: UI.isDarkTheme(context)
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .toggleableActiveColor,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup(
                                    context: context,
                                    builder: (context) {
                                      return ShowCustomAlterWidget(
                                          confirmCallback: (value) {
                                            setState(() {
                                              if (value == dic['all']) {
                                                _tab = 0;
                                              } else if (value == dic['in']) {
                                                _tab = 1;
                                              } else {
                                                _tab = 2;
                                              }
                                            });
                                          },
                                          cancel: I18n.of(context).getDic(
                                              i18n_full_dic_ui,
                                              'common')['cancel'],
                                          options: [
                                            dic['all'],
                                            dic['in'],
                                            dic['out']
                                          ]);
                                    });
                              },
                              child: v3.IconButton(
                                icon: SvgPicture.asset(
                                  'assets/images/icon_screening.svg',
                                  color: UI.isDarkTheme(context)
                                      ? Colors.white
                                      : Color(0xFF979797),
                                  width: 22.h,
                                ),
                              ))
                        ],
                      )
                    ],
                  )),
              Divider(
                height: 1,
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).cardColor,
                  child: txs == null
                      ? RefreshIndicator(
                          key: _refreshKey,
                          onRefresh: _refreshData,
                          child: ListView(
                            physics: BouncingScrollPhysics(),
                            controller: _scrollController,
                            children: [..._buildTxList()],
                          ),
                        )
                      : txs,
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  BalanceCard(this.balancesInfo,
      {this.marketPrices,
      this.symbol,
      this.decimals,
      // this.backgroundImage,
      this.bgColors,
      this.icon,
      this.marketPriceList,
      this.priceCurrency});

  final String symbol;
  final int decimals;
  final BalanceData balancesInfo;
  final double marketPrices;
  // final ImageProvider backgroundImage;
  final List<Color> bgColors;
  final Widget icon;
  final List<dynamic> marketPriceList;
  final String priceCurrency;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final balance = Fmt.balanceTotal(balancesInfo);

    String tokenPrice;
    if (marketPrices != null && balancesInfo != null) {
      tokenPrice =
          Fmt.priceFloor(marketPrices * Fmt.bigIntToDouble(balance, decimals));
    }

    final titleColor =
        UI.isDarkTheme(context) ? Colors.white : Theme.of(context).cardColor;
    final child = Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(const Radius.circular(8)),
        gradient: LinearGradient(
          colors: bgColors ??
              [Theme.of(context).primaryColor, Theme.of(context).hoverColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // image: backgroundImage != null
        //     ? DecorationImage(
        //         image: backgroundImage,
        //         fit: BoxFit.cover,
        //       )
        //     : null,
        boxShadow: [
          BoxShadow(
            // color: primaryColor.withAlpha(100),
            color: Color(0x5D000000),
            blurRadius: 3.0,
            spreadRadius: 0.0,
            offset: Offset(2.0, 2.0),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.only(bottom: 22.h),
              child: Row(
                children: [
                  Container(
                      height: 45.w,
                      width: 45.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(22.5.w)),
                      ),
                      child: icon),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Fmt.token(balance, decimals, length: 8),
                        style: TextStyle(
                            color: titleColor,
                            fontSize: UI.getTextSize(20, context),
                            letterSpacing: -0.8,
                            fontWeight: FontWeight.w600,
                            fontFamily:
                                UI.getFontFamily('TitilliumWeb', context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Visibility(
                        visible: tokenPrice != null,
                        child: Text(
                          '≈ ${Utils.currencySymbol(priceCurrency)} ${tokenPrice ?? '--.--'}',
                          style: Theme.of(context).textTheme.headline6.copyWith(
                              color: titleColor,
                              letterSpacing: -0.8,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    priceItemBuild(
                        SvgPicture.asset(
                          'assets/images/transferrable_icon.svg',
                          color: titleColor,
                        ),
                        dic['available'],
                        Fmt.priceFloorBigInt(
                          Fmt.balanceInt(
                              (balancesInfo?.availableBalance ?? 0).toString()),
                          decimals,
                          lengthMax: 4,
                        ),
                        titleColor,
                        context),
                    priceItemBuild(
                        SvgPicture.asset(
                          'assets/images/locked_icon.svg',
                          color: titleColor,
                        ),
                        dic['locked'],
                        Fmt.priceFloorBigInt(
                          Fmt.balanceInt(
                              (balancesInfo?.lockedBalance ?? 0).toString()),
                          decimals,
                          lengthMax: 4,
                        ),
                        titleColor,
                        context),
                    priceItemBuild(
                        SvgPicture.asset(
                          'assets/images/reversed_icon.svg',
                          color: titleColor,
                        ),
                        dic['reserved'],
                        Fmt.priceFloorBigInt(
                          Fmt.balanceInt(
                              (balancesInfo?.reservedBalance ?? 0).toString()),
                          decimals,
                          lengthMax: 4,
                        ),
                        titleColor,
                        context),
                  ],
                ),
                flex: 1,
              ),
              Expanded(
                child: marketPriceList != null
                    ? Container(
                        width: MediaQuery.of(context).size.width / 3,
                        alignment: Alignment.centerRight,
                        child: RewardsChart.withData(
                            getTimeSeriesAmounts(marketPriceList),
                            MediaQuery.of(context).size.width / 4))
                    : Container(width: MediaQuery.of(context).size.width / 3),
                flex: 0,
              )
            ],
          ),
        ],
      ),
    );
    return UI.isDarkTheme(context)
        ? RoundedCard(
            margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.w),
            child: child,
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.w), child: child);
  }

  List<TimeSeriesAmount> getTimeSeriesAmounts(List<dynamic> marketPriceList) {
    List<TimeSeriesAmount> datas = [];
    for (int i = 0; i < marketPriceList.length; i++) {
      datas.add(TimeSeriesAmount(DateTime.now().add(Duration(days: -1 * i)),
          marketPriceList[i] * 1.0));
    }
    return datas;
  }

  Widget priceItemBuild(Widget icon, String title, String price, Color color,
      BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                height: 18.w,
                width: 18.w,
                padding: EdgeInsets.all(2),
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(27),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                child: icon),
            Text(
              title,
              style: TextStyle(
                  color: color,
                  fontSize: UI.getTextSize(12, context),
                  fontWeight: FontWeight.w600,
                  fontFamily: UI.getFontFamily('TitilliumWeb', context)),
            ),
            Expanded(
              child: Text(
                price,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: color,
                    fontSize: UI.getTextSize(12, context),
                    fontWeight: FontWeight.w400,
                    fontFamily: UI.getFontFamily('TitilliumWeb', context)),
              ),
            )
          ],
        ));
  }
}

class TransferListItem extends StatelessWidget {
  TransferListItem({
    this.data,
    this.token,
    this.isOut,
    this.hasDetail,
    this.crossChain,
  });

  final TransferData data;
  final String token;
  final String crossChain;
  final bool isOut;
  final bool hasDetail;

  @override
  Widget build(BuildContext context) {
    final address = isOut ? data.to : data.from;
    final title =
        Fmt.address(address) ?? data.extrinsicIndex ?? Fmt.address(data.hash);
    final colorFailed = Theme.of(context).unselectedWidgetColor;
    final amount = Fmt.priceFloor(double.parse(data.amount), lengthFixed: 4);
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          data.success
              ? isOut
                  ? TransferIcon(type: TransferIconType.rollOut)
                  : TransferIcon(type: TransferIconType.rollIn)
              : TransferIcon(type: TransferIconType.failure)
        ],
      ),
      title: Text('$title${crossChain != null ? ' ($crossChain)' : ''}',
          style: Theme.of(context).textTheme.headline4),
      subtitle: Text(
        Fmt.dateTime(
            DateTime.fromMillisecondsSinceEpoch(data.blockTimestamp * 1000)),
      ),
      trailing: Container(
        width: 110,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${isOut ? '-' : '+'} $amount',
                style: Theme.of(context).textTheme.headline5.copyWith(
                    color: Theme.of(context).toggleableActiveColor,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      onTap: hasDetail
          ? () {
              Navigator.pushNamed(
                context,
                TransferDetailPage.route,
                arguments: data,
              );
            }
          : null,
    );
  }
}
