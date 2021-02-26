import 'package:app/pages/assets/transfer/detailPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/service/index.dart';
import 'package:app/store/types/transferData.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:polkawallet_sdk/api/subscan.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

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

    if (widget.service.plugin.basic.name == 'polkadot' ||
        widget.service.plugin.basic.name == 'kusama') {
      _queryDemocracyUnlocks();
    }

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
        setState(() {
          if (_tab == 0 && !_isLastPage) {
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

    final primaryColor = Theme.of(context).primaryColor;
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
          IconButton(icon: Icon(Icons.more_horiz), onPressed: _showAction),
        ],
      ),
      backgroundColor: Theme.of(context).cardColor,
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
                    lengthMax: 4,
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
                  margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: EdgeInsets.fromLTRB(8, 24, 8, 24),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(const Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [primaryColor, Theme.of(context).accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.1, 0.9],
                    ),
                    image: DecorationImage(
                      image: widget.service.plugin.basic.backgroundImage,
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(100),
                        blurRadius:
                            16.0, // has the effect of softening the shadow
                        spreadRadius:
                            2.0, // has the effect of extending the shadow
                        offset: Offset(
                          2.0, // horizontal, move right 10
                          6.0, // vertical, move down 10
                        ),
                      )
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          dic['balance'],
                          style: TextStyle(color: titleColor),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: tokenPrice != null ? 4 : 24),
                        child: Text(
                          Fmt.token(balance, decimals, length: 8),
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      tokenPrice != null
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 24),
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
                                dic['reserved'],
                                style:
                                    TextStyle(color: titleColor, fontSize: 12),
                              ),
                              Text(
                                Fmt.priceFloorBigInt(
                                  Fmt.balanceInt(
                                      balancesInfo.reservedBalance.toString()),
                                  decimals,
                                  lengthMax: 4,
                                ),
                                style: TextStyle(color: titleColor),
                              )
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
                                  lengthMax: 4,
                                ),
                                style: TextStyle(color: titleColor),
                              )
                            ],
                          ),
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
                                      lengthMax: 4,
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
                        ],
                      ),
                    ],
                  ),
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
    final address = isOut ? data.to : data.from;
    final title =
        Fmt.address(address) ?? data.extrinsicIndex ?? Fmt.address(data.hash);
    final colorIn = Color(0xFF62CFE4);
    final colorOut = Color(0xFF3394FF);
    final colorFailed = Theme.of(context).unselectedWidgetColor;
    final amount = Fmt.priceFloor(double.parse(data.amount), lengthFixed: 4);
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          data.success
              ? isOut
                  ? SvgPicture.asset('assets/images/assets_up.svg', width: 32)
                  : SvgPicture.asset('assets/images/assets_down.svg', width: 32)
              : SvgPicture.asset('assets/images/tx_failed.svg', width: 32)
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

class MainTabBar extends StatelessWidget {
  MainTabBar({this.tabs, this.activeTab, this.onTap});

  final List<String> tabs;
  final Function(int) onTap;
  final int activeTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.map((e) {
        final isActive = tabs[activeTab] == e;
        return GestureDetector(
          child: isActive
              ? Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: Column(
                    children: [
                      Text(e.toUpperCase(),
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      Container(
                        width: 24,
                        height: 8,
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Theme.of(context).primaryColor),
                      )
                    ],
                  ),
                )
              : Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: Column(children: [
                    Text(e.toUpperCase(), style: TextStyle(fontSize: 20)),
                    Container(width: 24, height: 8)
                  ]),
                ),
          onTap: () => onTap(tabs.indexOf(e)),
        );
      }).toList(),
    );
  }
}
