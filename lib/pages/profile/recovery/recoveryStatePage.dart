import 'dart:convert';

import 'package:app/pages/profile/recovery/initiateRecoveryPage.dart';
import 'package:app/pages/profile/recovery/recoverySettingPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/recoveryInfo.dart';
import 'package:polkawallet_sdk/api/types/txData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class RecoveryStatePage extends StatefulWidget {
  RecoveryStatePage(this.service);
  final AppService service;
  static final String route = '/profile/recovery/state';

  @override
  _RecoveryStatePage createState() => _RecoveryStatePage();
}

class _RecoveryStatePage extends State<RecoveryStatePage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final String _actionClaimRecovery = 'claim';
  final String _actionCancelRecovery = 'cancel';

  List<TxData> _txs = [];
  List<RecoveryInfo> _recoverableInfoList = [];
  List _activeRecoveriesStatus = [];
  List _proxyStatus = [];
  int _currentBlock = 0;
  bool _loading = false;

  Future<void> _fetchData() async {
    Map res = await widget.service.subScan.fetchTxsAsync(
      widget.service.subScan.moduleRecovery,
      call: 'initiate_recovery',
      sender: widget.service.keyring.current.address,
    );
    if (res['extrinsics'] == null) return;
    List txs = List.of(res['extrinsics']);
    if (txs.length > 0) {
      List<TxData> ls = txs.map((e) => TxData.fromJson(e)).toList();
      ls.retainWhere((i) => i.success);
      List<String> pubKeys = [];
      ls.toList().forEach((i) {
        String key = '0x${List.of(jsonDecode(i.params))[0]['value']}';
        if (!pubKeys.contains(key)) {
          pubKeys.add(key);
        } else {
          ls.remove(i);
        }
      });
      final pubKeyAddressMap =
          await widget.service.plugin.sdk.api.account.encodeAddress(pubKeys);
      // set pubKeyAddressMap so we can parse the pubKey from subscan tx.
      widget.service.store.account.setPubKeyAddressMap(Map<String, Map>.from(
          {'${widget.service.plugin.basic.ss58}': pubKeyAddressMap}));
      final addresses =
          pubKeys.map((e) => pubKeyAddressMap[e] as String).toList();

      /// fetch active recovery status
      List status = await Future.wait([
        widget.service.plugin.sdk.webView
            .evalJavascript('api.derive.chain.bestNumber()'),
        widget.service.plugin.sdk.api.recovery.queryRecoverableList(addresses),
        widget.service.plugin.sdk.api.recovery.queryActiveRecoveries(
          addresses,
          widget.service.keyring.current.address,
        ),
        widget.service.plugin.sdk.api.recovery
            .queryRecoveryProxies([widget.service.keyring.current.address]),
      ]);

      List<RecoveryInfo> infoList = List.of(status[1]);
      List statusList = List.of(status[2]);

      int invalidCount = 0;
      statusList.toList().asMap().forEach((k, v) {
        // recovery status is null if recovery was closed
        if (v == null) {
          print('remove $k');
          ls.removeAt(k - invalidCount);
          infoList.removeAt(k - invalidCount);
          statusList.removeAt(k - invalidCount);
          invalidCount++;
        }
      });

      setState(() {
        _txs = ls;
        _currentBlock = int.parse(status[0]);
        _recoverableInfoList = infoList;
        _activeRecoveriesStatus = statusList;
        _proxyStatus = status[3];
      });
    }
  }

  Future<void> _onAction(RecoveryInfo info, String action) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final args = TxConfirmParams(
        txTitle: dic['recovery.$action'],
        module: 'recovery',
        call: action == _actionClaimRecovery
            ? 'claimRecovery'
            : 'cancelRecovered',
        txDisplay: {"accountId": info.address},
        params: [info.address]);
    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: args);
    if (res != null) {
      _refreshKey.currentState.show();
    }
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
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    List<List> activeList = <List>[];
    _txs.asMap().forEach((i, v) {
      bool isRecovered =
          _proxyStatus.indexOf(_recoverableInfoList[i].address) >= 0;
      activeList.add([
        v,
        _activeRecoveriesStatus[i],
        _recoverableInfoList[i],
        isRecovered,
      ]);
    });

    final blockDuration = int.parse(
        widget.service.plugin.networkConst['babe']['expectedBlockTime']);

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['recovery.init']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 16),
                child: BorderedTitle(
                  title: dic['recovery.recoveries'],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchData,
                  key: _refreshKey,
                  child: ListView(
                    children: _txs.length > 0
                        ? activeList.map((e) {
                            final int createdBlock = e[1]['created'];
                            final String start = Fmt.blockToTime(
                              _currentBlock - createdBlock,
                              blockDuration,
                            );
                            final RecoveryInfo info = e[2];
                            final bool canClaim =
                                List.of(e[1]['friends']).length >=
                                        info.threshold &&
                                    (createdBlock + info.delayPeriod) <
                                        _currentBlock;
                            bool canCancel = false;
                            if (canClaim && e[3]) {
                              canCancel = true;
                            }
                            final String delay = Fmt.blockToTime(
                                info.delayPeriod, blockDuration);
                            return ActiveRecovery(
                              tx: e[0],
                              status: e[1],
                              info: info,
                              start: start,
                              delay: delay,
                              networkState: widget.service.plugin.networkState,
                              isRescuer: true,
                              proxy: canCancel,
                              action: CupertinoActionSheetAction(
                                child: Text(canCancel
                                    ? dic['recovery.cancel']
                                    : dic['recovery.claim']),
                                onPressed: canClaim
                                    ? () {
                                        Navigator.of(context).pop();
                                        if (canCancel) {
                                          _onAction(
                                              info, _actionCancelRecovery);
                                        } else {
                                          _onAction(info, _actionClaimRecovery);
                                        }
                                      }
                                    : () => {},
                              ),
                            );
                          }).toList()
                        : [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(I18n.of(context).getDic(
                                  i18n_full_dic_ui, 'common')['list.empty']),
                            )
                          ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                  text: dic['recovery.init'],
                  onPressed: () => Navigator.of(context)
                      .pushNamed(InitiateRecoveryPage.route),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
