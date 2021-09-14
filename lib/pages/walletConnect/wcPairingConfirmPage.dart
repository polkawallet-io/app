import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class WCPairingConfirmPage extends StatefulWidget {
  const WCPairingConfirmPage(this.service);
  final AppService service;

  static final String route = '/wc/pairing';

  @override
  _WCPairingConfirmPageState createState() => _WCPairingConfirmPageState();
}

class _WCPairingConfirmPageState extends State<WCPairingConfirmPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    final WCPairingData args = ModalRoute.of(context).settings.arguments;
    final permissions = List.of(args.permissions.jsonrpc['methods']);

    return Scaffold(
      appBar: AppBar(
        title:
            Image.asset('assets/images/wallet_connect_banner.png', height: 24),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    dic['wc.connect'],
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: WCPairingSourceInfo(args.proposer),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    dic['wc.permission'],
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: permissions.map((e) {
                      return Text('- $e');
                    }).toList(),
                  ),
                )
              ]),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: _submitting
                        ? Theme.of(context).disabledColor
                        : Colors.orange,
                    child: TextButton(
                      style: ButtonStyle(
                          padding:
                              MaterialStateProperty.all(EdgeInsets.all(16))),
                      child: Text(dic['wc.reject'],
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: _submitting
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).primaryColor,
                    child: Builder(
                      builder: (BuildContext context) {
                        return TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.all(16))),
                          child: Text(
                            dic['wc.approve'],
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                        );
                      },
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

class WCPairingSourceInfo extends StatelessWidget {
  WCPairingSourceInfo(this.peer);
  final WCProposerInfo peer;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(peer.metadata.icons[0]),
      title: Text(peer.metadata.name),
      subtitle: Text(peer.metadata.description),
    );
  }
}
