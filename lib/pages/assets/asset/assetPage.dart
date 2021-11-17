import 'package:app/pages/assets/asset/locksDetailPage.dart';
import 'package:app/pages/assets/transfer/detailPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/service/index.dart';
import 'package:app/store/types/transferData.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/MainTabBar.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/TransferIcon.dart';

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
  int _txsPage = 0;
  bool _isLastPage = false;
  ScrollController _scrollController;

  List _unlocks = [];

  Future<void> _queryDemocracyUnlocks() async {
    final List unlocks = await widget.service.plugin.sdk.api.gov
        .getDemocracyUnlocks(widget.service.keyring.current.address);
    if (mounted && unlocks != null) {
      setState(() {
        _unlocks = unlocks;
      });
    }
  }

  void _onUnlock() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final txs = _unlocks
        .map(
            (e) => 'api.tx.democracy.removeVote(${BigInt.parse(e.toString())})')
        .toList();
    txs.add(
        'api.tx.democracy.unlock("${widget.service.keyring.current.address}")');
    final res = await Navigator.of(context).pushNamed(TxConfirmPage.route,
        arguments: TxConfirmParams(
            txTitle: dic['lock.unlock'],
            module: 'utility',
            call: 'batch',
            txDisplay: {
              "actions": ['democracy.removeVote', 'democracy.unlock'],
            },
            params: [],
            rawParams: '[[${txs.join(',')}]]'));
    if (res != null) {
      _refreshKey.currentState.show();
    }
  }

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

    if (widget.service.plugin.basic.name == 'polkadot' ||
        widget.service.plugin.basic.name == 'kusama') {
      _queryDemocracyUnlocks();
    }

    setState(() {
      _txsPage = 0;
      _isLastPage = false;
    });

    widget.service.assets.fetchMarketPriceFromSubScan();

    await _updateData();
  }

  void _showAction() async {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
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
        cancelButton: CupertinoActionSheetAction(
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
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      return TransferListItem(
        data: i,
        token: symbol,
        isOut: i.from == widget.service.keyring.current.address,
        hasDetail: true,
      );
    }));

    res.add(ListTail(
      isEmpty: txs.length == 0,
      isLoading: _loading,
    ));

    return res;
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

    final titleColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          symbol,
          style: TextStyle(fontSize: 20, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: Colors.black87,
              ),
              onPressed: _showAction),
        ],
      ),
      backgroundColor: titleColor,
      body: SafeArea(
        child: Observer(
          builder: (_) {
            bool transferEnabled = true;
            if (widget.service.plugin.basic.name == 'karura' ||
                widget.service.plugin.basic.name == 'acala') {
              transferEnabled = false;
              if (widget.service.store.settings.liveModules['assets'] != null) {
                transferEnabled = widget
                    .service.store.settings.liveModules['assets']['enabled'];
              }
            }

            BalanceData balancesInfo = widget.service.plugin.balances.native;
            return Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: _refreshData,
                      child: ListView(
                        controller: _scrollController,
                        children: [
                          BalanceCard(
                            balancesInfo,
                            symbol: symbol,
                            decimals: decimals,
                            marketPrices:
                                widget.service.store.assets.marketPrices,
                            backgroundImage:
                                widget.service.plugin.basic.backgroundImage,
                            unlocks: _unlocks,
                            onUnlock: _onUnlock,
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: MainTabBar(
                              tabs: [dic['all'], dic['in'], dic['out']],
                              activeTab: _tab,
                              onTap: (i) {
                                setState(() {
                                  _tab = i;
                                });
                              },
                            ),
                          ),
                          ..._buildTxList()
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: RoundedButton(
                          icon:
                              Icon(Icons.qr_code, color: titleColor, size: 24),
                          text: dic['receive'],
                          color: colorIn,
                          onPressed: () {
                            Navigator.pushNamed(
                                context, AccountQrCodePage.route);
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
                        child: RoundedButton(
                          icon: SizedBox(
                            height: 20,
                            child: Image.asset('assets/images/assets_send.png'),
                          ),
                          text: dic['transfer'],
                          color: colorOut,
                          onPressed: transferEnabled
                              ? () {
                                  Navigator.pushNamed(
                                    context,
                                    TransferPage.route,
                                    arguments: TransferPageParams(
                                      redirect: AssetPage.route,
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  BalanceCard(this.balancesInfo,
      {this.marketPrices,
      this.symbol,
      this.decimals,
      this.backgroundImage,
      this.unlocks,
      this.onUnlock});

  final String symbol;
  final int decimals;
  final BalanceData balancesInfo;
  final Map marketPrices;
  final ImageProvider backgroundImage;
  final List unlocks;
  final Function onUnlock;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final balance = Fmt.balanceTotal(balancesInfo);

    String lockedInfo = '\n';
    bool hasVesting = false;
    if (balancesInfo != null && balancesInfo.lockedBreakdown != null) {
      balancesInfo.lockedBreakdown.forEach((i) {
        final amt = Fmt.balanceInt(i.amount.toString());
        if (amt > BigInt.zero) {
          lockedInfo += '${Fmt.priceFloorBigInt(
            amt,
            decimals,
            lengthMax: 4,
          )} $symbol ${dic['lock.${i.use.trim()}']}\n';
          if (i.use.contains('ormlvest')) {
            hasVesting = true;
          }
        }
      });
    }

    String tokenPrice;
    if (marketPrices[symbol] != null && balancesInfo != null) {
      tokenPrice = Fmt.priceFloor(
          marketPrices[symbol] * Fmt.bigIntToDouble(balance, decimals));
    }

    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).cardColor;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
      constraints: BoxConstraints(maxHeight: 200, maxWidth: 480),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(const Radius.circular(16)),
        gradient: LinearGradient(
          colors: [primaryColor, Theme.of(context).accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.1, 0.9],
        ),
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(100),
            blurRadius: 16.0,
            spreadRadius: 2.0,
            offset: Offset(2.0, 6.0),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              dic['balance'],
              style: TextStyle(color: titleColor),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: tokenPrice != null ? 4 : 24),
            child: Text(
              Fmt.token(balance, decimals, length: 8),
              style: TextStyle(
                color: titleColor,
                fontSize: 30,
                letterSpacing: -0.8,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Visibility(
              visible: tokenPrice != null,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '≈ \$ ${tokenPrice ?? '--.--'}',
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                  ),
                ),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                height: 24,
                width: 0,
              ),
              InfoItem(
                title: dic['reserved'],
                content: Fmt.priceFloorBigInt(
                  Fmt.balanceInt(
                      (balancesInfo?.reservedBalance ?? 0).toString()),
                  decimals,
                  lengthMax: 4,
                ),
                crossAxisAlignment: CrossAxisAlignment.center,
                color: titleColor,
                titleColor: titleColor,
                flex: 0,
                lowTitle: true,
              ),
              Container(
                height: 24,
                width: 0,
                decoration: BoxDecoration(
                    border: Border(
                  left: BorderSide(
                      color: Theme.of(context).cardColor, width: 0.5),
                )),
              ),
              InfoItem(
                title: dic['available'],
                content: Fmt.priceFloorBigInt(
                  Fmt.balanceInt(
                      (balancesInfo?.availableBalance ?? 0).toString()),
                  decimals,
                  lengthMax: 4,
                ),
                crossAxisAlignment: CrossAxisAlignment.center,
                color: titleColor,
                titleColor: titleColor,
                flex: 0,
                lowTitle: true,
              ),
              Container(
                height: 24,
                width: 0,
                decoration: BoxDecoration(
                    border: Border(
                  left: BorderSide(
                      color: Theme.of(context).cardColor, width: 0.5),
                )),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Visibility(
                          visible: lockedInfo.length > 2,
                          child: hasVesting
                              ? GestureDetector(
                                  child: Container(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info,
                                            size: 16, color: titleColor),
                                        priceBuild(balancesInfo, titleColor),
                                      ],
                                    ),
                                  ),
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(LocksDetailPage.route),
                                )
                              : TapTooltip(
                                  message: lockedInfo,
                                  child: Row(
                                    children: [
                                      Icon(Icons.info,
                                          size: 16, color: titleColor),
                                      priceBuild(balancesInfo, titleColor),
                                    ],
                                  ),
                                  waitDuration: Duration(seconds: 0),
                                )),
                      Visibility(
                          visible: lockedInfo.length <= 2,
                          child: priceBuild(balancesInfo, titleColor)),
                      Visibility(
                          visible: unlocks.length > 0,
                          child: GestureDetector(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.lock_open,
                                size: 16,
                                color: titleColor,
                              ),
                            ),
                            onTap: onUnlock,
                          )),
                    ],
                  ),
                  Text(
                    dic['locked'],
                    style: TextStyle(color: titleColor, fontSize: 12),
                  ),
                ],
              ),
              Container(
                height: 24,
                width: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget priceBuild(BalanceData balancesInfo, Color titleColor) {
    return Text(
      Fmt.priceFloorBigInt(
        Fmt.balanceInt((balancesInfo?.lockedBalance ?? 0).toString()),
        decimals,
        lengthMax: 4,
      ),
      style: TextStyle(color: titleColor),
    );
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

  final colorIn = Color(0xFF62CFE4);
  final colorOut = Color(0xFF3394FF);

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
              : TransferIcon(
                  type: TransferIconType.failure,
                  paddingHorizontal: 7,
                )
        ],
      ),
      title: Text('$title${crossChain != null ? ' ($crossChain)' : ''}'),
      subtitle: Text(Fmt.dateTime(
          DateTime.fromMillisecondsSinceEpoch(data.blockTimestamp * 1000))),
      trailing: Container(
        width: 110,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${isOut ? '-' : '+'} $amount',
                style: TextStyle(
                    color: data.success
                        ? isOut
                            ? colorOut
                            : colorIn
                        : colorFailed,
                    fontSize: 16),
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
