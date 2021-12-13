import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

import 'importAccountFormKeyStore.dart';
import 'importAccountFormMnemonic.dart';
import 'importAccountFromRawSeed.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class SelectImportTypePage extends StatefulWidget {
  static final String route = '/account/selectImportType';
  final AppService service;

  SelectImportTypePage(this.service, {Key key}) : super(key: key);

  @override
  _SelectImportTypePageState createState() => _SelectImportTypePageState();
}

class _SelectImportTypePageState extends State<SelectImportTypePage> {
  final _keyOptions = [
    'mnemonic',
    'rawSeed',
    'keystore',
  ];

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['import']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
          child: Column(
        children: [
          ListTile(title: Text(dic['import.type'])),
          Expanded(
              child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(10),
                  itemCount: _keyOptions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(dic[_keyOptions[index]]),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        switch (index) {
                          case 0:
                            Navigator.pushNamed(
                                context, ImportAccountFormMnemonic.route,
                                arguments: {"type": _keyOptions[index]});
                            break;
                          case 1:
                            Navigator.pushNamed(
                                context, ImportAccountFromRawSeed.route,
                                arguments: {"type": _keyOptions[index]});
                            break;
                          case 2:
                            Navigator.pushNamed(
                                context, ImportAccountFormKeyStore.route,
                                arguments: {"type": _keyOptions[index]});
                            break;
                        }
                      },
                    );
                  }))
        ],
      )),
    );
  }
}
