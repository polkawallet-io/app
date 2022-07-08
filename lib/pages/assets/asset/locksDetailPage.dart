import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/types/balanceData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/innerShadow.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginAccountInfoAction.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

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
    final res = await Future.wait([
      WalletApi.fetchBlocksFromSn(
          widget.service.plugin.basic.name == para_chain_name_karura
              ? relay_chain_name_ksm
              : relay_chain_name_dot),
      widget.service.plugin.sdk.webView.evalJavascript(
          'api.query.vesting.vestingSchedules("${widget.service.keyring.current.address}")')
    ]);
    if (res[0] != null && res[1] != null) {
      final blockNow = BigInt.from(res[0]['count']);
      BigInt vestOriginal = BigInt.zero;
      BigInt unlocking = BigInt.zero;

      List.from(res[1]).forEach((e) {
        final periodBlocks = BigInt.parse(e['period'].toString());
        final periodCount = BigInt.parse(e['periodCount'].toString());
        final perPeriod = BigInt.parse(e['perPeriod'].toString());
        final startBlock = BigInt.parse(e['start'].toString());

        final endBlock = startBlock + periodCount * periodBlocks;

        final blockNowOrStart = startBlock > blockNow ? startBlock : blockNow;
        final unlockingPeriod = endBlock - blockNowOrStart > BigInt.zero
            ? (endBlock - blockNowOrStart) ~/ periodBlocks +
                (startBlock > blockNow ? BigInt.zero : BigInt.one)
            : BigInt.zero;

        vestOriginal += perPeriod * periodCount;
        unlocking += unlockingPeriod * perPeriod;
      });
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

      if (mounted) {
        setState(() {
          _claimable = vestLeft - unlocking;
          _unlocking = unlocking;
          _originalLocked = vestOriginal;
        });
      }
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
      // _refreshUnlockDatas();
      _refreshKey.currentState.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final decimals = widget.service.plugin.networkState.tokenDecimals[0];
    final symbol = widget.service.plugin.networkState.tokenSymbol[0];

    final l = widget.service.plugin.balances.native.lockedBreakdown.toList();
    l.retainWhere((e) => BigInt.parse(e.amount.toString()) > BigInt.zero);
    final locks =
        l.where((element) => element.use.contains('ormlvest')).toList();
    locks.addAll(
        l.where((element) => element.use.contains('democrac')).toList());
    l.retainWhere(
        (e) => !e.use.contains('ormlvest') && !e.use.contains('democrac'));
    if (l.length > 0) {
      locks.add(BalanceBreakdownData.fromJson({"amount": 0, "use": ""}));
    }

    final hasClaim =
        _claimable != null && _claimable > BigInt.zero && !_submitting;
    final claimableAmount = Fmt.priceFloorBigInt(_claimable, decimals);
    return Scaffold(
      appBar: AppBar(
        title: Text('${dic['unlock']} ($symbol)'),
        centerTitle: true,
        leading: BackBtn(),
        actions: [
          PluginAccountInfoAction(
            widget.service.keyring,
            iconDefaultColor: Color(0xFFE4E4E3),
            hasShadow: true,
            iconSize: 30.h,
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refreshUnlockDatas,
                child: locks.length == 0
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          I18n.of(context)
                              .getDic(i18n_full_dic_ui, 'common')['list.empty'],
                          style: TextStyle(color: Colors.black),
                        ),
                      )
                    : ListView(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.all(16),
                        children: locks.map((e) {
                          final amt = BigInt.parse(e.amount.toString());
                          Widget Democracchild;
                          final List<String> unLockIds = [];
                          double maxLockAmount = 0, maxUnlockAmount = 0;
                          if (e.use.contains('democrac') && _locks.length > 0) {
                            for (int index = 0;
                                index < _locks.length;
                                index++) {
                              var unlockAt = _locks[index]['unlockAt'];
                              final amount = Fmt.balanceDouble(
                                _locks[index]['balance'].toString(),
                                decimals,
                              );
                              if (unlockAt != "0") {
                                BigInt endLeft;
                                try {
                                  endLeft =
                                      BigInt.parse("${unlockAt.toString()}") -
                                          BigInt.from(bestNumber);
                                } catch (e) {
                                  endLeft =
                                      BigInt.parse("0x${unlockAt.toString()}") -
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
                                InfoItemRow(dic['lock.vest.unlocking'],
                                    "$maxLockAmount"),
                                maxUnlockAmount - maxLockAmount > 0
                                    ? InfoItemRow(
                                        dic['lock.vest.claimable'],
                                        "${maxUnlockAmount - maxLockAmount}",
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            .copyWith(
                                                fontSize: UI.getTextSize(
                                                    18, context)),
                                        contentStyle: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            .copyWith(
                                                fontSize:
                                                    UI.getTextSize(18, context),
                                                color: Theme.of(context)
                                                    .errorColor,
                                                fontWeight: FontWeight.w600),
                                      )
                                    : Container(),
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
                                            '${Fmt.priceFloorBigInt(_originalLocked, decimals, lengthMax: 4)}')
                                        : Container(),
                                    InfoItemRow(dic['lock.vest'],
                                        '${Fmt.priceFloorBigInt(amt, decimals, lengthMax: 4)}'),
                                    InfoItemRow(
                                        dic['lock.vest.unlocking'],
                                        Fmt.priceFloorBigInt(
                                            _unlocking, decimals,
                                            lengthMax: 4)),
                                    _originalLocked != null
                                        ? InfoItemRow(dic['lock.vest.claimed'],
                                            '${Fmt.priceFloorBigInt(_originalLocked - amt, decimals, lengthMax: 4)}')
                                        : Container(),
                                    hasClaim
                                        ? InfoItemRow(
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
                                                    fontSize: UI.getTextSize(
                                                        18, context),
                                                    color: Theme.of(context)
                                                        .errorColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          )
                                        : Container()
                                  ],
                                ),
                                hasClaim: hasClaim,
                                onRedeem: () => _claimVest(
                                    claimableAmount, decimals, symbol));
                          } else if (Democracchild != null) {
                            return buildItem(
                                title: 'Democracy',
                                child: Democracchild,
                                hasClaim: maxUnlockAmount - maxLockAmount > 0,
                                onRedeem: () => _onUnlock(unLockIds));
                          } else if (e.use.length == 0) {
                            return buildItem(
                                title: 'Others',
                                child: Column(
                                  children: [
                                    ...l
                                        .map((e) => InfoItemRow(
                                            dic['lock.${e.use.trim()}'],
                                            Fmt.priceFloorBigInt(
                                                BigInt.parse(
                                                    e.amount.toString()),
                                                decimals,
                                                lengthMax: 4)))
                                        .toList()
                                  ],
                                ),
                                hasClaim: false,
                                onRedeem: null);
                          } else {
                            return Container();
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
                              padding: EdgeInsets.fromLTRB(17.w, 0, 17.w, 4),
                              height: 28,
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
                                  fontSize: UI.getTextSize(12, context),
                                  fontFamily:
                                      UI.getFontFamily('TitilliumWeb', context),
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
