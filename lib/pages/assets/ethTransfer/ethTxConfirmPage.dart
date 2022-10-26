import 'dart:async';

import 'package:app/pages/assets/ethTransfer/gasSettingsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EthTransferConfirmPageParams {
  EthTransferConfirmPageParams({
    this.tokenSymbol,
    this.contractAddress,
    this.amount,
    this.addressTo,
  });
  final String tokenSymbol;
  final String contractAddress;
  final double amount;
  final String addressTo;
}

class EthTransferConfirmPage extends StatefulWidget {
  const EthTransferConfirmPage(this.service, {Key key}) : super(key: key);

  static const String route = '/eth/transfer/confirm';
  final AppService service;

  @override
  EthTransferConfirmPageState createState() => EthTransferConfirmPageState();
}

class EthTransferConfirmPageState extends State<EthTransferConfirmPage> {
  EthWalletData _accountTo;
  EvmGasParams _fee;
  Map _gasOptions;
  int _gasLimit = 21000;

  int _gasLevel = 1;

  Timer _gasQueryTimer;

  bool _isAcala() {
    return widget.service.pluginEvm.basic.name.contains('acala') ||
        widget.service.pluginEvm.basic.name.contains('karura');
  }

  bool _gasEditable() {
    return !_isAcala();
  }

  Future<void> _updateAccountTo(String address) async {
    final acc = EthWalletData()..address = address;

    try {
      final plugin = widget.service.plugin as PluginEvm;
      final res = await Future.wait([
        plugin.sdk.api.service.eth.account.getAddress(address),
        plugin.sdk.api.service.eth.account.getAddressIcons([address])
      ]);
      if (res[1] != null) {
        acc.icon = (res[1] as List)[0][1];
      }

      setState(() {
        _accountTo = acc;
      });
    } catch (err) {
      print(err.toString());
    }
  }

  Future<void> _onSubmit() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    print('on submit');

    final EthTransferConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;

    final pass = await widget.service.account
        .getEvmPassword(context, widget.service.keyringEVM.current);

    if (pass == null) return;

    widget.service.plugin.sdk.api.eth.keyring.transfer(
        token: args.contractAddress.isNotEmpty
            ? args.contractAddress
            : args.tokenSymbol,
        amount: args.amount,
        to: args.addressTo,
        sender: widget.service.keyringEVM.current.address,
        pass: pass,
        gasOptions: _gasOptions);

