import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/import/selectImportTypePage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class AccountBindEntryPage extends StatefulWidget {
  AccountBindEntryPage({Key key}) : super(key: key);

  static final String route = '/account/accountBindEntry';

  @override
  State<AccountBindEntryPage> createState() => _AccountBindEntryPageState();
}

class _AccountBindEntryPageState extends State<AccountBindEntryPage> {
  @override
  Widget build(BuildContext context) {
    final type = ModalRoute.of(context).settings.arguments as int;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
        appBar: AppBar(
            title: Text('Bind ${type == 0 ? "substrate" : "Evm"} account'),
            centerTitle: true,
            leading: BackBtn(),
            elevation: 0),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Button(
                title: dic['create'],
                isBlueBg: true,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                      type == 0
                          ? CreateAccountPage.route
                          : CreateAccountPage.route,
                      arguments: 0);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Button(
                title: dic['import'],
                isBlueBg: true,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                      type == 0
                          ? SelectImportTypePage.route
                          : SelectImportTypePage.route,
                      arguments: 1);
                },
              ),
            ),
          ],
        ));
  }
}
