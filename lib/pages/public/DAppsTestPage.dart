import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';

class DAppsTestPage extends StatefulWidget {
  static const route = '/test/browser';

  @override
  _DAppsTestPageState createState() => _DAppsTestPageState();
}

class _DAppsTestPageState extends State<DAppsTestPage> {
  final TextEditingController _urlCtrl = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackBtn(),
        centerTitle: true,
        title: Text('DApps Test'),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: 'https://',
                      clearButtonMode: OverlayVisibilityMode.editing,
                      controller: _urlCtrl,
                    ),
                  ),
                  OutlinedButtonSmall(
                    margin: EdgeInsets.only(left: 8),
                    content: 'Go',
                    active: true,
                    onPressed: () {
                      final url = _urlCtrl.text.trim();
                      Navigator.of(context).pushNamed(DAppWrapperPage.route,
                          arguments:
                              url.contains('://') ? url : 'https://$url');
                    },
                  )
                ],
              ),
              Divider(height: 32),
              RoundedCard(
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('apps.acala.network'),
                  onTap: () {
                    Navigator.of(context).pushNamed(DAppWrapperPage.route,
                        arguments: 'https://apps.acala.network/');
                  },
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('apps.karura.network'),
                  onTap: () {
                    Navigator.of(context).pushNamed(DAppWrapperPage.route,
                        arguments: 'https://apps.karura.network/');
                  },
                ),
              ),
              RoundedCard(
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text('polkadot.polkassembly.io'),
                  onTap: () {
                    Navigator.of(context).pushNamed(DAppWrapperPage.route,
                        arguments: 'https://polkadot.polkassembly.io/');
                  },
                ),
              ),
              RoundedCard(
                child: ListTile(
                  title: Text('bifrost.app'),
                  onTap: () {
                    Navigator.of(context).pushNamed(DAppWrapperPage.route,
                        arguments: 'https://bifrost.app/');
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
