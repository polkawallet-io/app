import 'package:app/service/index.dart';
import 'package:app/store/types/transferData.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class TransferDetailPage extends StatelessWidget {
  TransferDetailPage(this.service);

  static final String route = '/assets/tx';
  final AppService service;

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final symbol = (service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals = (service.plugin.networkState.tokenDecimals ?? [12])[0];

    final TransferData tx = ModalRoute.of(context).settings.arguments;
    final amount = Fmt.priceFloor(double.parse(tx.amount), lengthMax: 4);

    final String txType = tx.from == service.keyring.current.address
        ? dic['transfer']
        : dic['receive'];

    String networkName = service.plugin.basic.name;
    if (service.plugin.basic.isTestNet) {
      networkName = '${networkName.split('-')[0]}-testnet';
    }
    return TxDetail(
      current: service.keyring.current,
      success: tx.success,
      action: txType,
      fee: '${Fmt.balance(tx.fee, decimals)} $symbol',
      eventId: tx.extrinsicIndex,
      hash: tx.hash,
      blockTime: Fmt.dateTime(
          DateTime.fromMillisecondsSinceEpoch(tx.blockTimestamp * 1000)),
      blockNum: tx.blockNum,
      networkName: networkName,
      infoItems: <TxDetailInfoItem>[
        TxDetailInfoItem(
          label: dic['amount'],
          content: Text(
              '${txType == dic['transfer'] ? "-" : ""}$amount $symbol',
              style: Theme.of(context).textTheme.headline1),
        ),
        TxDetailInfoItem(
          label: dic['from'],
          content: Text(Fmt.address(tx.from),
              style: Theme.of(context).textTheme.headline4),
          copyText: tx.from,
        ),
        TxDetailInfoItem(
          label: dic['to'],
          content: Text(Fmt.address(tx.to),
              style: Theme.of(context).textTheme.headline4),
          copyText: tx.to,
        )
      ],
    );
  }
}
