import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/create/accountAdvanceOption.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/Button.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/textFormField.dart' as v3;
import 'package:polkawallet_ui/utils/i18n.dart';

import 'importAccountCreatePage.dart';

class ImportAccountFormMnemonic extends StatefulWidget {
  final AppService service;

  static final String route = '/account/importAccountFormMnemonic';

  ImportAccountFormMnemonic(this.service, {Key key}) : super(key: key);

  @override
  _ImportAccountFormMnemonicState createState() =>
      _ImportAccountFormMnemonicState();
}

class _ImportAccountFormMnemonicState extends State<ImportAccountFormMnemonic> {
  String selected;
  final TextEditingController _keyCtrl = new TextEditingController();
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();
  final _formKey = GlobalKey<FormState>();

  bool _validating = false;
  AddressIconData _addressIcon = AddressIconData();

  @override
  void dispose() {
    widget.service.store.account.resetNewAccount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = (ModalRoute.of(context).settings.arguments as Map);
    selected = data["type"];
    final type = data['accountType'] as AccountType;
    final needChange = data["needChange"];
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
        appBar: AppBar(
            title: Text(dic['import']), centerTitle: true, leading: BackBtn()),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                  child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Visibility(
                                  visible: _addressIcon.svg != null,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.only(left: 16, right: 16),
                                      child: AddressFormItem(
                                          KeyPairData()
                                            ..icon = _addressIcon.svg
                                            ..address = _addressIcon.address,
                                          isShowSubtitle: false))),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 16, right: 16, top: 8.h),
                                child: v3.TextInputWidget(
                                  decoration: v3.InputDecorationV3(
                                    labelText: dic[selected],
                                  ),
                                  controller: _keyCtrl,
                                  maxLines: 3,
                                  validator: _validateInput,
                                  onChanged: _onKeyChange,
                                ),
                              ),
                              Visibility(
                                  visible: type == AccountType.Substrate,
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(
                                        16.w, 16.h, 16.w, 16.h),
                                    child: AccountAdvanceOption(
                                      api: widget
                                          .service.plugin.sdk.api?.keyring,
                                      seed: _keyCtrl.text.trim(),
                                      onChange:
                                          (AccountAdvanceOptionParams data) {
                                        setState(() {
                                          _advanceOptions = data;
                                        });

                                        _refreshAccountAddress(_keyCtrl.text);
                                      },
                                    ),
                                  )),
                            ],
                          )))),
              Container(
                padding: EdgeInsets.all(16),
                child: Button(
                  title: I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['next'],
                  onPressed: () async {
                    if (_formKey.currentState.validate() &&
                        !(_advanceOptions.error ?? false)) {
                      if (!(await _validateMnemonic())) return;

                      /// we should save user's key before next page
                      widget.service.store.account
                          .setNewAccountKey(_keyCtrl.text.trim());

                      Navigator.pushNamed(
                          context, ImportAccountCreatePage.route,
                          arguments: {
                            'keyType': selected,
                            'cryptoType':
                                _advanceOptions.type ?? CryptoType.sr25519,
                            'derivePath': _advanceOptions.path ?? '',
                            "accountType": type,
                            "needChange": needChange
                          });
                    }
                  },
                ),
              ),
            ],
          ),
        ));
  }

  String _validateInput(String v) {
    bool passed = false;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String input = v.trim();
    int len = input.split(' ').length;
    if (len >= 12) {
      passed = true;
    }
    return passed ? null : '${dic['import.invalid']} ${dic[selected]}';
  }

  Future<bool> _validateMnemonic() async {
    if (_validating) return false;

    setState(() {
      _validating = true;
    });
    final input = _keyCtrl.text.trim();
    final res =
        await widget.service.plugin.sdk.api.keyring.checkMnemonicValid(input);
    if (!res) {
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return PolkawalletAlertDialog(
            title: Text(dic['import.warn']),
            content: Text(dic['mnemonic.msg']),
            actions: [
              PolkawalletActionSheetAction(
                child: Text(dic['mnemonic.btn']),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _keyCtrl.text = "";
                  });
                },
              ),
            ],
          );
        },
      );
    }
    setState(() {
      _validating = false;
    });
    return res;
  }

  void _onKeyChange(String v) {
    _refreshAccountAddress(v);
  }

  Future<void> _refreshAccountAddress(String v) async {
    final type = (ModalRoute.of(context).settings.arguments
        as Map)['accountType'] as AccountType;
    final mnemonic = v.trim();

    if (mnemonic.split(" ").length >= 12) {
      final addressInfo = type == AccountType.Substrate
          ? await widget.service.plugin.sdk.api.keyring.addressFromMnemonic(
              widget.service.plugin.basic.ss58,
              cryptoType: _advanceOptions.type,
              derivePath: _advanceOptions.path,
              mnemonic: mnemonic)
          : await widget.service.plugin.sdk.api.eth.keyring.addressFromMnemonic(
              derivePath: "m/44'/60'/0'/0/0", mnemonic: mnemonic);
      setState(() {
        _addressIcon = addressInfo;
      });
    }
  }
}
