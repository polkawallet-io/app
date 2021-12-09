import 'dart:convert';

import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/txData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDetailPage extends StatelessWidget {
  TxDetailPage(this.service);
  static final String route = '/profile/tx/detail';
  final AppService service;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    final isKSMOrDOT = service.plugin.basic.name == 'kusama' ||
        service.plugin.basic.name == 'polkadot';
    final symbol = isKSMOrDOT
        ? service.plugin.networkState.tokenSymbol[0]
        : service.plugin.networkState.tokenSymbol ?? '';
    final decimals = isKSMOrDOT
        ? service.plugin.networkState.tokenDecimals[0]
        : service.plugin.networkState.tokenDecimals ?? 12;
    final TxData detail = ModalRoute.of(context).settings.arguments;
    List<TxDetailInfoItem> info = <TxDetailInfoItem>[
      TxDetailInfoItem(label: dic['tx.action'], content: Text(detail.call)),
    ];
    List params = jsonDecode(detail.params);
    info.addAll(params.map((i) {
      String value = i['value'].toString();
      switch (i['type']) {
        case "Address":
          value = Fmt.address(value);
          break;
        case "Compact<BalanceOf>":
          value = '${Fmt.balance(value, decimals)} $symbol';
          break;
        case "AccountId":
          value = value.contains('0x') ? value : '0x$value';
          String address = service.store.account
                  .pubKeyAddressMap[service.plugin.sdk.api.connectedNode.ss58]
              [value];
          value = Fmt.address(address);
          break;
      }
      return TxDetailInfoItem(
        label: i['name'],
        content: Text(value, style: Theme.of(context).textTheme.headline4),
      );
    }));
    return TxDetail(
      current: service.keyring.current,
      networkName: service.plugin.basic.isTestNet
          ? '${service.plugin.basic.name}-testnet'
          : service.plugin.basic.name,
      success: detail.success,
      action: detail.call,
      fee: '${Fmt.balance(detail.fee, decimals)} $symbol',
      hash: detail.hash,
      eventId: detail.txNumber,
      infoItems: info,
      blockTime: Fmt.dateTime(
          DateTime.fromMillisecondsSinceEpoch(detail.blockTimestamp * 1000)),
      blockNum: detail.blockNum,
    );
  }
}
