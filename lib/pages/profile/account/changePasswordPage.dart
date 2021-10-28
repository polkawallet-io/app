import 'package:biometric_storage/biometric_storage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/format.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ChangePasswordPage extends StatefulWidget {
  ChangePasswordPage(this.service);
  final AppService service;

  static final String route = '/profile/password';

  @override
  _ChangePassword createState() => _ChangePassword();
}

class _ChangePassword extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passCtrl = new TextEditingController();
  final TextEditingController _pass2Ctrl = new TextEditingController();

  bool _submitting = false;

  bool _supportBiometric = false; // if device support biometric
  bool _enableBiometric = true; // if the biometric usage checkbox checked

  Future<void> _doChangePass(String passOld) async {
    setState(() {
      _submitting = true;
    });
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final String passNew = _passCtrl.text.trim();

    await widget.service.plugin.sdk.api.keyring
        .changePassword(widget.service.keyring, passOld, passNew);

    final pubKey = widget.service.keyring.current.pubKey;
    if (_enableBiometric) {
      final storeFile = await widget.service.account
          .getBiometricPassStoreFile(context, pubKey);
      storeFile.write(passNew);

      widget.service.account.setBiometricEnabled(pubKey);
    } else {
      widget.service.account.setBiometricDisabled(pubKey);
    }

    setState(() {
      _submitting = false;
    });
    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: Text(dic['pass.success']),
          content: Text(dic['pass.success.txt']),
          actions: <Widget>[
            CupertinoButton(
              child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSave() async {
    if (_formKey.currentState.validate()) {
      final password = await widget.service.account.getPassword(
        context,
        widget.service.keyring.current,
      );
      if (password != null) {
        _doChangePass(password);
      }
    }
  }

  Future<void> _checkBiometricSupport() async {
    final canAuth = await BiometricStorage().canAuthenticate();

    setState(() {
      _supportBiometric = canAuth == CanAuthenticateResponse.success;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricSupport();
    });
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    var accDic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['pass.change']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          child: Text(
                            dic['pass.forget'],
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline),
                          ),
                          onTap: () {
                            showCupertinoDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CupertinoAlertDialog(
                                  title: Text(dic['pass.reset']),
                                  content: Text(dic['pass.reset.text']),
                                  actions: <Widget>[
                                    CupertinoButton(
                                      child: Text(I18n.of(context).getDic(
                                          i18n_full_dic_ui, 'common')['ok']),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock),
                        hintText: dic['pass.new'],
                        labelText: dic['pass.new'],
                      ),
                      controller: _passCtrl,
                      validator: (v) {
                        return AppFmt.checkPassword(v.trim())
                            ? null
                            : accDic['create.password.error'];
                      },
                      obscureText: true,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock),
                        hintText: dic['pass.new2'],
                        labelText: dic['pass.new2'],
                      ),
                      controller: _pass2Ctrl,
                      validator: (v) {
                        return v.trim() != _passCtrl.text
                            ? accDic['create.password2.error']
                            : null;
                      },
                      obscureText: true,
                    ),
                    Visibility(
                        visible: _supportBiometric,
                        child: Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _enableBiometric,
                                  onChanged: (v) {
                                    setState(() {
                                      _enableBiometric = v;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(accDic['unlock.bio.enable']),
                              )
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
              child: RoundedButton(
                text: dic['contact.save'],
                icon: _submitting ? CupertinoActivityIndicator() : null,
                onPressed: _submitting ? null : _onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
