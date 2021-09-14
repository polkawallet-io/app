import 'dart:async';
import 'dart:convert';

import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/payloadData.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
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

  Future<void> _showPasswordDialog(KeyPairData acc) async {
    final password = await widget.getPassword(context, acc);
    if (password != null) {
      _sign(password);
    }
  }

  Future<void> _sign(String password) async {
    setState(() {
      _submitting = true;
    });
    final WCPayloadData args = ModalRoute.of(context).settings.arguments;
    final res = await widget.service.plugin.sdk.api.walletConnect
        .signPayload(args, password);
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
    final WCPayloadData args = ModalRoute.of(context).settings.arguments;
    final session = widget.service.store.account.wcSessions
        .firstWhere((e) => e.topic == args.topic);
    final address = args.payload.params[0];
    final KeyPairData acc = widget.service.keyring.keyPairs.firstWhere((acc) {
      bool matched = false;
      widget.service.keyring.store.pubKeyAddressMap.values.forEach((e) {
        e.forEach((k, v) {
          if (acc.pubKey == k && address == v) {
            matched = true;
          }
        });
      });
      return matched;
    });
    return Scaffold(
      appBar: AppBar(
          title: Text(dic[args.payload.method == 'signExtrinsic'
              ? 'submit.sign.tx'
              : 'submit.sign.msg']),
          centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: AddressFormItem(acc,
                        svg: acc.icon, label: dic['submit.signer']),
                  ),
                  SignExtrinsicInfo(args, session.peer),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: _submitting ? Colors.black12 : Colors.orange,
                    child: TextButton(
                      style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all(EdgeInsets.all(16))),
                      child: Text(dic['cancel'],
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: _submitting
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).primaryColor,
                    child: TextButton(
                      style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all(EdgeInsets.all(16))),
                      child: Text(
                        dic['submit.sign'],
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed:
                          _submitting ? null : () => _showPasswordDialog(acc),
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
  SignExtrinsicInfo(this.payload, this.peer);
  final WCPayloadData payload;
  final WCProposerInfo peer;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = payload.payload.params[1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 16),
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
        payload.payload.method == 'signExtrinsic'
            ? Column(
                children: [
                  InfoItemRow('call', '${data['module']}.${data['call']}'),
                  InfoItemRow(
                    'params',
                    JsonEncoder.withIndent('  ').convert(data['params']),
                  ),
                  InfoItemRow('tip', data['tip']),
                ],
              )
            : InfoItemRow('message', data)
      ],
    );
  }
}
