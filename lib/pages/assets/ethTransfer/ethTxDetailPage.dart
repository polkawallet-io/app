import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/common/constants.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/evmTxData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/txDetail.dart';
import 'package:polkawallet_ui/utils/format.dart';

class EthTxDetailPage extends StatelessWidget {
  const EthTxDetailPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/assets/token/tx';

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final plugin = service.plugin as PluginEvm;
        final Map<String, String> dic =
            I18n.of(context).getDic(i18n_full_dic_app, 'assets');

        final EvmTxData argsTx =
            ModalRoute.of(context).settings.arguments as EvmTxData;
        final pendingTx =
            service.store.assets.pendingTx[service.keyringEVM.current.address];
        final tx = pendingTx != null && pendingTx.hash == argsTx.hash
            ? pendingTx
            : argsTx;

        final String txType = tx.from == service.keyringEVM.current.address
            ? dic['transfer']
            : dic['receive'];

        return TxDetail(
          current: service.keyringEVM.current.toKeyPairData(),
          success: tx.isError != null ? tx.isError == '0' : true,
          confirmations: int.parse(tx.confirmations),
          action: txType,
          scanName: block_explorer_url[plugin.network]['name'],
          scanLink:
              "${block_explorer_url[plugin.network]['url']}/tx/${tx.hash}",
          blockNum: tx.blockNumber != null ? int.parse(tx.blockNumber) : null,
          hash: tx.hash,
          blockTime: Fmt.dateTime(tx.timeStamp != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(tx.timeStamp) * 1000,
                  isUtc: true)
              : DateTime.now()),
          networkName: plugin.basic.name,
          infoItems: <TxDetailInfoItem>[
            TxDetailInfoItem(
              label: dic['amount'],
              content: Text(
                '${tx.from == service.keyringEVM.current.address ? '-' : '+'}${Fmt.balance(tx.value, int.tryParse(tx.tokenDecimal ?? "") ?? 12, length: 6)} ${tx.tokenSymbol}',
                style: Theme.of(context).textTheme.headline1,
              ),
            ),
            TxDetailInfoItem(
              label: 'From',
              content: Text(Fmt.address(tx.from)),
              copyText: tx.from,
            ),
            TxDetailInfoItem(
              label: 'To',
              content: Text(Fmt.address(tx.to)),
              copyText: tx.to,
            )
          ],
        );
      });
}
