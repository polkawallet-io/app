import 'package:app/pages/walletConnect/wcPairingConfirmPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/v3/roundedCardV3.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class WCSessionsPage extends StatefulWidget {
  const WCSessionsPage(this.service);
  final AppService service;

  static final String route = '/wc/session';

  @override
  _WCSessionsPageState createState() => _WCSessionsPageState();
}

class _WCSessionsPageState extends State<WCSessionsPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Observer(builder: (_) {
      final sessions = widget.service.store.account.wcSessions;
      return Scaffold(
        appBar: AppBar(
            title: Image.asset('assets/images/wallet_connect_banner.png',
                height: 24),
            centerTitle: true,
            leading: BackBtn(
              onBack: () => Navigator.of(context).pop(),
            )),
        body: SafeArea(
          child: ListView(
            children: sessions.map((session) {
              final permissions =
                  List.of(session.permissions.jsonrpc['methods']);
              return RoundedCardV3(
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
                          child: WCPairingSourceInfo(session.peer),
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
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.lightGreen,
                            ),
                            Text(dic['wc.connected'])
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: RoundedButton(
                            text: dic['wc.disconnect'],
                            color: Colors.red,
                            onPressed: () {
                              // widget.service.plugin.sdk.api.walletConnect.disconnect({
                              //   'topic': _walletConnectSession.topic,
                              //   'reason': "user closed connection"
                              // });
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}
