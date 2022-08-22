import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/create/accountAdvanceOption.dart';
import 'package:app/pages/account/create/backupAccountPage.dart';
import 'package:app/pages/account/create/createAccountForm.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';

class CreateAccountPage extends StatefulWidget {
  CreateAccountPage(this.service);
  final AppService service;

  static final String route = '/account/create';

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();

  int _step = 0;
  bool _submitting = false;

  Future<bool> _importAccount() async {
    setState(() {
      _submitting = true;
    });
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PolkawalletAlertDialog(
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['loading']),
          content: Container(
              height: 64,
              child:
                  CupertinoActivityIndicator(color: const Color(0xFF3C3C44))),
        );
      },
    );

    final data = ModalRoute.of(context).settings.arguments as Map;
    final type = data['accountType'] as AccountType;
    try {
      final json = await widget.service.account.importAccount(
          cryptoType: _advanceOptions.type ?? CryptoType.sr25519,
          derivePath: _advanceOptions.path ?? '',
          isFromCreatePage: true,
          type: type);
      await widget.service.account.addAccount(
          json: json,
          cryptoType: _advanceOptions.type ?? CryptoType.sr25519,
          derivePath: _advanceOptions.path ?? '',
          isFromCreatePage: true,
          type: type);

      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
      return true;
    } catch (err) {
      Navigator.of(context).pop();
      AppUI.alertWASM(context, () {
        setState(() {
          _submitting = false;
          _step = 0;
        });
      }, errorMsg: err.toString());
      return false;
    }
  }

  Future<void> _onNext() async {
    final next = await showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
        final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
        return PolkawalletAlertDialog(
          title: Container(),
          content: Column(
            children: <Widget>[
              Image.asset('assets/images/screenshot.png'),
              Container(
                padding: EdgeInsets.only(top: 16, bottom: 24),
                child: Text(
                  dic['create.warn9'],
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: UI.getTextSize(18, context),
                    fontFamily: UI.getFontFamily('TitilliumWeb', context),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(dic['create.warn10']),
            ],
          ),
          actions: <Widget>[
            PolkawalletActionSheetAction(
              child: Text(
                dicCommon['cancel'],
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            PolkawalletActionSheetAction(
              isDefaultAction: true,
              child: Text(
                dicCommon['ok'],
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (next) {
      final data = ModalRoute.of(context).settings.arguments as Map;
      // data['accountType'];
      final advancedOptions = await Navigator.pushNamed(
          context, BackupAccountPage.route,
          arguments: data);
      if (advancedOptions != null) {
        setState(() {
          _step = 1;
          _advanceOptions = (advancedOptions as AccountAdvanceOptionParams);
        });
      } else {
        widget.service.store.account.resetNewAccount();
      }
    }
  }

  Widget _generateSeed(BuildContext context) {
    var theme = Theme.of(context).textTheme;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Scaffold(
      appBar: AppBar(
          title: Text(dic['create']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(dic['create.warn1'],
                        style: theme.headline4
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Text(dic['create.warn2']),
                  Container(
                    padding: EdgeInsets.only(bottom: 10, top: 32),
                    child: Text(dic['create.warn3'],
                        style: theme.headline4
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(dic['create.warn4']),
                  ),
                  Text(dic['create.warn5']),
                  Container(
                    padding: EdgeInsets.only(bottom: 10, top: 32),
                    child: Text(dic['create.warn6'],
                        style: theme.headline4
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(dic['create.warn7']),
                  ),
                  Text(dic['create.warn8']),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Button(
                title:
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
                onPressed: () => _onNext(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return _generateSeed(context);
    }
    final data = ModalRoute.of(context).settings.arguments as Map;
    final type = data['accountType'] as AccountType;
    final needChange = data['needChange'] == false;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_app, 'account')['create']),
        leading: BackBtn(
          onBack: () {
            setState(() {
              _step = 0;
            });
          },
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CreateAccountForm(
          widget.service,
          submitting: _submitting,
          onSubmit: _importAccount,
          needChange: !needChange,
          type: type,
        ),
      ),
    );
  }
}
