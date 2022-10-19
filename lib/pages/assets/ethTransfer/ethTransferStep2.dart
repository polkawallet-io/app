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

  EthTransferPageParams pageParams;

  EvmGasParams _fee;
  Map _gasOptions;

  bool _isAcala() {
    return widget.service.pluginEvm.basic.name.contains('acala') ||
        widget.service.pluginEvm.basic.name.contains('karura');
  }

  Future<void> _getTxFee() async {
    final EthTransferConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;
    EvmGasParams gasParams;
    if (_isAcala()) {
      /// in acala/karura we use const gasLimit & gasPrice
      _gasOptions =
          widget.service.plugin.sdk.api.eth.account.getAcalaGasParams();
      gasParams = EvmGasParams(
          gasLimit: int.parse(_gasOptions['gasLimit']),
          gasPrice: Fmt.balanceDouble(_gasOptions['gasPrice'], 9));
    } else {
      /// in ethereum we use dynamic gas estimate
      final gasLimit = await widget.service.plugin.sdk.api.eth.keyring
          .estimateTransferGas(
              token: args.contractAddress.isEmpty
                  ? args.tokenSymbol
                  : args.contractAddress,
              amount: args.amount,
              to: args.addressTo);
      gasParams = await widget.service.plugin.sdk.api.eth.account
          .queryEthGasParams(gasLimit: gasLimit);
      _gasOptions = {
        'gasLimit': gasLimit,
        'gasPrice': Fmt.tokenInt(gasParams.gasPrice.toString(), 9),
        'maxFeePerGas': Fmt.tokenInt(
            gasParams.estimatedFee[EstimatedFeeLevel.medium].maxFeePerGas
                .toString(),
            9),
        'maxPriorityFeePerGas': Fmt.tokenInt(
            gasParams
                .estimatedFee[EstimatedFeeLevel.medium].maxPriorityFeePerGas
                .toString(),
            9),
      };
    }

    setState(() {
      _fee = gasParams;
    });
  }

  Future<void> _onSubmit() async {
    final EthTransferPageParams args =
        ModalRoute.of(context).settings.arguments;
    final params = EthTransferConfirmPageParams(
        tokenSymbol: pageParams.token.symbol,
        contractAddress:
            pageParams.token.id.startsWith('0x') ? pageParams.token.id : '',
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
  Widget build(BuildContext context) {
    final plugin = widget.service.plugin as PluginEvm;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final symbol = pageParams?.token?.symbol ?? 'ACA';
    final decimals = pageParams?.token?.decimals ?? 18;

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

    print('gas fee');
    print(_fee.gasLimit * _fee.gasPrice);

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
                          pageParams?.token?.id ?? '',
                          widget.service.plugin.tokenIcons,
                          symbol: pageParams?.token?.symbol,
                        ),
                        Text(pageParams?.token?.symbol ?? symbol)
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
                          prefix: Container(width: 32, height: 24),
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
                          if (feeLeft < BigInt.zero) {
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
