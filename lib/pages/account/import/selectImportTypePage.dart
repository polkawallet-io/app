import 'package:app/pages/account/import/importAccountFormKeyStore.dart';
import 'package:app/pages/account/import/importAccountFromRawSeed.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

import 'importAccountFormMnemonic.dart';

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(title: Text(dic['import.type'])),
              RoundedCard(
                margin: EdgeInsets.only(left: 16.w, right: 16.w),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: _keyOptions.map((e) {
                    return Container(
                      margin: EdgeInsets.only(top: 12.h, bottom: 12.h),
                      child: SettingsPageListItem(
                        label: dic[e],
                        onTap: () {
                          switch (e) {
                            case 'mnemonic':
                              Navigator.pushNamed(
                                  context, ImportAccountFormMnemonic.route,
                                  arguments: {"type": e});
                              break;
                            case 'rawSeed':
                              Navigator.pushNamed(
                                  context, ImportAccountFromRawSeed.route,
                                  arguments: {"type": e});
                              break;
                            case 'keystore':
                              Navigator.pushNamed(
                                  context, ImportAccountFormKeyStore.route,
                                  arguments: {"type": e});
                              break;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
