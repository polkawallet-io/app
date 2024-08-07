import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/create/accountAdvanceOption.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/api/types/addressIconData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/Button.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/textFormField.dart' as v3;
import 'package:polkawallet_ui/utils/i18n.dart';

import 'importAccountCreatePage.dart';

class ImportAccountFromRawSeed extends StatefulWidget {
  final AppService service;

  static const String route = '/account/importAccountFormRawSeed';

  ImportAccountFromRawSeed(this.service, {Key key}) : super(key: key);

  @override
  _ImportAccountFromRawSeedState createState() =>
      _ImportAccountFromRawSeedState();
}

class _ImportAccountFromRawSeedState extends State<ImportAccountFromRawSeed> {
  String selected;
  final TextEditingController _keyCtrl = new TextEditingController();
  AccountAdvanceOptionParams _advanceOptions = AccountAdvanceOptionParams();
  final _formKey = GlobalKey<FormState>();

  AddressIconData _addressIcon = AddressIconData();

  @override
  void dispose() {
    widget.service.store.account.resetNewAccount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context).settings.arguments as Map);
    selected = args["type"];
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final type = args['accountType'] as AccountType;
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
                                      EdgeInsets.only(left: 16.w, right: 16.w),
                                  child: AddressFormItem(
                                      KeyPairData()
                                        ..icon = _addressIcon.svg
                                        ..address = _addressIcon.address,
                                      isShowSubtitle: false))),
                          Padding(
                            padding: EdgeInsets.only(
                                left: 16.w, right: 16.w, top: 8.h),
                            child: v3.TextInputWidget(
                              decoration: v3.InputDecorationV3(
                                labelText: dic[selected],
                              ),
                              controller: _keyCtrl,
                              validator: _validateInput,
                              onChanged: (v) {
                                if (_formKey.currentState.validate()) {
                                  _refreshAccountAddress(v);
                                } else {
                                  setState(() {
                                    _addressIcon = AddressIconData();
                                  });
                                }
                              },
                            ),
                          ),
                          Visibility(
                              visible: type == AccountType.Substrate,
                              child: Container(
                                margin:
                                    EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                                child: AccountAdvanceOption(
                                  api: widget.service.plugin.sdk.api?.keyring,
                                  seed: _keyCtrl.text.trim(),
                                  onChange: (AccountAdvanceOptionParams data) {
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
              title:
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['next'],
              onPressed: () async {
                if (_formKey.currentState.validate() &&
                    !(_advanceOptions.error ?? false)) {
                  /// we should save user's key before next page
                  widget.service.store.account
                      .setNewAccountKey(_keyCtrl.text.trim());

                  Navigator.pushNamed(context, ImportAccountCreatePage.route,
                      arguments: {
                        'keyType': selected,
                        'cryptoType':
                            _advanceOptions.type ?? CryptoType.sr25519,
                        'derivePath': _advanceOptions.path ?? '',
                        ...args
                      });
                }
              },
            ),
          ),
        ],
      )),
    );
  }

  String _validateInput(String v) {
    final type = (ModalRoute.of(context).settings.arguments
        as Map)['accountType'] as AccountType;
    bool passed = false;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final input = v.trim();
    if (type == AccountType.Substrate) {
      if (input.isNotEmpty && (input.length <= 32 || input.length == 66)) {
        passed = true;
      }
    } else {
      if ((input.startsWith('0x') && input.length == 66) ||
          (!input.startsWith('0x') && input.length == 64)) {
        passed = true;
      }
    }
    return passed ? null : '${dic['import.invalid']} ${dic[selected]}';
  }

  Future<void> _refreshAccountAddress(String v) async {
    final type = (ModalRoute.of(context).settings.arguments
        as Map)['accountType'] as AccountType;
    final seed = v.trim();

    if (type == AccountType.Evm) {
      try {
        final addressInfo = await widget.service.plugin.sdk.api.eth.keyring
            .addressFromPrivateKey(privateKey: seed);
        setState(() {
          _addressIcon = addressInfo;
        });
      } catch (_) {
        setState(() {
          _addressIcon = AddressIconData();
        });
      }
    } else {
      if (seed.length <= 32 || seed.length == 66) {
        final addressInfo = await widget.service.plugin.sdk.api.keyring
            .addressFromRawSeed(widget.service.plugin.basic.ss58,
                cryptoType: _advanceOptions.type,
                derivePath: _advanceOptions.path,
                rawSeed: seed);
        setState(() {
          _addressIcon = addressInfo;
        });
      }
    }
  }
}