    // // params: [to, amount]
    // final params = [
    //   _accountTo.address,
    //   Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
    // ];
    // return TxConfirmParams(
    //   txTitle: '${dic['transfer']} $symbol',
    //   module: 'balances',
    //   call: 'transfer',
    //   txDisplayBold: {
    //     dic['to']: Row(
    //       children: [
    //         AddressIcon(_accountTo.address, svg: _accountTo.icon),
    //         Expanded(
    //           child: Container(
    //             margin: const EdgeInsets.fromLTRB(8, 16, 0, 16),
    //             child: Text(
    //               Fmt.address(_accountTo.address, pad: 8),
    //               style: Theme.of(context).textTheme.headline4,
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //     dic['amount']: Text(
    //       '${_amountCtrl.text.trim()} $symbol',
    //       style: Theme.of(context).textTheme.headline1,
    //     ),
    //   },
    //   params: params,
    // );
  }

  Future<void> _getTxFee() async {
    final EthTransferConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;

    _gasLimit = await widget.service.plugin.sdk.api.eth.keyring
        .estimateTransferGas(
            token: args.contractAddress.isEmpty
                ? args.tokenSymbol
                : args.contractAddress,
            amount: args.amount,
            to: args.addressTo);
    EvmGasParams gasParams;
    if (_isAcala()) {
      /// in acala/karura we use const gasLimit & gasPrice
      final gasPrice =
          await widget.service.plugin.sdk.api.eth.keyring.getGasPrice();
      gasParams = EvmGasParams(
          gasLimit: _gasLimit, gasPrice: Fmt.balanceDouble(gasPrice, 9));
      _gasOptions = {
        'gas': _gasLimit,
        'gasPrice': gasPrice,
      };
    } else {
      /// in ethereum we use dynamic gas estimate
      gasParams = await widget.service.plugin.sdk.api.eth.account
          .queryEthGasParams(gasLimit: _gasLimit);
      _gasOptions = {
        'gas': gasParams.gasLimit,
        'gasPrice': Fmt.tokenInt(gasParams.gasPrice.toString(), 9).toString(),
        'maxFeePerGas': Fmt.tokenInt(
                gasParams.estimatedFee[EstimatedFeeLevel.high].maxFeePerGas
                    .toString(),
                9)
            .toString(),
        'maxPriorityFeePerGas': Fmt.tokenInt(
                gasParams
                    .estimatedFee[EstimatedFeeLevel.high].maxPriorityFeePerGas
                    .toString(),
                9)
            .toString(),
      };
    }

    setState(() {
      _fee = gasParams;
    });
  }

  Future<void> _onSetGas() async {
    final gasLevel = await Navigator.of(context)
        .pushNamed(GasSettingsPage.route, arguments: _fee?.gasLimit);
    if (gasLevel != null && gasLevel != _gasLevel) {
      setState(() {
        _gasLevel = gasLevel;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      final EthTransferConfirmPageParams args =
          ModalRoute.of(context).settings.arguments;
      _updateAccountTo(args.addressTo);

      if (_gasEditable()) {
        _gasQueryTimer = Timer(const Duration(seconds: 7), _getTxFee);
      }
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
    final EthTransferConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;

    final connected = plugin.sdk.api.connectedNode != null;

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
    print(gasTokenPrice);
    List<BigInt> gasFee = [BigInt.zero, BigInt.zero];
    if (_fee != null) {
      gasFee = _gasEditable()
          ? Utils.calcGasFee(_fee, _gasLevel)
          : [
              BigInt.from(_fee.gasLimit * _fee.gasPrice * 1000000000),
              BigInt.zero
            ];
    }

    String gasValue =
        '\$${Fmt.priceFloor(Fmt.bigIntToDouble(gasFee[0], 18) * gasTokenPrice, lengthMax: 2)}';
    String gasAmount =
        '${Fmt.priceCeilBigInt(gasFee[0], 18, lengthFixed: 6)} $nativeToken';
    if (_fee != null && _gasEditable()) {
      gasValue =
          '$gasValue ~ \$${Fmt.priceFloor(Fmt.bigIntToDouble(gasFee[1], 18) * gasTokenPrice, lengthMax: 2)}';
      gasAmount =
          '$gasAmount ~ ${Fmt.priceCeilBigInt(gasFee[1], 18, lengthFixed: 6)} $nativeToken';
    }

    return Scaffold(
      appBar: AppBar(
          systemOverlayStyle: UI.isDarkTheme(context)
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          title: Text(dic['evm.send.2'] ?? ''),
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
                    Text(dic['from'], style: labelStyle),
                    Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 8),
                        child:
                            AddressFormItem(widget.service.keyringEVM.current)),
                    Text(dic['to'], style: labelStyle),
                    Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _accountTo != null
                            ? AddressFormItem(_accountTo)
                            : Container()),
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(dic['amount'], style: labelStyle),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 16),
                      height: 88,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/public/flex_text_form_field_bg.png'),
                              fit: BoxFit.fill)),
                      child: Row(
                        children: [
                          Text(
                            args.amount.toStringAsFixed(4),
                            style: Theme.of(context)
                                .textTheme
                                .headline1
                                .copyWith(fontSize: 40),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 8),
                            child: Text(args.tokenSymbol),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(dic['amount.fee'], style: labelStyle),
                    ),
                    RoundedCard(
                        child: _fee != null
                            ? ListTile(
                                title: EstimatedGasFeeValue(
                                  gasFee: gasFee,
                                  gasTokenPrice: gasTokenPrice,
                                  style: infoValueStyle,
                                ),
                                subtitle: EstimatedGasFeeAmount(
                                  gasFee: gasFee,
                                  gasTokenSymbol: nativeToken,
                                  style: subTitleStyle,
                                ),
                                trailing: Container(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(dic['evm.send.gas.$_gasLevel']),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      )
                                    ],
                                  ),
                                ),
                                onTap: _gasEditable() ? _onSetGas : null,
                              )
                            : const SizedBox(
                                width: double.infinity,
                                height: 72,
                                child: CupertinoActivityIndicator(),
                              )),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: v3.Button(
                title: dicUI['dApp.confirm'],
                onPressed: connected ? _onSubmit : () => null,
              ),
            )
          ],
        ),
      ),
    );
  }
}
