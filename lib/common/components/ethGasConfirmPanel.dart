import 'package:app/pages/assets/ethTransfer/gasSettingsPage.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EthGasConfirmPanel extends StatelessWidget {
  const EthGasConfirmPanel(
      {Key key,
      this.gasParams,
      this.isGasEditable,
      this.gasLevel,
      this.gasTokenSymbol,
      this.gasTokenPrice,
      this.onTap})
      : super(key: key);

  final EvmGasParams gasParams;
  final bool isGasEditable;
  final int gasLevel;
  final String gasTokenSymbol;
  final double gasTokenPrice;
  final Function onTap;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    List<BigInt> gasFee = [BigInt.zero, BigInt.zero];
    if (gasParams != null) {
      gasFee = isGasEditable
          ? Utils.calcGasFee(gasParams, gasLevel)
          : [
              BigInt.from(gasParams.gasLimit * gasParams.gasPrice * 1000000000),
              BigInt.zero
            ];
    }

    final subTitleStyle = Theme.of(context).textTheme.headline5?.copyWith(
        height: 1,
        fontWeight: FontWeight.w300,
        fontSize: 12,
        color:
            UI.isDarkTheme(context) ? Colors.white : const Color(0xBF565554));
    final infoValueStyle = Theme.of(context)
        .textTheme
        .headline5
        .copyWith(fontWeight: FontWeight.w600);
    return RoundedCard(
        child: gasParams != null
            ? ListTile(
                title: EstimatedGasFeeValue(
                  gasFee: gasFee,
                  gasTokenPrice: gasTokenPrice,
                  style: infoValueStyle,
                ),
                subtitle: EstimatedGasFeeAmount(
                  gasFee: gasFee,
                  gasTokenSymbol: gasTokenSymbol,
                  style: subTitleStyle,
                ),
                trailing: isGasEditable
                    ? Container(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(dic['evm.send.gas.$gasLevel']),
                            const Icon(Icons.arrow_forward_ios, size: 16)
                          ],
                        ),
                      )
                    : Container(width: 8),
                onTap: isGasEditable ? onTap : null,
              )
            : const SizedBox(
                width: double.infinity,
                height: 72,
                child: CupertinoActivityIndicator(),
              ));
  }
}
