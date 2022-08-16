import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/import/selectImportTypePage.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';

enum AccountType { Substrate, Evm }

class AccountTypeSelectPage extends StatefulWidget {
  AccountTypeSelectPage({Key key}) : super(key: key);

  static final String route = '/account/accountTypeSelect';

  @override
  State<AccountTypeSelectPage> createState() => _AccountTypeSelectPageState();
}

class _AccountTypeSelectPageState extends State<AccountTypeSelectPage> {
  Future<void> _onCreateAccount(int isImport, AccountType type) async {
    Navigator.of(context).pushNamed(
        isImport == 0 ? CreateAccountPage.route : SelectImportTypePage.route,
        arguments: {"accountType": type});
  }

  @override
  Widget build(BuildContext context) {
    final isImport = ModalRoute.of(context).settings.arguments as int;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
        appBar: AppBar(
            title: Text(dic[isImport == 0 ? 'create' : 'import']),
            centerTitle: true,
            leading: BackBtn(),
            elevation: 0),
        body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dic['create.warn3'],
                  style: Theme.of(context)
                      .textTheme
                      .headline4
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 33, bottom: 24),
                  child: Button(
                    title: "Substrate ${dic['account']}",
                    onPressed: () =>
                        _onCreateAccount(isImport, AccountType.Substrate),
                  ),
                ),
                Button(
                  title: "Evm ${dic['account']}",
                  onPressed: () => _onCreateAccount(isImport, AccountType.Evm),
                ),
              ],
            )));
  }
}
