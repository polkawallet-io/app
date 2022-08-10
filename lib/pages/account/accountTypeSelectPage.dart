import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/import/selectImportTypePage.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/button.dart';

class AccountTypeSelectPage extends StatefulWidget {
  AccountTypeSelectPage({Key key}) : super(key: key);

  static final String route = '/account/accountTypeSelect';

  @override
  State<AccountTypeSelectPage> createState() => _AccountTypeSelectPageState();
}

class _AccountTypeSelectPageState extends State<AccountTypeSelectPage> {
  Future<void> _onCreateAccount(int step, int type) async {
    Navigator.of(context).pushNamed(step == 0
        ? type == 0
            ? CreateAccountPage.route
            : CreateAccountPage.route
        : type == 0
            ? SelectImportTypePage.route
            : SelectImportTypePage.route);
  }

  @override
  Widget build(BuildContext context) {
    final step = ModalRoute.of(context).settings.arguments as int;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
        appBar: AppBar(
            title: Text(dic[step == 0 ? 'create' : 'import']),
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
                    onPressed: () => _onCreateAccount(step, 0),
                  ),
                ),
                Button(
                  title: "Evm ${dic['account']}",
                  onPressed: () => _onCreateAccount(step, 1),
                ),
              ],
            )));
  }
}
