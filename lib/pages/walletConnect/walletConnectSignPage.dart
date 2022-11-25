import 'dart:async';

import 'package:app/common/components/ethGasConfirmPanel.dart';
import 'package:app/pages/assets/ethTransfer/gasSettingsPage.dart';
import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart';
import 'package:polkawallet_ui/components/v3/infoItemRow.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class WalletConnectSignPage extends StatefulWidget {
  WalletConnectSignPage(this.service, this.getPassword);
  final AppService service;
  final Future<String> Function(BuildContext, KeyPairData) getPassword;

  static const String route = '/wc/sign';

  static const String signTypeBytes = 'pub(bytes.sign)';
  static const String signTypeExtrinsic = 'pub(extrinsic.sign)';

  @override
  _WalletConnectSignPageState createState() => _WalletConnectSignPageState();
}

class _WalletConnectSignPageState extends State<WalletConnectSignPage> {
  Timer _gasQueryTimer;

  int _gasLevel = 1;

  bool _submitting = false;

  Future<void> _showPasswordDialog() async {
    final password = await widget.service.account
        .getEvmPassword(context, widget.service.keyringEVM.current);
    if (password != null) {
      _sign(password);
    }
  }

  Future<void> _sign(String password) async {
    setState(() {
      _submitting = true;
    });
    final WCCallRequestData args = ModalRoute.of(context).settings.arguments;

    final gasOptions = _isRequestSendTx(args)
        ? Utils.getGasOptionsForTx(args.params[3].value,
            widget.service.store.assets.gasParams, _gasLevel, _gasEditable())
        : {};
    final res = await widget.service.plugin.sdk.api.walletConnect
        .confirmPayload(args.id, true, password, gasOptions);
    print('user signed payload:');
    print((res as WCCallRequestResult).result);

    widget.service.store.account.closeCallRequest(args.id);

    if (mounted) {
      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
    }
  }

  bool _isRequestSendTx(WCCallRequestData args) {
    return args.params[0].value == 'eth_sendTransaction';
  }

  bool _gasEditable() {
    final pluginName = (widget.service.plugin as PluginEvm).basic.name;
    return !pluginName.contains('acala') && !pluginName.contains('karura');
  }

  Future<void> _updateTxFee() async {
    if (!mounted) return;

    final WCCallRequestData args = ModalRoute.of(context).settings.arguments;

    final gasLimit = args.params[3].value;
    await widget.service.assets
        .updateEvmGasParams(gasLimit, isFixedGas: !_gasEditable());

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
      final WCCallRequestData args = ModalRoute.of(context).settings.arguments;
      if (_isRequestSendTx(args)) {
        _updateTxFee();
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
    return Observer(builder: (_) {
      final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
      final WCCallRequestData args = ModalRoute.of(context).settings.arguments;
      final session = widget.service.store.account.wcSession;
      final acc = widget.service.keyringEVM.current.toKeyPairData();

      final gasParams = widget.service.store.assets.gasParams;
      final gasTokenSymbol = (widget.service.plugin as PluginEvm).nativeToken;
      final gasTokenPrice =
          widget.service.store.assets.marketPrices[gasTokenSymbol] ?? 0;

      return Scaffold(
        appBar: AppBar(
            title: Text(dic[args.event.contains('Transaction')
                ? 'submit.sign.tx'
                : 'submit.sign.msg']),
            centerTitle: true,
            leading: BackBtn()),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dic['submit.signer']),
                        Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          child: AddressFormItem(acc, svg: acc.icon),
                        ),
                        SignExtrinsicInfo(args, session),
                        _isRequestSendTx(args)
                            ? Container(
                                margin:
                                    const EdgeInsets.only(top: 8, bottom: 8),
                                child: const Text('Gas'),
                              )
                            : Container(),
                        _isRequestSendTx(args)
                            ? EthGasConfirmPanel(
                                gasParams: gasParams,
                                gasLevel: _gasLevel,
                                isGasEditable: _gasEditable(),
                                gasTokenSymbol: gasTokenSymbol,
                                gasTokenPrice: gasTokenPrice,
                                onTap: _onSetGas,
                              )
                            : Container(),
                      ]),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                      child: Button(
                        isBlueBg: false,
                        child: Text(
                            I18n.of(context).getDic(
                                i18n_full_dic_app, 'account')['wc.reject'],
                            style: Theme.of(context).textTheme.headline3),
                        onPressed: () {
                          widget.service.plugin.sdk.api.walletConnect
                              .confirmPayload(args.id, false, '', {});

                          widget.service.store.account
                              .closeCallRequest(args.id);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                      child: Button(
                        isBlueBg: !_submitting,
                        onPressed:
                            _submitting ? null : () => _showPasswordDialog(),
                        child: Text(dic['submit.sign'],
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }
}

class SignExtrinsicInfo extends StatelessWidget {
  SignExtrinsicInfo(this.callRequest, this.peer);
  final WCCallRequestData callRequest;
  final WCPeerMetaData peer;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    List<WCCallRequestParamItem> params = callRequest.params;
    if (callRequest.params[0].value == 'eth_sendTransaction') {
      params = [
        ...callRequest.params.sublist(0, 3),
        ...callRequest.params.sublist(5)
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            dic['wc.source'],
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        WCPairingSourceInfo(peer),
        Padding(
          padding: EdgeInsets.only(bottom: 16, top: 16),
          child: Text(
            dic['wc.data'],
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        Column(
            children: params.map((e) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InfoItemRow(e.label, e.value.toString()),
          );
        }).toList())
      ],
    );
  }
}
