import 'package:app/pages/profile/account/signPage.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:app/pages/profile/account/changeNamePage.dart';
import 'package:app/pages/profile/account/changePasswordPage.dart';
import 'package:app/pages/profile/account/exportAccountPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/passwordInputDialog.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AccountManagePage extends StatefulWidget {
  AccountManagePage(this.service);
  final AppService service;

  static final String route = '/profile/account';

  @override
  _AccountManagePageState createState() => _AccountManagePageState();
}

class _AccountManagePageState extends State<AccountManagePage> {
  bool _supportBiometric = false; // if device support biometric
  bool _isBiometricAuthorized = false; // if user authorized biometric usage
  BiometricStorageFile _authStorage;

  Future<void> _onDeleteAccount(BuildContext context) async {
    final password = await widget.service.account
        .getPassword(context, widget.service.keyring.current);
    if (password != null) {
      widget.service.plugin.sdk.api.keyring
          .deleteAccount(widget.service.keyring, widget.service.keyring.current)
          .then((_) {
        // refresh balance
        widget.service.plugin.changeAccount(widget.service.keyring.current);

        widget.service.store.assets.loadCache(
            widget.service.keyring.current, widget.service.plugin.basic.name);
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateBiometricAuth(bool enable) async {
    print('enable: $enable');
    final pubKey = widget.service.keyring.current.pubKey;
    final password = await showCupertinoDialog(
      context: context,
      builder: (_) {
        return PasswordInputDialog(
          widget.service.plugin.sdk.api,
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_app, 'account')['unlock']),
          account: widget.service.keyring.current,
        );
      },
    );
    if (password == null) return;

    bool result = !enable;
    if (enable) {
      try {
        print('write: $password');
        await _authStorage.write(password);
        print('setBiometricEnabled');
        widget.service.account.setBiometricEnabled(pubKey);
        result = enable;
      } catch (err) {
        print(err);
        // user may cancel the biometric auth. then we set biometric disabled
        widget.service.account.setBiometricDisabled(pubKey);
      }
    } else {
      widget.service.account.setBiometricDisabled(pubKey);
      result = enable;
    }

    if (result == enable) {
      setState(() {
        _isBiometricAuthorized = enable;
      });
    }
  }

  Future<void> _checkBiometricAuth() async {
    final response = await BiometricStorage().canAuthenticate();
    final supportBiometric = response == CanAuthenticateResponse.success;
    print(response);
    if (!supportBiometric) {
      return;
    }
    setState(() {
      _supportBiometric = supportBiometric;
    });
    final pubKey = widget.service.keyring.current.pubKey;
    final storeFile =
        await widget.service.account.getBiometricPassStoreFile(context, pubKey);
    final isAuthorized = widget.service.account.getBiometricEnabled(pubKey);
    setState(() {
      _isBiometricAuthorized = isAuthorized;
      _authStorage = storeFile;
    });
  }

  Future<void> _onChangePass() async {
    final res = await Navigator.pushNamed(context, ChangePasswordPage.route);
    // refresh biometric auth status after password changed
    if (res ?? false) {
      _checkBiometricAuth();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    final acc = widget.service.keyring.current;

    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['account']),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: <Widget>[
                  Container(
                    color: primaryColor,
                    padding: EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: AddressIcon(
                        acc.address,
                        svg: acc.icon,
                      ),
                      title: Text(acc.name ?? 'name',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      subtitle: Text(
                        Fmt.address(acc.address) ?? '',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                  ),
                  Container(padding: EdgeInsets.only(top: 16)),
                  ListTile(
                    title: Text(dic['name.change']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () async {
                      await Navigator.pushNamed(context, ChangeNamePage.route);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    title: Text(dic['pass.change']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => _onChangePass(),
                  ),
                  ListTile(
                    title: Text(dic['sign']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.of(context).pushNamed(SignMessagePage.route);
                    },
                  ),
                  ListTile(
                    title: Text(dic['export']),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => Navigator.of(context)
                        .pushNamed(ExportAccountPage.route),
                  ),
                  Visibility(
                      visible: _supportBiometric,
                      child: ListTile(
                        title: Text(I18n.of(context).getDic(
                            i18n_full_dic_app, 'account')['unlock.bio.enable']),
                        trailing: CupertinoSwitch(
                          value: _isBiometricAuthorized,
                          onChanged: (v) {
                            if (v != _isBiometricAuthorized) {
                              _updateBiometricAuth(v);
                            }
                          },
                        ),
                      )),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.all(16)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white)),
                    child: Text(
                      dic['delete'],
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => _onDeleteAccount(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
