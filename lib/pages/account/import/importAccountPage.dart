import 'package:app/pages/account/create/createAccountForm.dart';
import 'package:app/pages/account/import/importAccountForm.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

import 'package:polkawallet_sdk/api/apiKeyring.dart';

class ImportAccountPage extends StatefulWidget {
  const ImportAccountPage(this.service);
  final AppService service;

  static final String route = '/account/import';

  @override
  _ImportAccountPageState createState() => _ImportAccountPageState();
}

class _ImportAccountPageState extends State<ImportAccountPage> {
  int _step = 0;
  KeyType _keyType = KeyType.mnemonic;
  CryptoType _cryptoType = CryptoType.sr25519;
  String _derivePath = '';
  bool _submitting = false;

  Future<bool> _importAccount() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    setState(() {
      _submitting = true;
    });
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(dicCommon['loading']),
          content: Container(height: 64, child: CupertinoActivityIndicator()),
        );
      },
    );

    try {
      /// import account
      var acc = await widget.service.account.importAccount(
        keyType: _keyType,
        cryptoType: _cryptoType,
        derivePath: _derivePath,
      );
      if (acc == null) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Container(),
              content:
                  Text('${dic['import.invalid']} ${dic['create.password']}'),
              actions: <Widget>[
                CupertinoButton(
                  child: Text(I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['cancel']),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        return false;
      }

      /// check if account duplicate
      final duplicated = await _checkAccountDuplicate(acc['pubKey']);
      if (!duplicated) {
        await widget.service.account.addAccount(
          json: acc,
          keyType: _keyType,
          cryptoType: _cryptoType,
          derivePath: _derivePath,
        );
        widget.service.account.setBiometricDisabled(acc['pubKey']);
      }
      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
      return !duplicated;
    } on Exception catch (err) {
      Navigator.of(context).pop();
      setState(() {
        _submitting = false;
      });
      if (err.toString().contains('unreachable')) {
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Container(),
              content: Text(
                  '${dic['import.invalid']} ${dic[_keyType.toString().split('.')[1]]}'),
              actions: <Widget>[
                CupertinoButton(
                  child: Text(dicCommon['ok']),
                  onPressed: () {
                    setState(() {
                      _step = 0;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        await AppUI.alertWASM(
          context,
          () {
            setState(() {
              _step = 0;
            });
          },
          isImport: true,
        );
      }
      return false;
    }
  }

  Future<bool> _checkAccountDuplicate(String pubKey) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final index =
        widget.service.keyring.keyPairs.indexWhere((i) => i.pubKey == pubKey);
    if (index > -1) {
      final duplicate = await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(
                Fmt.address(widget.service.keyring.keyPairs[index].address)),
            content: Text(dic['import.duplicate']),
            actions: <Widget>[
              // CupertinoButton(
              //   child: Text(dicCommon['cancel']),
              //   onPressed: () => Navigator.of(context).pop(true),
              // ),
              CupertinoButton(
                child: Text(dicCommon['ok']),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          );
        },
      );
      return duplicate;
    }
    return false;
  }

  Future<bool> _onNext(Map<String, dynamic> data) async {
    final keyType = KeyType.values
        .firstWhere((e) => e.toString().contains(data['keyType']));
    if (data['finish'] == null) {
      setState(() {
        _keyType = keyType;
        _cryptoType = data['cryptoType'];
        _derivePath = data['derivePath'];
        _step = 1;
      });
      return false;
    } else {
      setState(() {
        _keyType = keyType;
        _cryptoType = data['cryptoType'];
        _derivePath = data['derivePath'];
      });
      final saved = await _importAccount();
      return saved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    if (_step == 1) {
      return Scaffold(
        appBar: AppBar(
          title: Text(dic['import']),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _step = 0;
              });
            },
          ),
        ),
        body: SafeArea(
          child: CreateAccountForm(
            widget.service,
            submitting: _submitting,
            onSubmit: _importAccount,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(dic['import'])),
      body: SafeArea(
        child: ImportAccountForm(widget.service, _onNext),
      ),
    );
  }
}
