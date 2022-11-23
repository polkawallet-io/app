import 'dart:async';

import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
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
    final res = await widget.service.plugin.sdk.api.walletConnect
        .confirmPayload(args.id, true, password);
    if (mounted) {
      setState(() {
        _submitting = false;
      });
    }
    Navigator.of(context).pop(res);
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final WCCallRequestData args = ModalRoute.of(context).settings.arguments;
    final session = widget.service.store.account.wcSession;
    final acc = widget.service.keyringEVM.current.toKeyPairData();
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
                      child: Text(dic['cancel'],
                          style: Theme.of(context).textTheme.headline3),
                      onPressed: () {
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
  }
}

class SignExtrinsicInfo extends StatelessWidget {
  SignExtrinsicInfo(this.callRequest, this.peer);
  final WCCallRequestData callRequest;
  final WCPeerMetaData peer;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
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
            children: callRequest.params.map((e) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: InfoItemRow(e.label, e.value.toString()),
          );
        }).toList())
      ],
    );
  }
}
