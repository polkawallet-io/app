import 'package:app/pages/account/accountTypeSelectPage.dart';
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
  var _keyOptions = [
    'mnemonic',
    'rawSeed',
    'keystore',
  ];

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context).settings.arguments as Map;
    final type = data['accountType'] as AccountType;
    final needChange = data["needChange"];
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    if (type == AccountType.Evm) {
      _keyOptions = [
        'mnemonic',
        'privateKey',
        'keystore',
      ];
    }
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['import']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                  title: Text(dic['import.type'],
                      style: Theme.of(context).textTheme.headline4)),
              RoundedCard(
                  margin: EdgeInsets.only(left: 15.w, right: 15.w),
                  padding: EdgeInsets.all(8),
                  child: ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(top: 12.h, bottom: 12.h),
                          child: SettingsPageListItem(
                            label: dic[_keyOptions[index]],
                            onTap: () {
                              switch (_keyOptions[index]) {
                                case 'mnemonic':
                                  Navigator.pushNamed(
                                      context, ImportAccountFormMnemonic.route,
                                      arguments: {
                                        "type": _keyOptions[index],
                                        "accountType": type,
                                        "needChange": needChange
                                      });
                                  break;
                                case 'rawSeed':
                                case 'privateKey':
                                  Navigator.pushNamed(
                                      context, ImportAccountFromRawSeed.route,
                                      arguments: {
                                        "type": _keyOptions[index],
                                        "accountType": type,
                                        "needChange": needChange
                                      });
                                  break;
                                case 'keystore':
                                  Navigator.pushNamed(
                                      context, ImportAccountFormKeyStore.route,
                                      arguments: {
                                        "type": _keyOptions[index],
                                        "accountType": type,
                                        "needChange": needChange
                                      });
                                  break;
                              }
                            },
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemCount: _keyOptions.length)),
            ],
          ),
        ),
      ),
    );
  }
}
