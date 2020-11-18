import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';

class ReceivePage extends StatelessWidget {
  ReceivePage(this.service);
  final AppService service;

  static final String route = '/assets/receive';

  @override
  Widget build(BuildContext context) {
    String codeAddress =
        'substrate:${service.keyring.current.address}:${service.keyring.current.pubKey}:${service.keyring.current.name}';
    Color themeColor = Theme.of(context).primaryColor;

    final accInfo = service.keyring.current.indexInfo;

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_app, 'assets')['receive']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Stack(
              alignment: AlignmentDirectional.topCenter,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Image.asset('assets/images/receive_line.png'),
                ),
                Container(
                  margin: EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(const Radius.circular(4)),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: AddressIcon(
                          service.keyring.current.address,
                          svg: service.keyring.current.icon,
                        ),
                      ),
                      Text(
                        service.keyring.current.name,
                        style: Theme.of(context).textTheme.headline4,
                      ),
                      accInfo != null && accInfo['accountIndex'] != null
                          ? Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(accInfo['accountIndex']),
                            )
                          : Container(width: 8, height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 4, color: themeColor),
                          borderRadius:
                              BorderRadius.all(const Radius.circular(8)),
                        ),
                        margin: EdgeInsets.fromLTRB(48, 16, 48, 24),
                        child: QrImage(
                          data: codeAddress,
                          size: 200,
                          embeddedImage: AssetImage('assets/images/app.png'),
                          embeddedImageStyle:
                              QrEmbeddedImageStyle(size: Size(40, 40)),
                        ),
                      ),
                      Container(
                        width: 160,
                        child: Text(service.keyring.current.address),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        padding: EdgeInsets.only(top: 16, bottom: 32),
                        child: RoundedButton(
                          text: I18n.of(context)
                              .getDic(i18n_full_dic_app, 'assets')['copy'],
                          onPressed: () => UI.copyAndNotify(
                              context, service.keyring.current.address),
                        ),
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
