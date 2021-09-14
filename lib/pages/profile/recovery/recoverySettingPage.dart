import 'dart:convert';

import 'package:app/pages/profile/recovery/createRecoveryPage.dart';
import 'package:app/pages/profile/recovery/txDetailPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';
import 'package:polkawallet_sdk/api/types/recoveryInfo.dart';
import 'package:polkawallet_sdk/api/types/txData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/infoItem.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class RecoverySettingPage extends StatefulWidget {
  RecoverySettingPage(this.service);
  static final String route = '/profile/recovery';
  final AppService service;

  @override
  _RecoverySettingPage createState() => _RecoverySettingPage();
}

class _RecoverySettingPage extends State<RecoverySettingPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  List<TxData> _activeRecoveries = [];
  List _activeRecoveriesStatus = [];
  List _proxyStatus = [];
  int _currentBlock = 0;

  Future<void> _fetchData() async {
    /// fetch recovery config
    final config = await widget.service.account
        .queryRecoverable(widget.service.keyring.current.pubKey);
    if (config == null) {
      print('no recoverable config');
      return;
    }

    /// fetch active recoveries from txs
    Map res = await widget.service.subScan.fetchTxsAsync(
      widget.service.subScan.moduleRecovery,
      call: 'initiate_recovery',
      sender: widget.service.keyring.current.address,
    );
    List<TxData> txs = List.of(res['extrinsics'] ?? [])
        .map((e) => TxData.fromJson(e))
        .toList();
    List pubKeys = [];
    txs.retainWhere((e) {
      if (!e.success) return false;
      List params = jsonDecode(e.params);
      String pubKey =
          params[0]['valueRaw'] ?? params[0]['value_raw'] ?? params[0]['value'];
      if (pubKeys.contains(pubKey)) {
        return false;
      } else {
        pubKeys.add(pubKey);
        return '0x$pubKey' == widget.service.keyring.current.pubKey;
      }
    });
    if (txs.length > 0) {
      List<String> addressesNew = txs.map((e) => e.accountId).toList();

      /// fetch active recovery status
      final status = await Future.wait([
        widget.service.plugin.sdk.webView
            .evalJavascript('api.derive.chain.bestNumber()'),
        widget.service.plugin.sdk.api.recovery.queryActiveRecoveryAttempts(
            widget.service.keyring.current.address, addressesNew),
        widget.service.plugin.sdk.api.recovery
            .queryRecoveryProxies(addressesNew),
      ]);
      setState(() {
        _activeRecoveries = txs;
        _currentBlock = status[0];
        _activeRecoveriesStatus = status[1];
        _proxyStatus = status[2];
      });
    }
  }

  Future<void> _onRemoveRecovery() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    List activeList = _activeRecoveriesStatus.toList();
    activeList.retainWhere((e) => e != null);
    bool couldRemove = activeList.length == 0;
    if (!couldRemove) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Container(),
            content: Text(dic['recovery.remove.warn']),
            actions: <Widget>[
              CupertinoButton(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      final args = TxConfirmParams(
        txTitle: dic['recovery.remove'],
        module: 'recovery',
        call: 'removeRecovery',
        txDisplay: {},
        params: [],
      );
      final res = await Navigator.of(context)
          .pushNamed(TxConfirmPage.route, arguments: args);
      if (res != null) {
        _refreshKey.currentState.show();
      }
    }
  }

  Future<void> _closeRecovery(TxData tx) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final args = TxConfirmParams(
      txTitle: dic['recovery.close'],
      module: 'recovery',
      call: 'closeRecovery',
      txDisplay: {"rescuer": tx.accountId},
      params: [tx.accountId],
    );
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
    return Scaffold(
      appBar: AppBar(title: Text(dic['recovery']), centerTitle: true),
      body: SafeArea(
        child: Observer(
          builder: (_) {
            final isKSMOrDOT = widget.service.plugin.basic.name == 'kusama' ||
                widget.service.plugin.basic.name == 'polkadot';
            final symbol = isKSMOrDOT
                ? widget.service.plugin.networkState.tokenSymbol[0]
                : widget.service.plugin.networkState.tokenSymbol ?? '';
            final decimals = isKSMOrDOT
                ? widget.service.plugin.networkState.tokenDecimals[0]
                : widget.service.plugin.networkState.tokenDecimals ?? 12;

            final info = widget.service.store.account.recoveryInfo;
            final friends = <KeyPairData>[];
            if (info.friends != null) {
              friends.addAll(info.friends.map((e) {
                int friendIndex = widget.service.keyring.contacts
                    .indexWhere((c) => c.address == e);
                if (friendIndex >= 0) {
                  return widget.service.keyring.contacts[friendIndex];
                }
                final res = KeyPairData();
                res.address = e;
                return res;
              }));
            }
            List<List> activeList = <List>[];
            _activeRecoveries.asMap().forEach((i, v) {
              // status is null if recovery process was closed
              if (_activeRecoveriesStatus[i] != null) {
                activeList
                    .add([v, _activeRecoveriesStatus[i], _proxyStatus[i]]);
              }
            });

            final blockDuration = int.parse(widget
                .service.plugin.networkConst['babe']['expectedBlockTime']);
            final String delay =
                Fmt.blockToTime(info.delayPeriod, blockDuration);
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    key: _refreshKey,
                    onRefresh: _fetchData,
                    child: ListView(
                      children: [
                        RoundedCard(
                          margin: EdgeInsets.all(16),
                          padding: EdgeInsets.all(16),
                          child: friends.length == 0
                              ? Text(dic['recovery.brief'])
                              : _RecoveryInfo(
                                  recoveryInfo: info,
                                  friends: friends,
                                  decimals: decimals,
                                  symbol: symbol,
                                  delay: delay,
                                  onRemove: _onRemoveRecovery,
                                ),
                        ),
                        friends.length > 0
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(16, 8, 0, 16),
                                child: BorderedTitle(
                                  title: dic['recovery.process'],
                                ),
                              )
                            : Container(),
                        friends.length > 0
                            ? Column(
                                children: activeList.length > 0
                                    ? activeList.map((e) {
                                        String start = Fmt.blockToTime(
                                            _currentBlock - e[1]['created'],
                                            blockDuration);
                                        TxData tx = e[0];
                                        bool hasProxy = false;
                                        if (e[2] != null) {
                                          hasProxy = e[2] == info.address;
                                        }
                                        return ActiveRecovery(
                                          tx: tx,
                                          status: e[1],
                                          info: info,
                                          start: start,
                                          delay: delay,
                                          proxy: hasProxy,
                                          networkState: widget
                                              .service.plugin.networkState,
                                          action: CupertinoActionSheetAction(
                                            child: Text(dic['recovery.close']),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _closeRecovery(tx);
                                            },
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(I18n.of(context).getDic(
                                              i18n_full_dic_ui,
                                              'common')['list.empty']),
                                        )
                                      ],
                              )
                            : Container()
                      ],
                    ),
                  ),
                ),
                info.friends == null
                    ? Padding(
                        padding: EdgeInsets.all(16),
                        child: RoundedButton(
                          text: dic['recovery.create'],
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              CreateRecoveryPage.route,
                              arguments: friends,
                            );
                          },
                        ),
                      )
                    : Container(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecoveryInfo extends StatelessWidget {
  _RecoveryInfo({
    this.friends,
    this.recoveryInfo,
    this.decimals,
    this.symbol,
    this.delay,
    this.onRemove,
  });

  final RecoveryInfo recoveryInfo;
  final List<KeyPairData> friends;
  final int decimals;
  final String symbol;
  final String delay;
  final Function onRemove;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    TextStyle titleStyle = TextStyle(fontSize: 16);
    TextStyle valueStyle = Theme.of(context).textTheme.headline4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(dic['recovery.friends'], style: titleStyle),
        ),
        RecoveryFriendList(friends: friends),
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dic['recovery.threshold'], style: titleStyle),
              Text(
                '${recoveryInfo.threshold} / ${friends.length}',
                style: valueStyle,
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dic['recovery.delay'], style: titleStyle),
              Text(
                delay,
                style: valueStyle,
              )
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dic['recovery.deposit'], style: titleStyle),
            Text(
              '${Fmt.token(recoveryInfo.deposit, decimals)} $symbol',
              style: valueStyle,
            )
          ],
        ),
        Divider(height: 32),
        RoundedButton(
          color: Colors.orange,
          text: dic['recovery.remove'],
          onPressed: () => onRemove(),
        ),
      ],
    );
  }
}

