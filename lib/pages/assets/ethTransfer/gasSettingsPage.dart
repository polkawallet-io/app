import 'dart:async';

import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
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
  EvmGasParams _fee;

  Timer _gasQueryTimer;

  /// [_level]: 0|1|2|3 for fast|medium|slow|custom.
  /// custom(level 3) not supported.
  final levels = [
    EstimatedFeeLevel.low,
    EstimatedFeeLevel.medium,
    EstimatedFeeLevel.high
  ];
  int _level = 1;

  Future<void> _onSet() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    print('on submit');

    Navigator.of(context).pop(_level);
  }

  Future<void> _getTxFee() async {
    final int gasLimit = ModalRoute.of(context).settings.arguments;

    /// in ethereum we use dynamic gas estimate
    final gasParams = await widget.service.plugin.sdk.api.eth.account
        .queryEthGasParams(gasLimit: gasLimit);
    // _gasOptions = {
    //   'gas': gasLimit,
    //   'gasPrice': Fmt.tokenInt(gasParams.gasPrice.toString(), 9).toString(),
    //   'maxFeePerGas': Fmt.tokenInt(
    //       gasParams.estimatedFee[EstimatedFeeLevel.high].maxFeePerGas
    //           .toString(),
    //       9)
    //       .toString(),
    //   'maxPriorityFeePerGas': Fmt.tokenInt(
    //       gasParams
    //           .estimatedFee[EstimatedFeeLevel.high].maxPriorityFeePerGas
    //           .toString(),
    //       9)
    //       .toString(),
    // };

    setState(() {
      _fee = gasParams;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      _gasQueryTimer = Timer(const Duration(seconds: 7), _getTxFee);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _gasQueryTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.service.plugin as PluginEvm;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final nativeToken = widget.service.pluginEvm.nativeToken;

    final available = Fmt.balanceInt(
        (plugin.balances.native?.availableBalance ?? 0).toString());

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.bold);
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

    final gasTokenPrice =
        widget.service.store.assets.marketPrices[nativeToken] ?? 0;
    List<BigInt> gasFee = [BigInt.zero, BigInt.zero];
    if (_fee != null) {
      gasFee = Utils.calcGasFee(_fee, _level);
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
                                gasTokenSymbol: nativeToken,
                                style: subTitleStyle,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: v3.Button(
                title: dicUI['dApp.confirm'],
                onPressed: _onSet,
              ),
            )
          ],
        ),
      ),
    );
  }
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
