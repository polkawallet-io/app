import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/components/v3/innerShadow.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LocksDetailPage extends StatefulWidget {
  LocksDetailPage(this.service);
  final AppService service;

  static final String route = '/assets/vesting';

  @override
  LocksDetailPageState createState() => LocksDetailPageState();
}

class LocksDetailPageState extends State<LocksDetailPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  BigInt _unlocking;
  BigInt _claimable;
  BigInt _originalLocked;

  bool _submitting = false;

  List _locks = [];
  int bestNumber = 0;

  Future<void> _queryDemocracyLocks() async {
    final res = await widget.service.plugin.sdk.webView
        .evalJavascript('api.derive.chain.bestNumber()');
    bestNumber = int.parse(res.toString());
    final List locks = await widget.service.plugin.sdk.api.gov
        .getDemocracyLocks(widget.service.keyring.current.address);
    if (mounted && locks != null) {
      setState(() {
        _locks = locks;
      });
    }
  }

  void _onUnlock(List<String> ids) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final txs = ids
        .map((e) => 'api.tx.democracy.removeVote(${BigInt.parse(e)})')
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

  Future<void> _refreshUnlockDatas() async {
    await _queryDemocracyLocks();
    if (widget.service.plugin.basic.name == para_chain_name_karura ||
        widget.service.plugin.basic.name == para_chain_name_acala) {
      await _updateVestingInfo();
    }
  }

  Future<void> _updateVestingInfo() async {
    final unlockdatas =
        await WalletApi.getUnlockDatas(widget.service.keyring.current.address);
    BigInt originalLocked;
    if (unlockdatas != null) {
      if (widget.service.plugin.basic.name == para_chain_name_karura) {
        originalLocked = BigInt.from(double.parse((unlockdatas['data']
                [widget.service.plugin.basic.name][0]['vested'])
            .toString()
            .splitMapJoin(",", onMatch: (Match match) {
          return "";
        })));
      } else {
        originalLocked = BigInt.from(double.parse((unlockdatas['data']
                    [widget.service.plugin.basic.name][0]['totalReward'])
                .toString()
                .splitMapJoin(",", onMatch: (Match match) {
              return "";
            })) *
            0.8);
      }
    }

    final res = await Future.wait([
      WalletApi.fetchBlocksFromSn(
          widget.service.plugin.basic.name == para_chain_name_karura
              ? 'kusama'
              : 'polkadot'),
      widget.service.plugin.sdk.webView.evalJavascript(
          'api.query.vesting.vestingSchedules("${widget.service.keyring.current.address}")')
    ]);
    if (res[0] != null && res[1] != null) {
      final blockNow = BigInt.from(res[0]['count']);
      final vestInfo = res[1][0];
      final periodBlocks = BigInt.parse(vestInfo['period'].toString());
      final periodCount = BigInt.parse(vestInfo['periodCount'].toString());
      final perPeriod = BigInt.parse(vestInfo['perPeriod'].toString());
      final startBlock = BigInt.parse(vestInfo['start'].toString());
      final endBlock = startBlock + periodCount * periodBlocks;
      var vestLeft = BigInt.zero;
      // final vestLeft = BigInt.parse(
      //     widget.service.plugin.balances.native.lockedBalance.toString());
      final locks =
          widget.service.plugin.balances.native.lockedBreakdown.toList();
      locks.retainWhere((e) => BigInt.parse(e.amount.toString()) > BigInt.zero);
      locks.forEach((element) {
        if (element.use.contains('ormlvest')) {
          vestLeft = BigInt.parse(element.amount.toString());
        }
      });
      final unlockingPeriod = endBlock - blockNow > BigInt.zero
          ? (endBlock - blockNow) ~/ periodBlocks + BigInt.one
          : BigInt.zero;
      final unlocking = unlockingPeriod * perPeriod;
      setState(() {
        _claimable = vestLeft - unlocking;
        _unlocking = unlocking;
        _originalLocked = originalLocked;
      });
    }
  }

  Future<void> _claimVest(
      String claimableAmount, int decimals, String symbol) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final params = TxConfirmParams(
        txTitle: '${dic['lock.vest.claim']} $symbol',
        module: 'vesting',
        call: 'claim',
        txDisplay: {'amount': '$claimableAmount $symbol'},
        params: []);
    setState(() {
      _submitting = true;
    });
    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params);
    if (res != null) {
      await _refreshKey.currentState.show();
    }
    setState(() {
      _submitting = false;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUnlockDatas();
      _refreshKey.currentState.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final decimals = widget.service.plugin.networkState.tokenDecimals[0];
    final symbol = widget.service.plugin.networkState.tokenSymbol[0];

    final locks =
        widget.service.plugin.balances.native.lockedBreakdown.toList();
    locks.retainWhere((e) => BigInt.parse(e.amount.toString()) > BigInt.zero);

    final hasClaim =
        _claimable != null && _claimable > BigInt.zero && !_submitting;
    final claimableAmount = Fmt.priceFloorBigInt(_claimable, decimals);
    return Scaffold(
      appBar: AppBar(
          title: Text('${dic['unlock']} ($symbol)'),
          centerTitle: true,
          leading: BackBtn()),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refreshUnlockDatas,
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  children: locks.map((e) {
                    final amt = BigInt.parse(e.amount.toString());
                    Widget Democracchild;
                    final List<String> unLockIds = [];
                    double maxLockAmount = 0, maxUnlockAmount = 0;
                    if (e.use.contains('democrac') && _locks.length > 0) {
                      for (int index = 0; index < _locks.length; index++) {
                        var unlockAt = _locks[index]['unlockAt'];
                        final amount = double.parse(Fmt.balance(
                          _locks[index]['balance'].toString(),
                          decimals,
                        ));
                        if (unlockAt != "0") {
                          BigInt endLeft;
                          try {
                            endLeft = BigInt.parse("${unlockAt.toString()}") -
                                BigInt.from(bestNumber);
                          } catch (e) {
                            endLeft = BigInt.parse("0x${unlockAt.toString()}") -
                                BigInt.from(bestNumber);
                          }
                          if (endLeft.toInt() <= 0) {
                            unLockIds.add(_locks[index]['referendumId']);
                            if (amount > maxUnlockAmount) {
                              maxUnlockAmount = amount;
                            }
                            continue;
                          }
                        }
                        if (amount > maxLockAmount) {
                          maxLockAmount = amount;
                        }
                      }
                      Democracchild = Column(
                        children: [
                          InfoItemRow(dic['lock.democrac.total'],
                              "${maxLockAmount + maxUnlockAmount}"),
                          InfoItemRow(
                              dic['lock.vest.unlocking'], "$maxLockAmount"),
                          InfoItemRow(
                            dic['lock.vest.claimable'],
                            "${maxUnlockAmount - maxLockAmount}",
                            labelStyle: Theme.of(context)
                                .textTheme
                                .headline5
                                .copyWith(fontSize: 18),
                            contentStyle: Theme.of(context)
                                .textTheme
                                .headline5
                                .copyWith(
                                    fontSize: 18,
                                    color: Color(0xFFE46B41),
                                    fontWeight: FontWeight.w600),
                          ),
                          // Visibility(
                          //     visible: maxUnlockAmount - maxLockAmount > 0,
                          //     child: Column(
                          //       children: [
                          //         Divider(height: 24),
                          //         Row(
                          //           mainAxisAlignment:
                          //               MainAxisAlignment.spaceBetween,
                          //           children: [
                          //             Text(
                          //                 '${dic['democracy.unlock']}:${maxUnlockAmount - maxLockAmount} $symbol'),
                          //             OutlinedButtonSmall(
                          //                 margin: EdgeInsets.only(left: 8),
                          //                 content: dic['lock.unlock'],
                          //                 active: true,
                          //                 onPressed: () {
                          //                   _onUnlock(unLockIds);
                          //                 })
                          //           ],
                          //         )
                          //       ],
                          //     ))
                        ],
                      );
                    }
                    if (e.use.contains('ormlvest')) {
                      return buildItem(
                          title: "Vesting",
                          child: Column(
                            children: [
                              _originalLocked != null
                                  ? InfoItemRow(dic['lock.vest.original'],
                                      '${Fmt.priceFloorBigInt(_originalLocked, decimals)}')
                                  : Container(),
                              InfoItemRow(dic['lock.vest'],
                                  '${Fmt.priceFloorBigInt(amt, decimals)}'),
                              InfoItemRow(dic['lock.vest.unlocking'],
                                  Fmt.priceFloorBigInt(_unlocking, decimals)),
                              _originalLocked != null
                                  ? InfoItemRow(dic['lock.vest.claimed'],
                                      '${Fmt.priceFloorBigInt(_originalLocked - amt, decimals)}')
                                  : Container(),
                              InfoItemRow(
                                dic['lock.vest.claimable'],
                                claimableAmount,
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    .copyWith(fontSize: 18),
                                contentStyle: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    .copyWith(
                                        fontSize: 18,
                                        color: Color(0xFFE46B41),
                                        fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                          hasClaim: hasClaim,
                          onRedeem: () =>
                              _claimVest(claimableAmount, decimals, symbol));
                    } else if (Democracchild != null) {
                      return buildItem(
                          title: 'Locked',
                          child: Democracchild,
                          hasClaim: maxUnlockAmount - maxLockAmount > 0,
                          onRedeem: () => _onUnlock(unLockIds));
                    } else {
                      return buildItem(
                          title: 'Locked',
                          child: InfoItemRow(dic['lock.${e.use.trim()}'],
                              Fmt.priceFloorBigInt(amt, decimals)),
                          hasClaim: false,
                          onRedeem: null);
                    }
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(
      {@required String title,
      @required Widget child,
      @required bool hasClaim,
      @required Function onRedeem}) {
    return Container(
        padding: EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BorderedTitle(
              title: title,
            ),
            Padding(
                padding: EdgeInsets.only(top: 2),
                child: InnerShadowBGCar(child: child)),
            hasClaim
                ? Container(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                            onTap: () => onRedeem(),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 4),
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                image: DecorationImage(
                                    image: AssetImage(
                                        "assets/images/icon_bg_2.png"),
                                    fit: BoxFit.fill),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                I18n.of(context).getDic(i18n_full_dic_app,
                                    'assets')['lock.vest.claim'],
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                  fontSize: 12,
                                  fontFamily: 'TitilliumWeb',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                      ],
                    ))
                : Container()
          ],
        ));
  }
}
