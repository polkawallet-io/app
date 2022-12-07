import 'dart:async';

import 'package:app/common/components/ethGasConfirmPanel.dart';
import 'package:app/pages/assets/ethTransfer/ethTxDetailPage.dart';
import 'package:app/pages/assets/ethTransfer/gasSettingsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/common/constants.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EthTransferConfirmPageParams {
  EthTransferConfirmPageParams({
    this.tokenSymbol,
    this.tokenDecimals,
    this.contractAddress,
    this.amount,
    this.addressTo,
  });
  final String tokenSymbol;
  final int tokenDecimals;
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

  int _gasLimit = 21000;

  int _gasLevel = 1;

  bool _submitting = false;

  Timer _gasQueryTimer;

  bool _isAcala() {
    final pluginName = (widget.service.plugin as PluginEvm).basic.name;
    return pluginName.contains('acala') || pluginName.contains('karura');
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
    final EthTransferConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;

    final pass = await widget.service.account
        .getEvmPassword(context, widget.service.keyringEVM.current);

    if (pass == null) return;

    final gasOptions = Utils.getGasOptionsForTx(_gasLimit,
        widget.service.store.assets.gasParams, _gasLevel, _gasEditable());

    setState(() {
      _submitting = true;
    });

    final res = await widget.service.assets.evmTransfer(args, pass, gasOptions);
    if (res != null && res['hash'] != null) {
      Navigator.popUntil(context, ModalRoute.withName(ethTokenDetailPageRoute));

      final pendingTx = widget.service.store.assets
          .pendingTx[widget.service.keyringEVM.current.address];
      Navigator.of(context)
          .pushNamed(EthTxDetailPage.route, arguments: pendingTx);
    }
    setState(() {
      _submitting = false;
    });
  }

  Future<void> _updateTxFee() async {
    if (!mounted) return;

    final EthTransferConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;

    _gasLimit = await widget.service.plugin.sdk.api.eth.keyring
        .estimateTransferGas(
            token: args.contractAddress ?? args.tokenSymbol,
            amount: args.amount,
            to: args.addressTo,
            from: widget.service.keyringEVM.current.address);
    await widget.service.assets
        .updateEvmGasParams(_gasLimit, isFixedGas: !_gasEditable());

    if (_gasEditable()) {
      _gasQueryTimer = Timer(const Duration(seconds: 7), _updateTxFee);
    }
  }

  Future<void> _onSetGas() async {
    final gasLevel = await Navigator.of(context)
        .pushNamed(GasSettingsPage.route, arguments: _gasLevel);
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
      _updateTxFee();

      final EthTransferConfirmPageParams args =
          ModalRoute.of(context).settings.arguments;
      _updateAccountTo(args.addressTo);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _gasQueryTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) => Observer(builder: (_) {
        final plugin = widget.service.plugin as PluginEvm;
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
        final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');

        final EthTransferConfirmPageParams args =
            ModalRoute.of(context).settings.arguments;

        final labelStyle = Theme.of(context)
            .textTheme
            .headline4
            ?.copyWith(fontWeight: FontWeight.bold);

        final gasParams = widget.service.store.assets.gasParams;
        final gasTokenPrice =
            widget.service.store.assets.marketPrices[plugin.nativeToken] ?? 0;

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
                            child: AddressFormItem(
                                widget.service.keyringEVM.current)),
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
                        EthGasConfirmPanel(
                          gasParams: gasParams,
                          gasLevel: _gasLevel,
                          isGasEditable: _gasEditable(),
                          gasTokenSymbol: plugin.nativeToken,
                          gasTokenPrice: gasTokenPrice,
                          onTap: _onSetGas,
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.service.keyringEVM.current.observation != true,
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  child: v3.Button(
                    title: dicUI['dApp.confirm'],
                    isBlueBg: _submitting ? false : true,
                    icon:
                    _submitting ? const CupertinoActivityIndicator() : null,
                    onPressed: !_submitting ? _onSubmit : () => null,
                  ),
                ),)
              ],
            ),
          ),
        );
      });
}
