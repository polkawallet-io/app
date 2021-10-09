import 'package:app/pages/account/create/accountAdvanceOption.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

import 'importAccountCreatePage.dart';

class ImportAccountFromRawSeed extends StatefulWidget {
  final AppService service;

  static final String route = '/account/importAccountFormRawSeed';

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

  @override
  void dispose() {
    widget.service.store.account.resetNewAccount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    selected = (ModalRoute.of(context).settings.arguments as Map)["type"];
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(title: Text(dic['import']), centerTitle: true),
      body: SafeArea(
          child: Observer(
              builder: (_) => Column(
                    children: [
                      Expanded(
                          child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                  child: Column(
                                children: [
                                  Visibility(
                                      visible: widget.service.store.account
                                              .newAccount.icon?.isNotEmpty ??
                                          false,
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 16, right: 16, top: 16),
                                          child: AddressFormItem(
                                              KeyPairData()
                                                ..pubKey = widget.service.store
                                                    .account.newAccount.key
                                                ..icon = widget.service.store
                                                    .account.newAccount.icon
                                                ..address = widget.service.store
                                                    .account.newAccount.address,
                                              isShowSubtitle: false))),
                                  ListTile(
                                      title: Text(
                                        dic['import.type'],
                                      ),
                                      trailing: Text(dic[selected])),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 16, right: 16),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        hintText: dic[selected],
                                        labelText: dic[selected],
                                      ),
                                      controller: _keyCtrl,
                                      maxLines: 2,
                                      validator: _validateInput,
                                      onChanged: _onKeyChange,
                                    ),
                                  ),
                                  AccountAdvanceOption(
                                    api: widget.service.plugin.sdk.api?.keyring,
                                    seed: _keyCtrl.text.trim(),
                                    onChange:
                                        (AccountAdvanceOptionParams data) {
                                      setState(() {
                                        _advanceOptions = data;
                                      });

                                      _refreshAcccountAddress();
                                    },
                                  ),
                                ],
                              )))),
                      Container(
                        padding: EdgeInsets.all(16),
                        child: RoundedButton(
                          text: I18n.of(context)
                              .getDic(i18n_full_dic_ui, 'common')['next'],
                          onPressed: () async {
                            if (_formKey.currentState.validate() &&
                                !(_advanceOptions.error ?? false)) {
                              Navigator.pushNamed(
                                  context, ImportAccountCreatePage.route,
                                  arguments: {
                                    'keyType': selected,
                                    // 'cryptoType': _advanceOptions.type ??
                                    //     CryptoType.sr25519,
                                    // 'derivePath': _advanceOptions.path ?? '',
                                  });
                            }
                          },
                        ),
                      ),
                    ],
                  ))),
    );
  }

  String _validateInput(String v) {
    bool passed = false;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String input = v.trim();
    if (input.length <= 32 || input.length == 66) {
      passed = true;
    }
    return passed ? null : '${dic['import.invalid']} ${dic[selected]}';
  }

  void _onKeyChange(String v) {
    _refreshAcccountAddress();
  }

  void _refreshAcccountAddress() {
    widget.service.account.addressFromRawSeed(
        rawSeed: _keyCtrl.text.trim(),
        type: _advanceOptions.type,
        path: _advanceOptions.path);
  }
}
