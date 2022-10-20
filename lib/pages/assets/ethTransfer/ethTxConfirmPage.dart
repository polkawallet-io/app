import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
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

  bool _isAcala() {
    return widget.service.pluginEvm.basic.name.contains('acala') ||
        widget.service.pluginEvm.basic.name.contains('karura');
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

    final gasLimit = await widget.service.plugin.sdk.api.eth.keyring
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
          gasLimit: gasLimit, gasPrice: Fmt.balanceDouble(gasPrice, 9));
      _gasOptions = {
        'gasLimit': gasLimit,
        'gasPrice': gasPrice,
      };
    } else {
      /// in ethereum we use dynamic gas estimate
      gasParams = await widget.service.plugin.sdk.api.eth.account
          .queryEthGasParams(gasLimit: gasLimit);
      _gasOptions = {
        'gasLimit': gasLimit,
        'gasPrice': Fmt.tokenInt(gasParams.gasPrice.toString(), 9).toString(),
        'maxFeePerGas': Fmt.tokenInt(
                gasParams.estimatedFee[EstimatedFeeLevel.medium].maxFeePerGas
                    .toString(),
                9)
            .toString(),
        'maxPriorityFeePerGas': Fmt.tokenInt(
                gasParams
                    .estimatedFee[EstimatedFeeLevel.medium].maxPriorityFeePerGas
                    .toString(),
                9)
            .toString(),
      };
    }

    setState(() {
      _fee = gasParams;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _getTxFee();

      final EthTransferConfirmPageParams args =
          ModalRoute.of(context).settings.arguments;
      _updateAccountTo(args.addressTo);
    });
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

    BigInt gasFee = BigInt.zero;
    if (_fee != null) {
      gasFee = BigInt.from(_fee.gasLimit * _fee.gasPrice * 1000000000);
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
                    RoundedCard(
                      margin: EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(dic['amount.fee'],
                                        style: labelStyle?.copyWith(
                                            fontWeight: FontWeight.w400)),
                                  ),
                                ),
                                Text(
                                    '${Fmt.priceCeilBigInt(gasFee, 18, lengthMax: 6)} $nativeToken',
                                    style: infoValueStyle),
                              ],
                            ),
                          ),
                          // Divider(),
                          // Container(
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.end,
                          //     children: [
                          //       Expanded(
                          //         child: Padding(
                          //           padding: const EdgeInsets.only(right: 4),
                          //           child: Text(dic['amount.fee'],
                          //               style: labelStyle?.copyWith(
                          //                   fontWeight: FontWeight.w400)),
                          //         ),
                          //       ),
                          //       Text(
                          //           '${Fmt.priceCeilBigInt(Fmt.balanceInt((_fee?.partialFee?.toString() ?? "0")), decimals, lengthMax: 6)} $symbol',
                          //           style: infoValueStyle),
                          //     ],
                          //   ),
                          // ),
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
                onPressed: connected ? _onSubmit : () => null,
              ),
            )
          ],
        ),
      ),
    );
  }
}
