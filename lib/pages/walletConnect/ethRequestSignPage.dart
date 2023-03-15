import 'dart:async';

import 'package:app/common/components/ethGasConfirmPanel.dart';
import 'package:app/pages/assets/ethTransfer/gasSettingsPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/ethSignRequestInfo.dart';
import 'package:polkawallet_ui/components/v3/index.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class EthRequestSignPageParams {
  EthRequestSignPageParams(this.request, this.originUri, {this.requestRaw});
  final Uri originUri;
  final WCCallRequestData request;
  final Map requestRaw;
}

class EthRequestSignPage extends StatefulWidget {
  const EthRequestSignPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/wc/sign';

  @override
  _EthRequestSignPageState createState() => _EthRequestSignPageState();
}

class _EthRequestSignPageState extends State<EthRequestSignPage> {
  Timer _gasQueryTimer;

  int _gasLevel = 1;

  bool _submitting = false;

  void _rejectRequest() {
    final wcVersion = widget.service.store.account.wcSessionURI != null ? 1 : 2;
    final EthRequestSignPageParams args =
        ModalRoute.of(context).settings.arguments;
    if (args.requestRaw == null) {
      if (wcVersion == 2) {
        widget.service.plugin.sdk.api.walletConnect
            .confirmPayloadV2(args.request.id, false, '', {});
      } else {
        widget.service.plugin.sdk.api.walletConnect
            .confirmPayload(args.request.id, false, '', {});
      }

      widget.service.store.account.closeCallRequest(args.request.id);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(WCCallRequestResult.fromJson(
          Map<String, dynamic>.of({'error': 'User rejected request.'})));
    }
  }

  Future<void> _showPasswordDialog() async {
    final password = await widget.service.account
        .getEvmPassword(context, widget.service.keyringEVM.current);
    if (password != null) {
      setState(() {
        _submitting = true;
      });
      final EthRequestSignPageParams args =
          ModalRoute.of(context).settings.arguments;

      final gasOptions = _isRequestSendTx(args.request)
          ? Utils.getGasOptionsForTx(args.request.params[3].value,
              widget.service.store.assets.gasParams, _gasLevel, _gasEditable())
          : {};
      if (args.requestRaw == null) {
        _signWC(args.request.id, password, gasOptions);
      } else {
        _sign(args.requestRaw, password, gasOptions);
      }
    }
  }

  Future<void> _signWC(int id, String password, Map gasOptions) async {
    final wcVersion = widget.service.store.account.wcSessionURI != null ? 1 : 2;
    if (wcVersion == 2) {
      await widget.service.plugin.sdk.api.walletConnect
          .confirmPayloadV2(id, true, password, gasOptions);
    } else {
      await widget.service.plugin.sdk.api.walletConnect
          .confirmPayload(id, true, password, gasOptions);
    }

    widget.service.store.account.closeCallRequest(id);

    if (mounted) {
      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> _sign(Map request, String password, Map gasOptions) async {
    final res = await widget.service.plugin.sdk.api.eth.keyring.signEthRequest(
        request,
        widget.service.keyringEVM.current.address,
        password,
        gasOptions);

    if (mounted) {
      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop(res);
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

    final EthRequestSignPageParams args =
        ModalRoute.of(context).settings.arguments;

    final gasLimit = args.request.params[3].value;
    await widget.service.assets.updateEvmGasParams(
        double.parse(gasLimit.toString()).toInt(),
        isFixedGas: !_gasEditable());

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
      final EthRequestSignPageParams args =
          ModalRoute.of(context).settings.arguments;
      if (_isRequestSendTx(args.request)) {
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
      final EthRequestSignPageParams args =
          ModalRoute.of(context).settings.arguments;
      final wcVersion =
          widget.service.store.account.wcSessionURI != null ? 1 : 2;
      final session = wcVersion == 2
          ? widget.service.store.account.wcV2Sessions
              .firstWhere((e) => e.topic == args.request.topic)
              .peerMeta
          : widget.service.store.account.wcSession;
      final acc = widget.service.keyringEVM.current.toKeyPairData();

      final gasParams = widget.service.store.assets.gasParams;
      final gasTokenSymbol = (widget.service.plugin as PluginEvm).nativeToken;
      final gasTokenPrice =
          widget.service.store.assets.marketPrices[gasTokenSymbol] ?? 0;

      return PluginScaffold(
        appBar: PluginAppBar(
            title: Text(dic[_isRequestSendTx(args.request)
                ? 'submit.sign.tx'
                : 'submit.sign.msg']),
            centerTitle: true),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dic['submit.signer']),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: AddressFormItem(acc, svg: acc.icon),
                        ),
                        EthSignRequestInfo(
                          args.request,
                          peer: session,
                          originUri: args.originUri,
                        ),
                        _isRequestSendTx(args.request)
                            ? Container(
                                margin:
                                    const EdgeInsets.only(top: 8, bottom: 8),
                                child: const Text('Gas'),
                              )
                            : Container(),
                        _isRequestSendTx(args.request)
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
              widget.service.keyringEVM.current.observation == true
                  ? Container()
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                            child: Button(
                              isBlueBg: false,
                              onPressed: _rejectRequest,
                              child: Text(
                                  I18n.of(context).getDic(i18n_full_dic_app,
                                      'account')['wc.reject'],
                                  style: Theme.of(context).textTheme.headline3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                            child: Button(
                              isBlueBg: !_submitting,
                              onPressed: _submitting
                                  ? null
                                  : () => _showPasswordDialog(),
                              child: Text(
                                  _isRequestSendTx(args.request)
                                      ? dic['submit.sign.send']
                                      : dic['submit.sign'],
                                  style: const TextStyle(color: Colors.white)),
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
