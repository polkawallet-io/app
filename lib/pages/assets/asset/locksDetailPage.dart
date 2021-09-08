import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';

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

  bool _submitting = false;

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

  Future<void> _updateVestingInfo() async {
    _queryDemocracyUnlocks();

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
      final vestLeft = BigInt.parse(
          widget.service.plugin.balances.native.lockedBalance.toString());
      final unlockingPeriod = endBlock - blockNow > BigInt.zero
          ? (endBlock - blockNow) ~/ periodBlocks + BigInt.one
          : BigInt.zero;
      final unlocking = unlockingPeriod * perPeriod;
      setState(() {
        _claimable = vestLeft - unlocking;
        _unlocking = unlocking;
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
      params: [],
    );
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
      appBar:
          AppBar(title: Text('${dic['locked']} ($symbol)'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _updateVestingInfo,
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: locks.map((e) {
                    final amt = BigInt.parse(e.amount.toString());
                    return RoundedCard(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      child: e.use.contains('ormlvest')
                          ? Column(
                              children: [
                                InfoItemRow(dic['lock.vest'],
                                    '${Fmt.priceFloorBigInt(amt, decimals)}'),
                                InfoItemRow(dic['lock.vest.unlocking'],
                                    Fmt.priceFloorBigInt(_unlocking, decimals)),
                                Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                        child: InfoItemRow(
                                            dic['lock.vest.claimable'],
                                            claimableAmount)),
                                    OutlinedButtonSmall(
                                        margin: EdgeInsets.only(left: 8),
                                        content: dic['lock.vest.claim'],
                                        active: hasClaim,
                                        color: hasClaim
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(context)
                                                .unselectedWidgetColor,
                                        onPressed: hasClaim
                                            ? () => _claimVest(claimableAmount,
                                                decimals, symbol)
                                            : null)
                                  ],
                                ),
                              ],
                            )
                          : e.use.contains('democrac')
                              ? Column(
                                  children: [
                                    InfoItemRow(dic['lock.${e.use.trim()}'],
                                        Fmt.priceFloorBigInt(amt, decimals)),
                                    Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButtonSmall(
                                            margin: EdgeInsets.only(left: 8),
                                            content: dic['lock.unlock'],
                                            active: true,
                                            onPressed: _onUnlock)
                                      ],
                                    )
                                  ],
                                )
                              : InfoItemRow(dic['lock.${e.use.trim()}'],
                                  Fmt.priceFloorBigInt(amt, decimals)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
