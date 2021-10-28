import 'package:app/service/index.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class InitiateRecoveryPage extends StatefulWidget {
  InitiateRecoveryPage(this.service);
  final AppService service;
  static final String route = '/profile/recovery/init';

  @override
  _InitiateRecoveryPage createState() => _InitiateRecoveryPage();
}

class _InitiateRecoveryPage extends State<InitiateRecoveryPage> {
  final double _recoveryDeposit = 5 / 6;

  KeyPairData _recoverable;
  bool _loading = false;

  Future<void> _handleRecoverableSelect() async {
    var res = await Navigator.of(context).pushNamed(
      AccountListPage.route,
      arguments: AccountListPageParams(
          title:
              I18n.of(context).getDic(i18n_full_dic_app, 'profile')['contact'],
          list: widget.service.keyring.allAccounts),
    );
    if (res != null) {
      setState(() {
        _recoverable = res;
      });
    }
  }

  Future<void> _onValidateSubmit() async {
    /// check if balance enough for deposit
    final decimals = widget.service.plugin.networkState.tokenDecimals[0];
    if (!AppUI.checkBalanceAndAlert(
      context,
      widget.service.plugin.balances.native,
      Fmt.tokenInt(_recoveryDeposit.toString(), decimals),
    )) {
      return;
    }

    /// check if account is recoverable
    setState(() {
      _loading = true;
    });
    final info =
        await widget.service.account.queryRecoverable(_recoverable.address);
    setState(() {
      _loading = false;
    });
    if (info == null) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
          return CupertinoAlertDialog(
            title: Text(Fmt.address(_recoverable.address)),
            content: Text(dic['recovery.not.recoverable']),
            actions: <Widget>[
              CupertinoButton(
                child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel'],
                  style: TextStyle(
                    color: Theme.of(context).unselectedWidgetColor,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      _onSubmit();
    }
  }

  Future<void> _onSubmit() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final params = TxConfirmParams(
        txTitle: dic['recovery.init'],
        module: 'recovery',
        call: 'initiateRecovery',
        txDisplay: {
          'accountId': _recoverable.address,
          'deposit':
              '${Fmt.doubleFormat(_recoveryDeposit)} ${widget.service.plugin.networkState.tokenSymbol[0]}'
        },
        params: [
          _recoverable.address
        ]);

    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: params);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final symbol = widget.service.plugin.networkState.tokenSymbol[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['recovery.init']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: AddressFormItem(
                        widget.service.keyring.current,
                        label: dic['recovery.init.new'],
                        svg: widget.service.keyring.current.icon,
                      ),
                    ),
                    ListTile(
                      title: Text(dic['recovery.init.old']),
                      trailing: Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => _handleRecoverableSelect(),
                    ),
                    Visibility(
                        visible: _recoverable != null,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16, right: 16),
                          child: AddressFormItem(
                            _recoverable,
                          ),
                        )),
                    ListTile(
                      title: Text(dic['recovery.deposit']),
                      trailing: Text(
                        '${Fmt.doubleFormat(_recoveryDeposit)} $symbol',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                  text: I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['next'],
                  onPressed:
                      _recoverable != null ? () => _onValidateSubmit() : null,
                  submitting: _loading,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
