import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/import/selectImportTypePage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class AccountBindEntryPage extends StatefulWidget {
  const AccountBindEntryPage({Key key}) : super(key: key);

  static const String route = '/account/accountBindEntry';

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
            title: Text('Bind ${type == 0 ? "Substrate" : "Evm"} account'),
            centerTitle: true,
            leading: const BackBtn(),
            elevation: 0),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Button(
                title: dic['create'],
                isBlueBg: true,
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(CreateAccountPage.route, arguments: {
                    "accountType":
                        type == 0 ? AccountType.Substrate : AccountType.Evm,
                    "needChange": false
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Button(
                title: dic['import'],
                isBlueBg: true,
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(SelectImportTypePage.route, arguments: {
                    "accountType":
                        type == 0 ? AccountType.Substrate : AccountType.Evm,
                    "needChange": false
                  });
                },
              ),
            ),
          ],
        ));
  }
}
