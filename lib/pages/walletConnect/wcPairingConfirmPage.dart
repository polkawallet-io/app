import 'package:app/common/components/jumpToLink.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

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

    final WCPeerMetaData args = ModalRoute.of(context).settings.arguments;
    // TODO: fix this page to implement wallet-connect
    // final permissions = List.of(args.permissions.jsonrpc['methods']);

    return Scaffold(
      appBar: AppBar(
          title: Image.asset('assets/images/wallet_connect_banner.png',
              height: 20),
          centerTitle: true,
          leading: BackBtn()),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child:
                  ListView(physics: BouncingScrollPhysics(), children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    dic['wc.connect'],
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: WCPairingSourceInfoDetail(args),
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
                    children: [
                      dic['wc.permission.address'],
                      dic['wc.permission.req']
                    ].map((e) {
                      return Text('- $e');
                    }).toList(),
                  ),
                )
              ]),
            ),
            Container(
              margin: EdgeInsets.only(top: 24, bottom: 8),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                JumpToLink(
                  'https://walletconnect.com/',
                  text: dic['wc.service'],
                  color: Theme.of(context).disabledColor,
                ),
              ]),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                    child: Button(
                      isBlueBg: false,
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        dic['wc.reject'],
                        style: Theme.of(context).textTheme.headline3,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                    child: Button(
                      isBlueBg: !_submitting,
                      child: Text(
                        dic['wc.approve'],
                        style: Theme.of(context)
                            .textTheme
                            .headline3
                            .copyWith(color: Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
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
  WCPairingSourceInfo(this.metadata);
  final WCPeerMetaData metadata;
  @override
  Widget build(BuildContext context) {
    return metadata != null
        ? RoundedCard(
            child: ListTile(
              dense: true,
              leading: Image.network(metadata.icons[0], width: 40),
              title: Text(metadata.name),
              subtitle: Text(metadata.url),
            ),
          )
        : Container();
  }
}

class WCPairingSourceInfoDetail extends StatelessWidget {
  WCPairingSourceInfoDetail(this.metadata);
  final WCPeerMetaData metadata;
  @override
  Widget build(BuildContext context) {
    return metadata != null
        ? Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Image.network(metadata.icons[0], width: 64),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(metadata.name,
                    style: Theme.of(context).textTheme.headline3),
              ),
              Text(
                metadata.url,
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
              Text(metadata.description),
            ],
          )
        : Container();
  }
}
