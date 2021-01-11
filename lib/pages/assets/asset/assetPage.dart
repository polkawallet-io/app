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
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AssetPage extends StatefulWidget {
  AssetPage(this.service);
  final AppService service;

  static final String route = '/assets/detail';

  @override
  _AssetPageState createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  bool _loading = false;

  TabController _tabController;
  int _tab = 0;
  int _txsPage = 0;
  bool _isLastPage = false;
  ScrollController _scrollController;

  List _unlocks = [];

  Future<void> _queryDemocracyUnlocks() async {
    final List unlocks = await widget.service.plugin.sdk.api.gov
        .getDemocracyUnlocks(widget.service.keyring.current.address);
    if (mounted && unlocks != null && unlocks.length > 0) {
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
          rawParams: '[[${txs.join(',')}]]',
        ));
    if (res != null) {
      _refreshKey.currentState.show();
    }
  }

  Future<void> _updateData() async {
    if (widget.service.plugin.sdk.api.connectedNode == null || _loading) return;
    setState(() {
      _loading = true;
    });

    _queryDemocracyUnlocks();
    final res = await widget.service.assets.updateTxs(_txsPage);

    if (!mounted) return;
    setState(() {
      _loading = false;
    });

    if (res['transfers'] == null ||
        res['transfers'].length < tx_list_page_size) {
      setState(() {
        _isLastPage = true;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _txsPage = 0;
      _isLastPage = false;
    });

    widget.service.assets.fetchMarketPrice();

    await _updateData();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        setState(() {
          if (_tabController.index == 0 && !_isLastPage) {
            _txsPage += 1;
            _updateData();
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Widget> _buildTxList() {
    final symbol = widget.service.plugin.networkState.tokenSymbol;
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
    final List<Tab> _myTabs = <Tab>[
      Tab(text: dic['all']),
      Tab(text: dic['in']),
      Tab(text: dic['out']),
    ];

    final decimals = widget.service.plugin.networkState.tokenDecimals;
    final symbol = widget.service.plugin.networkState.tokenSymbol;

    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(symbol),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            BigInt balance =
                Fmt.balanceTotal(widget.service.plugin.balances.native);

            BalanceData balancesInfo = widget.service.plugin.balances.native;
            String lockedInfo = '\n';
            if (balancesInfo != null && balancesInfo.lockedBreakdown != null) {
              balancesInfo.lockedBreakdown.forEach((i) {
                final amt = Fmt.balanceInt(i.amount.toString());
                if (amt > BigInt.zero) {
                  lockedInfo += '${Fmt.priceFloorBigInt(
                    amt,
                    decimals,
                    lengthMax: 3,
                  )} $symbol ${dic['lock.${i.use.trim()}']}\n';
                }
              });
            }

            String tokenPrice;
            if (widget.service.store.assets.marketPrices[symbol] != null &&
                balancesInfo != null) {
              tokenPrice = Fmt.priceFloor(
                  widget.service.store.assets.marketPrices[symbol] *
                      Fmt.bigIntToDouble(balance, decimals));
            }

            return Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: primaryColor,
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: tokenPrice != null ? 4 : 16),
                        child: Text(
                          Fmt.token(balance, decimals, length: 8),
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      tokenPrice != null
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                '≈ \$ ${tokenPrice ?? '--.--'}',
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                ),
                              ),
                            )
                          : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Column(
                            children: [
                              Text(
                                dic['locked'],
                                style:
                                    TextStyle(color: titleColor, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  lockedInfo.length > 2
                                      ? TapTooltip(
                                          message: lockedInfo,
                                          child: Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: Icon(
                                              Icons.info,
                                              size: 16,
                                              color: titleColor,
                                            ),
                                          ),
                                          waitDuration: Duration(seconds: 0),
                                        )
                                      : Container(),
                                  Text(
                                    Fmt.priceFloorBigInt(
                                      Fmt.balanceInt(balancesInfo.lockedBalance
                                          .toString()),
                                      decimals,
                                      lengthMax: 3,
                                    ),
                                    style: TextStyle(color: titleColor),
                                  ),
                                  _unlocks.length > 0
                                      ? GestureDetector(
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 6),
                                            child: Icon(
                                              Icons.lock_open,
                                              size: 16,
                                              color: titleColor,
                                            ),
                                          ),
                                          onTap: _onUnlock,
                                        )
                                      : Container(),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                dic['available'],
                                style:
                                    TextStyle(color: titleColor, fontSize: 12),
                              ),
                              Text(
                                Fmt.priceFloorBigInt(
                                  Fmt.balanceInt(
                                      balancesInfo.availableBalance.toString()),
                                  decimals,
                                  lengthMax: 3,
                                ),
                                style: TextStyle(color: titleColor),
                              )
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                dic['reserved'],
                                style:
                                    TextStyle(color: titleColor, fontSize: 12),
                              ),
                              Text(
                                Fmt.priceFloorBigInt(
                                  Fmt.balanceInt(
                                      balancesInfo.reservedBalance.toString()),
                                  decimals,
                                  lengthMax: 3,
                                ),
                                style: TextStyle(color: titleColor),
                              )
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: Colors.black87,
                  labelStyle: TextStyle(fontSize: 18),
                  controller: _tabController,
                  tabs: _myTabs,
                  onTap: (i) {
                    setState(() {
                      _tab = i;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: _refreshData,
                      child: ListView(
                        controller: _scrollController,
                        children: _buildTxList(),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        color: Colors.lightBlue,
                        child: FlatButton(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  height: 24,
                                  child: Image.asset(
                                      'assets/images/assets_send.png'),
                                ),
                              ),
                              Text(
                                dic['transfer'],
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              TransferPage.route,
                              arguments: TransferPageParams(
                                redirect: AssetPage.route,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.lightGreen,
                        child: FlatButton(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.qr_code,
                                    color: titleColor, size: 24),
                              ),
                              Text(
                                dic['receive'],
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                                context, AccountQrCodePage.route);
                          },
                        ),
                      ),
                    )
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
    String address = isOut ? data.to : data.from;
    String title =
        Fmt.address(address) ?? data.extrinsicIndex ?? Fmt.address(data.hash);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.5, color: Colors.black12)),
      ),
      child: ListTile(
        leading: data.success
            ? Icon(Icons.check_circle, color: Colors.lightGreen, size: 28)
            : Icon(Icons.error, color: Colors.red, size: 28),
        title: Text('$title${crossChain != null ? ' ($crossChain)' : ''}'),
        subtitle: Text(Fmt.dateTime(
            DateTime.fromMillisecondsSinceEpoch(data.blockTimestamp * 1000))),
        trailing: Container(
          width: 110,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  Fmt.priceFloor(double.parse(data.amount), lengthMax: 3),
                  style: Theme.of(context).textTheme.headline4,
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 4),
                width: 16,
                child: isOut
                    ? Image.asset('assets/images/assets_up.png')
                    : Image.asset('assets/images/assets_down.png'),
              )
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
      ),
    );
  }
}
