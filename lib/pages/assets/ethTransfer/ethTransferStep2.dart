import 'package:app/common/components/flexTextFormField.dart';
import 'package:app/pages/assets/ethTransfer/ethTransferStep1.dart';
import 'package:app/pages/assets/ethTransfer/ethTxConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/eth/apiAccountEth.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EthTransferStep2 extends StatefulWidget {
  const EthTransferStep2(this.service, {Key key}) : super(key: key);

  static const String route = '/eth/assets/transfer/2';
  final AppService service;

  @override
  EthTransferStep2State createState() => EthTransferStep2State();
}

class EthTransferStep2State extends State<EthTransferStep2> {
  final TextEditingController _amountCtrl = TextEditingController();

  String _amountError;

  EvmGasParams _fee;

  bool _isAcala() {
    return widget.service.pluginEvm.basic.name.contains('acala') ||
        widget.service.pluginEvm.basic.name.contains('karura');
  }

  Future<void> _getTxFee() async {
    final EthTransferPageParams args =
        ModalRoute.of(context).settings.arguments;

    final gasLimit = await widget.service.plugin.sdk.api.eth.keyring
        .estimateTransferGas(
            token: args.token.id ?? args.token.symbol,
            amount: 1,
            to: args.address);
    EvmGasParams gasParams;
    if (_isAcala()) {
      /// in acala/karura we use const gasLimit & gasPrice
      final gasPrice =
          await widget.service.plugin.sdk.api.eth.keyring.getGasPrice();
      gasParams = EvmGasParams(
          gasLimit: gasLimit, gasPrice: Fmt.balanceDouble(gasPrice, 9));
    } else {
      /// in ethereum we use dynamic gas estimate
      gasParams = await widget.service.plugin.sdk.api.eth.account
          .queryEthGasParams(gasLimit: gasLimit);
    }

    setState(() {
      _fee = gasParams;
    });
  }

  Future<void> _onSubmit() async {
    if (_amountError != null) return;

    final EthTransferPageParams args =
        ModalRoute.of(context).settings.arguments;
    final params = EthTransferConfirmPageParams(
        tokenSymbol: args.token.symbol,
        contractAddress:
            (args.token.id ?? '').startsWith('0x') ? args.token.id : '',
        addressTo: args.address,
        amount: double.tryParse(_amountCtrl.text.trim()) ?? '0');
    final res = await Navigator.of(context)
        .pushNamed(EthTransferConfirmPage.route, arguments: params);
    print('eth transfer sending ============================');
    print(res);
  }

  BigInt _getExistAmount(BigInt notTransferable, BigInt existentialDeposit) {
    return notTransferable > BigInt.zero
        ? notTransferable >= existentialDeposit
            ? BigInt.zero
            : existentialDeposit - notTransferable
        : existentialDeposit;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.service.plugin as PluginEvm;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final EthTransferPageParams args =
        ModalRoute.of(context).settings.arguments;
    final isERC20 = args.token.id?.startsWith('0x') == true;
    final symbol = args?.token?.symbol ?? 'ACA';
    final decimals = args?.token?.decimals ?? 18;

    final available = Fmt.balanceInt(
        (plugin.balances.native?.availableBalance ?? 0).toString());

    BigInt gasFee = BigInt.zero;
    if (_fee != null &&
        !isERC20 &&
        symbol == widget.service.pluginEvm.nativeToken) {
      gasFee = BigInt.from(_fee.gasLimit * _fee.gasPrice * 1000000000);
    }

    return Scaffold(
      appBar: AppBar(
          systemOverlayStyle: UI.isDarkTheme(context)
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          title: Text(dic['evm.send.1']),
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
                    /// step1: set amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TokenIcon(
                          args?.token?.id ?? args?.token?.symbol ?? '',
                          widget.service.plugin.tokenIcons,
                          symbol: args?.token?.symbol,
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          child: Text(
                            args?.token?.symbol ?? symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: FlexTextFormField(
                        key: Key(_amountCtrl.text),
                        bottom: Text(
                          '${dic['balance']}: ${Fmt.priceFloorBigInt(
                            available,
                            decimals,
                            lengthMax: 6,
                          )}',
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          prefix: const SizedBox(width: 32, height: 24),
                          suffixIcon: GestureDetector(
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: const Icon(Icons.cancel,
                                  color: Colors.grey, size: 16),
                            ),
                            onTap: () {
                              setState(() {
                                _amountCtrl.text = '';
                              });
                            },
                          ),
                        ),
                        inputFormatters: [UI.decimalInputFormatter(decimals)],
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          final error = Fmt.validatePrice(v, context);
                          _amountError = error;
                          if (error != null) {
                            return _amountError;
                          }
                          final input = Fmt.tokenInt(v, decimals);
                          final feeLeft = available - input;
                          if (feeLeft < gasFee) {
                            _amountError = dic['amount.low'];
                          }

                          return _amountError;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: v3.Button(
                title: dicUI['next'],
                onPressed: _onSubmit,
              ),
            )
          ],
        ),
      ),
    );
  }
}
