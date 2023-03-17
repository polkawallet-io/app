import 'dart:async';

import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/ethSignRequestInfo.dart';
import 'package:polkawallet_ui/components/v3/index.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginScaffold.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class DotRequestSignPageParams {
  DotRequestSignPageParams(this.request, {this.requestRaw});
  final WCCallRequestData request;
  final Map requestRaw;
}

class DotRequestSignPage extends StatefulWidget {
  const DotRequestSignPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/wc/sign/dot';

  static const String signTypeBytes = 'pub(bytes.sign)';
  static const String signTypeExtrinsic = 'pub(extrinsic.sign)';

  @override
  DotRequestSignPageState createState() => DotRequestSignPageState();
}

class DotRequestSignPageState extends State<DotRequestSignPage> {
  bool _submitting = false;

  bool _isRequestSignTx(WCCallRequestData args) {
    return args.params[0].value == 'polkadot_signTransaction';
  }

  void _rejectRequest() {
    final DotRequestSignPageParams args =
        ModalRoute.of(context).settings.arguments;
    if (args.requestRaw == null) {
      widget.service.plugin.sdk.api.walletConnect
          .confirmPayloadV2(args.request.id, false, '', {});

      widget.service.store.account.closeCallRequest(args.request.id);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(WCCallRequestResult.fromJson(
          Map<String, dynamic>.of({'error': 'User rejected request.'})));
    }
  }

  Future<void> _showPasswordDialog() async {
    final DotRequestSignPageParams args =
        ModalRoute.of(context).settings.arguments;
    final password = await widget.service.account
        .getPassword(context, widget.service.keyring.current);
    if (password != null) {
      setState(() {
        _submitting = true;
      });

      await widget.service.plugin.sdk.api.walletConnect
          .confirmPayloadV2(args.request.id, true, password, null);

      widget.service.store.account.closeCallRequest(args.request.id);

      if (mounted) {
        setState(() {
          _submitting = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
      final DotRequestSignPageParams args =
          ModalRoute.of(context).settings.arguments;
      final session = widget.service.store.account.wcV2Sessions
          .firstWhere((e) => e.topic == args.request.topic);

      return PluginScaffold(
        appBar: PluginAppBar(
            title: Text(dic[_isRequestSignTx(args.request)
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
                          child: AddressFormItem(widget.service.keyring.current,
                              svg: widget.service.keyring.current.icon),
                        ),
                        EthSignRequestInfo(
                          args.request,
                          peer: session.peerMeta,
                          originUri: Uri(),
                        ),
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
                              child: Text(I18n.of(context).getDic(
                                  i18n_full_dic_app, 'account')['wc.reject']),
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
                              child: Text(dic['submit.sign'],
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
