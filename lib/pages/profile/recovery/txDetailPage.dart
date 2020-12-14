import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_kusama/polkawallet_plugin_kusama.dart';
import 'package:polkawallet_plugin_kusama/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/txData.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TxDetailPage extends StatelessWidget {
  TxDetailPage(this.plugin, this.keyring);
  static final String route = '/staking/tx';
  final PluginKusama plugin;
  final Keyring keyring;

  @override
  Widget build(BuildContext context) {
    final dicStaking = I18n.of(context).getDic(i18n_full_dic_kusama, 'staking');
    final decimals = plugin.networkState.tokenDecimals;
    final TxData detail = ModalRoute.of(context).settings.arguments;
    List<TxDetailInfoItem> info = <TxDetailInfoItem>[
      TxDetailInfoItem(label: dicStaking['action'], title: detail.call),
    ];
    List params = jsonDecode(detail.params);
    info.addAll(params.map((i) {
      String value = i['value'].toString();
      switch (i['type']) {
        case "Address":
          value = Fmt.address(value);
          break;
        case "Compact<BalanceOf>":
          final symbol = plugin.networkState.tokenSymbol;
          value = '${Fmt.balance(value, decimals)} $symbol';
          break;
        case "AccountId":
          value = value.contains('0x') ? value : '0x$value';
          String address = plugin.store.accounts
              .pubKeyAddressMap[plugin.sdk.api.connectedNode.ss58][value];
          value = Fmt.address(address);
          break;
      }
      return TxDetailInfoItem(
        label: i['name'],
        title: value,
      );
    }));
    return TxDetail(
      networkName: plugin.basic.name,
      success: detail.success,
      action: detail.call,
      hash: detail.hash,
      eventId: detail.txNumber,
      infoItems: info,
      blockTime: Fmt.dateTime(
          DateTime.fromMillisecondsSinceEpoch(detail.blockTimestamp * 1000)),
      blockNum: detail.blockNum,
    );
  }
}