class RecoveryFriendList extends StatelessWidget {
  RecoveryFriendList({this.friends});

  final List<KeyPairData> friends;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: friends.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                margin: EdgeInsets.only(right: 8),
                child: AddressIcon(e.address, svg: e.icon, size: 32),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  e.name != null && e.name.isNotEmpty
                      ? Text(e.name)
                      : Container(),
                  Text(
                    Fmt.address(e.address),
                    style: TextStyle(
                      color: Theme.of(context).unselectedWidgetColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ActiveRecovery extends StatelessWidget {
  ActiveRecovery({
    this.tx,
    this.status,
    this.info,
    this.start,
    this.delay,
    this.action,
    this.isRescuer = false,
    this.proxy = false,
    this.networkState,
  });

  final TxData tx;
  final Map status;
  final RecoveryInfo info;
  final String start;
  final String delay;
  final Widget action;
  final bool isRescuer;
  final bool proxy;
  final NetworkStateData networkState;

  void _showActions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          action,
          CupertinoActionSheetAction(
            child: Text(
                I18n.of(context).getDic(i18n_full_dic_app, 'assets')['detail']),
            onPressed: () => Navigator.of(context)
                .popAndPushNamed(TxDetailPage.route, arguments: tx),
          )
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
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    String frindsVouched =
        List.of(status['friends']).map((e) => Fmt.address(e)).join('\n');
    return RoundedCard(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isRescuer
                      ? proxy
                          ? dic['recovery.recovered']
                          : dic['recovery.init.old']
                      : proxy
                          ? dic['recovery.proxy']
                          : dic['recovery.init.new']),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          Fmt.address(isRescuer ? info.address : tx.accountId),
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      !isRescuer
                          ? TapTooltip(
                              child: Icon(
                                Icons.info,
                                color: Theme.of(context).disabledColor,
                                size: 16,
                              ),
                              message: dic['recovery.close.info'],
                            )
                          : Container()
                    ],
                  )
                ],
              ),
              OutlinedButtonSmall(
                content: dic['recovery.actions'],
                active: true,
                onPressed: () => _showActions(context),
              )
            ],
          ),
          Container(height: 16),
          Row(
            children: [
              InfoItem(
                title: dic['recovery.deposit'],
                content:
                    '${Fmt.balance(status['deposit'].toString(), networkState.tokenDecimals[0])} ${networkState.tokenSymbol[0]}',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dic['recovery.process']),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(
                            '${List.of(status['friends']).length} / ${info.threshold}',
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ),
                        TapTooltip(
                          child: Icon(
                            Icons.info,
                            color: Theme.of(context).disabledColor,
                            size: 16,
                          ),
                          message:
                              '\n${dic['recovery.friends.vouched']}\n$frindsVouched\n',
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(height: 16),
          Row(
            children: [
              InfoItem(
                title: dic['recovery.delay'],
                content: delay,
              ),
              InfoItem(
                title: dic['recovery.time.start'],
                content: start,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
