import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';

class WCPairingConfirmPageParams {
  WCPairingConfirmPageParams({this.req, this.connected});
  final WCPairingData req;
  final connected;
}

class WCPairingConfirmPage extends StatefulWidget {
  const WCPairingConfirmPage(this.plugin, this.keyring);
  final PolkawalletPlugin plugin;
  final Keyring keyring;

  static final String route = '/wc/pairing';

  @override
  _WCPairingConfirmPageState createState() => _WCPairingConfirmPageState();
}

class _WCPairingConfirmPageState extends State<WCPairingConfirmPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    final WCPairingConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;
    final permissions = List.of(args.req.permissions.jsonrpc['methods']);

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
                RoundedCard(
                  margin: EdgeInsets.only(left: 16, right: 16),
                  child: ListTile(
                    leading: Image.network(args.req.proposer.metadata.icons[0]),
                    title: Text(args.req.proposer.metadata.name),
                    subtitle: Text(args.req.proposer.metadata.description),
                  ),
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
            args.connected
                ? Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.lightGreen,
                          ),
                          Text('connected')
                        ],
                      ),
                      RoundedButton(
                        text: 'disconnect',
                        onPressed: () => Navigator.of(context).pop(true),
                      )
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          color: _submitting
                              ? Theme.of(context).disabledColor
                              : Colors.orange,
                          child: FlatButton(
                            padding: EdgeInsets.all(16),
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
                              return FlatButton(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  dic['wc.approve'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
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
