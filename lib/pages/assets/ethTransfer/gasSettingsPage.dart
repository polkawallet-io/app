import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class GasSettingsPage extends StatefulWidget {
  const GasSettingsPage(this.service, {Key key}) : super(key: key);

  static const String route = '/eth/transfer/gas';
  final AppService service;

  @override
  GasSettingsPageState createState() => GasSettingsPageState();
}

class GasSettingsPageState extends State<GasSettingsPage> {
  int _level;

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final plugin = widget.service.plugin as PluginEvm;
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
        final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');

        final int initialLevel = ModalRoute.of(context).settings.arguments;
        final gasLevel = _level ?? initialLevel;

        final labelStyle = Theme.of(context)
            .textTheme
            .headline4
            ?.copyWith(fontWeight: FontWeight.bold);
        final subTitleStyle = Theme.of(context).textTheme.headline5?.copyWith(
            height: 1,
            fontWeight: FontWeight.w300,
            fontSize: 12,
            color: UI.isDarkTheme(context)
                ? Colors.white
                : const Color(0xBF565554));
        final infoValueStyle = Theme.of(context)
            .textTheme
            .headline5
            .copyWith(fontWeight: FontWeight.w600);

        final gasParams = widget.service.store.assets.gasParams;
        final gasTokenPrice =
            widget.service.store.assets.marketPrices[plugin.nativeToken] ?? 0;
        List<BigInt> gasFee = [BigInt.zero, BigInt.zero];
        if (gasParams != null) {
          gasFee = Utils.calcGasFee(gasParams, gasLevel);
        }

        return Scaffold(
          appBar: AppBar(
              systemOverlayStyle: UI.isDarkTheme(context)
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              title: Text(dic['evm.send.gas']),
              centerTitle: true,
              leading: const BackBtn()),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(dic['amount.fee'], style: labelStyle),
                        ),
                        RoundedCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: EstimatedGasFeeValue(
                                      gasFee: gasFee,
                                      gasTokenPrice: gasTokenPrice,
                                      style: infoValueStyle,
                                    ),
                                  ),
                                  EstimatedGasFeeAmount(
                                    gasFee: gasFee,
                                    gasTokenSymbol: plugin.nativeToken,
                                    style: subTitleStyle,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            children: [
                              Text(dic['evm.send.gas.option'],
                                  style: labelStyle),
                              EstimatedGasInfo(gasParams),
                            ],
                          ),
                        ),
                        ...[0, 1, 2].map((level) {
                          final gasFeeAmount = gasParams != null
                              ? Utils.calcGasFee(gasParams, level)
                              : [BigInt.zero, BigInt.zero];
                          return RoundedCard(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                            margin: const EdgeInsets.only(bottom: 12),
                            border: level == gasLevel
                                ? Border.all(
                                    color:
                                        Theme.of(context).toggleableActiveColor)
                                : null,
                            borderWidth: 2,
                            child: ListTile(
                              dense: true,
                              title: EstimatedGasFeeValue(
                                gasFee: gasFeeAmount,
                                gasTokenPrice: gasTokenPrice,
                              ),
                              subtitle: EstimatedGasFeeAmount(
                                gasFee: gasFeeAmount,
                                gasTokenSymbol: plugin.nativeToken,
                              ),
                              trailing: Text(dic['evm.send.gas.$level']),
                              onTap: () {
                                if (level != _level) {
                                  setState(() {
                                    _level = level;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                initialLevel != gasLevel
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: v3.Button(
                          title: dicUI['dApp.confirm'],
                          onPressed: () => Navigator.of(context).pop(_level),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        );
      });
}

class EstimatedGasFeeValue extends StatelessWidget {
  const EstimatedGasFeeValue(
      {Key key, this.gasFee, this.gasTokenPrice, this.style})
      : super(key: key);
  final List<BigInt> gasFee;
  final double gasTokenPrice;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    String gasValue =
        '\$${Fmt.priceFloor(Fmt.bigIntToDouble(gasFee[0], 18) * gasTokenPrice, lengthMax: 2)}';
    if (gasFee[1] > BigInt.zero) {
      gasValue =
          '$gasValue ~ \$${Fmt.priceFloor(Fmt.bigIntToDouble(gasFee[1], 18) * gasTokenPrice, lengthMax: 2)}';
    }
    return Text(gasValue, style: style);
  }
}

class EstimatedGasFeeAmount extends StatelessWidget {
  const EstimatedGasFeeAmount(
      {Key key, this.gasFee, this.gasTokenSymbol, this.style})
      : super(key: key);
  final List<BigInt> gasFee;
  final String gasTokenSymbol;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    String gasAmount =
        '${Fmt.priceCeilBigInt(gasFee[0], 18, lengthFixed: 6)} $gasTokenSymbol';
    if (gasFee[1] > BigInt.zero) {
      gasAmount =
          '$gasAmount ~ ${Fmt.priceCeilBigInt(gasFee[1], 18, lengthFixed: 6)} $gasTokenSymbol';
    }
    return Text(gasAmount, style: style);
  }
}

class EstimatedGasInfo extends StatelessWidget {
  const EstimatedGasInfo(this.gasParams, {Key key}) : super(key: key);
  final EvmGasParams gasParams;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final gasInfo = '\n'
        'EstimatedBaseFee:\n'
        '  -- ${gasParams.estimatedBaseFee.toStringAsFixed(2)} Gwei\n'
        'MaxPriorityFeePerGas:\n'
        '  -- ${dic['evm.send.gas.0']} ${(gasParams.estimatedFee[EstimatedFeeLevel.high].maxPriorityFeePerGas - 0.5).toStringAsFixed(2)} Gwei\n'
        '  -- ${dic['evm.send.gas.1']} ${(gasParams.estimatedFee[EstimatedFeeLevel.medium].maxPriorityFeePerGas - 0.5).toStringAsFixed(2)} Gwei\n'
        '  -- ${dic['evm.send.gas.2']} ${(gasParams.estimatedFee[EstimatedFeeLevel.low].maxPriorityFeePerGas - 0.5).toStringAsFixed(2)} Gwei\n'
        'MaxFeePerGas:\n'
        '  -- ${dic['evm.send.gas.0']} ${gasParams.estimatedFee[EstimatedFeeLevel.high].maxFeePerGas.toStringAsFixed(2)} Gwei\n'
        '  -- ${dic['evm.send.gas.1']} ${gasParams.estimatedFee[EstimatedFeeLevel.medium].maxFeePerGas.toStringAsFixed(2)} Gwei\n'
        '  -- ${dic['evm.send.gas.2']} ${gasParams.estimatedFee[EstimatedFeeLevel.low].maxFeePerGas.toStringAsFixed(2)} Gwei\n';
    return TapTooltip(
      message: gasInfo,
      child: const Icon(Icons.info_outlined, size: 16),
    );
  }
}
