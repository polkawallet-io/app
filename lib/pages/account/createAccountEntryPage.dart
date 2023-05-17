import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';

class CreateAccountEntryPage extends StatelessWidget {
  CreateAccountEntryPage(this.service);

  static final String route = '/account/entry';

  final AppService service;

  void _checkJsCodeStarted(BuildContext context) {
    if (service.plugin.sdk.webView.webViewLoaded) {
      if (service.plugin.sdk.webView.jsCodeStarted == 0) {
        showCupertinoDialog(
            context: context,
            builder: (_) {
              return PolkawalletAlertDialog(
                content: Text(I18n.of(context)
                    .getDic(i18n_full_dic_app, 'public')['os.invalid']),
              );
            });
      }
    }
  }

  void _autoSwitchAccountType(BuildContext context) {
    /// if we are in a specific account type(substrate or evm), but account is empty,
    /// then we check if we can switch to another plugin with another account type.
    if (service.store.account.accountType == AccountType.Evm) {
      if (service.keyringEVM.allAccounts.isEmpty &&
          service.keyring.allAccounts.isNotEmpty) {
        Navigator.of(context).pushNamed(NetworkSelectPage.route);
      }
    } else {
      if (service.keyring.allAccounts.isEmpty &&
          service.keyringEVM.allAccounts.isNotEmpty) {
        Navigator.of(context).pushNamed(NetworkSelectPage.route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkJsCodeStarted(context);

      _autoSwitchAccountType(context);
    });

    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // appBar: AppBar(title: Text(dic['add']), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width / 3,
                child: Image.asset('assets/images/icon.png'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Button(
                title: dic['create'],
                isBlueBg: true,
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AccountTypeSelectPage.route, arguments: 0);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Button(
                title: dic['import'],
                isBlueBg: true,
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AccountTypeSelectPage.route, arguments: 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
