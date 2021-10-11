import 'package:app/service/index.dart';
import 'package:app/utils/UI.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ImportAccountAction {
  static Future<void> authBiometric(
      BuildContext context, AppService service) async {
    final storeFile = await service.account.getBiometricPassStoreFile(
      context,
      service.keyring.current.pubKey,
    );

    try {
      await storeFile.write(service.store.account.newAccount.password);
      service.account.setBiometricEnabled(service.keyring.current.pubKey);
    } catch (err) {
      // ignore
    }
  }

  static Future<bool> onSubmit(
      BuildContext context,
      AppService service,
      Map<String, dynamic> data,
      Function(bool submitting) obSubmittingChang) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');

    final _keyType = KeyType.values
        .firstWhere((e) => e.toString().contains(data['keyType']));
    final _cryptoType = data['cryptoType'] ?? CryptoType.sr25519;
    final _derivePath = data['derivePath'] ?? "";

    obSubmittingChang(true);
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
      var acc = await service.account.importAccount(
        keyType: _keyType,
        cryptoType: _cryptoType,
        derivePath: _derivePath,
      );
      if (acc == null) {
        obSubmittingChang(false);
        Navigator.of(context).pop();

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
      final duplicated =
          await _checkAccountDuplicate(context, service, acc['pubKey']);
      // _checkAccountDuplicate always return false because account
      // was imported and duplicated account was updated.
      if (!duplicated) {
        await service.account.addAccount(
          json: acc,
          keyType: _keyType,
          cryptoType: _cryptoType,
          derivePath: _derivePath,
        );
        service.account.setBiometricDisabled(acc['pubKey']);
      }
      obSubmittingChang(false);
      Navigator.of(context).pop();
      return !duplicated;
    } on Exception catch (err) {
      Navigator.of(context).pop();
      obSubmittingChang(false);
      if (err.toString().contains('Invalid')) {
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
                    Navigator.of(context).pop();
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
            Navigator.of(context).pop();
          },
          isImport: true,
        );
      }
      return false;
    }
  }

  static Future<bool> _checkAccountDuplicate(
      BuildContext context, AppService service, String pubKey) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final index =
        service.keyring.keyPairs.indexWhere((i) => i.pubKey == pubKey);
    if (index > -1) {
      final duplicate = await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(Fmt.address(service.keyring.keyPairs[index].address)),
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
      return duplicate ?? false;
    }
    return false;
  }
}
