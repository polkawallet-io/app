import 'dart:convert';

import 'package:app/pages/account/create/accountAdvanceOption.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ImportAccountForm extends StatefulWidget {
  ImportAccountForm(this.service, this.onSubmit);

  final AppService service;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  @override
  _ImportAccountFormState createState() => _ImportAccountFormState();
}

// TODO: add mnemonic word check & selection
class _ImportAccountFormState extends State<ImportAccountForm> {
  final _keyOptions = [
    'mnemonic',
    'rawSeed',
    'keystore',
  ];

  bool _supportBiometric = false;
  bool _enableBiometric = true; // if the biometric usage checkbox checked

  int _keySelection = 0;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _keyCtrl = new TextEditingController();
  final TextEditingController _nameCtrl = new TextEditingController();
  final TextEditingController _passCtrl = new TextEditingController();

  String _keyCtrlText = '';
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();

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

  Future<void> _authBiometric() async {
    final storeFile = await widget.service.account.getBiometricPassStoreFile(
      context,
      widget.service.keyring.current.pubKey,
    );

    try {
      await storeFile.write(widget.service.store.account.newAccount.password);
      widget.service.account
          .setBiometricEnabled(widget.service.keyring.current.pubKey);
    } catch (err) {
      // ignore
    }
  }

  Widget _buildNameAndPassInput() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: dic['create.name'],
              labelText: dic['create.name'],
            ),
            controller: _nameCtrl,
            validator: (v) {
              return v.trim().length > 0 ? null : dic['create.name.error'];
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: dic['create.password'],
              labelText: dic['create.password'],
              suffixIcon: IconButton(
                iconSize: 18,
                icon: Icon(
                  CupertinoIcons.clear_thick_circled,
                  color: Theme.of(context).unselectedWidgetColor,
                ),
                onPressed: () {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _passCtrl.clear());
                },
              ),
            ),
            controller: _passCtrl,
            obscureText: true,
            validator: (v) {
              // TODO: fix me: disable validator for polkawallet-RN exported keystore importing
              return null;
              // return v.trim().length > 0 ? null : dic['create.password.error'];
            },
          ),
        ),
        _supportBiometric
            ? Padding(
                padding: EdgeInsets.only(left: 16, top: 24),
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
                      child: Text(dic['unlock.bio.enable']),
                    )
                  ],
                ),
              )
            : Container(),
      ],
    );
  }

  String _validateInput(String v) {
    bool passed = false;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String input = v.trim();
    switch (_keySelection) {
      case 0:
        int len = input.split(' ').length;
        if (len == 12 || len == 24) {
          passed = true;
        }
        break;
      case 1:
        if (input.length <= 32 || input.length == 66) {
          passed = true;
        }
        break;
      case 2:
        try {
          jsonDecode(input);
          passed = true;
        } catch (_) {
          // ignore
        }
    }
    return passed
        ? null
        : '${dic['import.invalid']} ${dic[_keyOptions[_keySelection]]}';
  }

  void _onKeyChange(String v) {
    if (_keySelection == 2) {
      // auto set account name
      var json = jsonDecode(v.trim());
      if (json['meta']['name'] != null) {
        setState(() {
          _nameCtrl.value = TextEditingValue(text: json['meta']['name']);
        });
      }
    }
    setState(() {
      _keyCtrlText = v.trim();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAuth();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String selected = dic[_keyOptions[_keySelection]];
    return Column(
      children: <Widget>[
        Expanded(
          child: Form(
            key: _formKey,
//            autovalidate: true,
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: Text(dic['import.type']),
                  subtitle: Text(selected),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => Container(
                        height:
                            MediaQuery.of(context).copyWith().size.height / 3,
                        child: CupertinoPicker(
                          backgroundColor: Colors.white,
                          itemExtent: 56,
                          scrollController: FixedExtentScrollController(
                              initialItem: _keySelection),
                          children: _keyOptions
                              .map((i) => Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(dic[i])))
                              .toList(),
                          onSelectedItemChanged: (v) {
                            setState(() {
                              _keyCtrl.value = TextEditingValue(text: '');
                              _keySelection = v;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                _keySelection != 3
                    ? Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: selected,
                            labelText: selected,
                          ),
                          controller: _keyCtrl,
                          maxLines: 2,
                          validator: _validateInput,
                          onChanged: _onKeyChange,
                        ),
                      )
                    : Container(),
                _keySelection == 2
                    ? _buildNameAndPassInput()
                    : AccountAdvanceOption(
                        api: widget.service.plugin.sdk.api?.keyring,
                        seed: _keyCtrlText,
                        onChange: (AccountAdvanceOptionParams data) {
                          setState(() {
                            _advanceOptions = data;
                          });
                        },
                      ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: RoundedButton(
            text: I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
            onPressed: () async {
              if (_formKey.currentState.validate() &&
                  !(_advanceOptions.error ?? false)) {
                if (_keySelection == 2) {
                  widget.service.store.account.setNewAccount(
                      _nameCtrl.text.trim(), _passCtrl.text.trim());
                }
                widget.service.store.account
                    .setNewAccountKey(_keyCtrl.text.trim());
                final saved = await widget.onSubmit({
                  'keyType': _keyOptions[_keySelection],
                  'cryptoType': _advanceOptions.type ?? CryptoType.sr25519,
                  'derivePath': _advanceOptions.path ?? '',
                  'finish': _keySelection == 2 ? true : null,
                });
                if (saved) {
                  if (_supportBiometric && _enableBiometric) {
                    await _authBiometric();
                  }

                  widget.service.plugin
                      .changeAccount(widget.service.keyring.current);
                  widget.service.store.assets.loadCache(
                      widget.service.keyring.current,
                      widget.service.plugin.basic.name);
                  widget.service.store.account.resetNewAccount();
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
