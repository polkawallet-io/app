import 'package:app/pages/account/import/importAccountAction.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/format.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/Button.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/utils/i18n.dart';

class CreateAccountForm extends StatefulWidget {
  CreateAccountForm(this.service, {this.submitting, this.onSubmit});

  final AppService service;
  final Future<bool> Function() onSubmit;
  final bool submitting;

  @override
  _CreateAccountFormState createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = new TextEditingController();
  final TextEditingController _passCtrl = new TextEditingController();
  final TextEditingController _pass2Ctrl = new TextEditingController();

  bool _supportBiometric = false;
  bool _enableBiometric = true; // if the biometric usage checkbox checked

  Future<void> _checkBiometricAuth() async {
    final response = await BiometricStorage().canAuthenticate();
    final supportBiometric = response == CanAuthenticateResponse.success;
    if (!supportBiometric) {
      return;
    }
    setState(() {
      _supportBiometric = supportBiometric;
    });
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState.validate()) {
      widget.service.store.account
          .setNewAccount(_nameCtrl.text, _passCtrl.text);
      final success = await widget.onSubmit();

      if (success) {
        /// save password with biometrics after import success
        if (_supportBiometric && _enableBiometric) {
          await ImportAccountAction.authBiometric(context, widget.service);
        }

        widget.service.plugin.changeAccount(widget.service.keyring.current);
        widget.service.store.account.resetNewAccount();
        widget.service.store.account.setAccountCreated();
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAuth();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 8.h),
                  child: v3.TextInputWidget(
                    decoration: v3.InputDecorationV3(
                      labelText: dic['create.name'],
                    ),
                    controller: _nameCtrl,
                    validator: (v) {
                      return v.trim().length > 0
                          ? null
                          : dic['create.name.error'];
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 16.h),
                  child: v3.TextInputWidget(
                    decoration: v3.InputDecorationV3(
                      labelText: dic['create.password'],
                    ),
                    controller: _passCtrl,
                    validator: (v) {
                      return AppFmt.checkPassword(v.trim())
                          ? null
                          : dic['create.password.error'];
                    },
                    obscureText: true,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 16.h),
                  child: v3.TextInputWidget(
                    decoration: v3.InputDecorationV3(
                      labelText: dic['create.password2'],
                    ),
                    controller: _pass2Ctrl,
                    obscureText: true,
                    validator: (v) {
                      return _passCtrl.text != v
                          ? dic['create.password2.error']
                          : null;
                    },
                  ),
                ),
                Visibility(
                    visible: _supportBiometric,
                    child: Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: v3.Checkbox(
                              value: _enableBiometric,
                              onChanged: (v) {
                                setState(() {
                                  _enableBiometric = v;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: Text(dic['unlock.bio.enable']),
                          )
                        ],
                      ),
                    )),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Button(
              title:
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
              submitting: widget.submitting,
              onPressed: _onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
