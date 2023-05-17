import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/types/verifyResult.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/mainTabBar.dart';
import 'package:polkawallet_ui/components/v3/textFormField.dart' as v3;
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class SignMessagePage extends StatefulWidget {
  const SignMessagePage(this.service);

  static final String route = '/profile/sign';
  final AppService service;

  @override
  _SignMessagePageState createState() => _SignMessagePageState();
}

class _SignMessagePageState extends State<SignMessagePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final TextEditingController _messageCtrl = new TextEditingController();
  final TextEditingController _signResCtrl = new TextEditingController();
  final TextEditingController _messageVerifyCtrl = new TextEditingController();
  final TextEditingController _signatureCtrl = new TextEditingController();

  int _tab = 0;
  bool _submitting = false;

  KeyPairData _verifySigner;
  VerifyResult _verifyResult = VerifyResult();

  void _onSign() async {
    if (_formKey.currentState.validate()) {
      setState(() {
        _submitting = true;
      });
      final password =
          widget.service.store.account.accountType == AccountType.Evm
              ? await widget.service.account
                  .getEvmPassword(context, widget.service.keyringEVM.current)
              : await widget.service.account
                  .getPassword(context, widget.service.keyring.current);

      final params = SignAsExtensionParam();
      params.msgType = "pub(bytes.sign)";
      params.request = {
        "address": widget.service.keyring.current.address,
        "data": _messageCtrl.text,
      };

      final res = widget.service.store.account.accountType == AccountType.Evm
          ? await widget.service.plugin.sdk.api.eth.keyring.signMessage(
              password,
              _messageCtrl.text,
              widget.service.keyringEVM.current.address)
          : await widget.service.plugin.sdk.api.keyring
              .signAsExtension(password, params);
      setState(() {
        _signResCtrl.text = res.signature;
        _submitting = false;
      });
    }
  }

  void _onVerify() async {
    if (_formKey2.currentState.validate()) {
      setState(() {
        _submitting = true;
      });
      VerifyResult res = VerifyResult()..isValid = false;
      if (widget.service.store.account.accountType == AccountType.Evm) {
        try {
          var resData =
              await widget.service.plugin.sdk.api.eth.keyring.signatureVerify(
            _messageVerifyCtrl.text.trim(),
            _signatureCtrl.text.trim(),
          );
          if (resData['signer'] == _verifySigner.address) {
            res.isValid = true;
          }
        } catch (_) {}
      } else {
        res = await widget.service.plugin.sdk.api.keyring.signatureVerify(
          _messageVerifyCtrl.text.trim(),
          _signatureCtrl.text.trim(),
          _verifySigner.address,
        );
      }
      setState(() {
        _verifyResult = res;
        _submitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _verifySigner =
            widget.service.store.account.accountType == AccountType.Evm
                ? widget.service.keyringEVM.current.toKeyPairData()
                : widget.service.keyring.current;
      });
    });
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    _messageCtrl.dispose();
    _messageVerifyCtrl.dispose();
    _signResCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['sign']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                child: MainTabBar(
                  tabs: {dic['sign.sign']: false, dic['sign.verify']: false},
                  activeTab: _tab,
                  onTap: (i) {
                    setState(() {
                      _tab = i;
                    });
                  },
                ),
              ),
              Visibility(
                visible: _tab == 0,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                        child: AddressFormItem(
                          widget.service.store.account.accountType ==
                                  AccountType.Evm
                              ? widget.service.keyringEVM.current
                              : widget.service.keyring.current,
                          label: dicCommon['submit.signer'],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: v3.TextInputWidget(
                          decoration: v3.InputDecorationV3(
                            labelText: dic['sign.data'],
                            labelStyle: Theme.of(context).textTheme.headline4,
                          ),
                          controller: _messageCtrl,
                          validator: (v) {
                            if (v.isEmpty) {
                              return dic['sign.empty'];
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: GestureDetector(
                          child: v3.TextInputWidget(
                            decoration: v3.InputDecorationV3(
                              labelText: dic['sign.res'],
                              labelStyle: Theme.of(context).textTheme.headline4,
                            ),
                            controller: _signResCtrl,
                            enabled: false,
                            maxLines: 3,
                          ),
                          onTap: _signResCtrl.text.isEmpty
                              ? null
                              : () =>
                                  UI.copyAndNotify(context, _signResCtrl.text),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(14.w, 24.h, 12.w, 24.h),
                        child: Button(
                          title: dic['sign.sign'],
                          onPressed: _onSign,
                          submitting: _submitting,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: _tab == 1,
                child: Form(
                  key: _formKey2,
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                        child: AddressTextFormField(
                          widget.service.plugin.sdk.api,
                          widget.service.keyring.allWithContacts,
                          localEthAccounts:
                              widget.service.store.account.accountType ==
                                      AccountType.Evm
                                  ? widget.service.keyringEVM.allWithContacts
                                  : null,
                          labelText: dicCommon['submit.signer'],
                          hintText: dicCommon['submit.signer'],
                          initialValue:
                              _verifySigner ?? widget.service.keyring.current,
                          onChanged: (KeyPairData acc) {
                            setState(() {
                              _verifySigner = acc;
                            });
                          },
                          key: ValueKey<KeyPairData>(_verifySigner),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: v3.TextInputWidget(
                          decoration: v3.InputDecorationV3(
                            labelText: dic['sign.data'],
                            labelStyle: Theme.of(context).textTheme.headline4,
                          ),
                          controller: _messageVerifyCtrl,
                          validator: (v) {
                            if (v.isEmpty) {
                              return dic['sign.empty'];
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: v3.TextInputWidget(
                          decoration: v3.InputDecorationV3(
                            labelText: dic['sign.verify'],
                            labelStyle: Theme.of(context).textTheme.headline4,
                          ),
                          controller: _signatureCtrl,
                          validator: (v) {
                            if (v.isEmpty) {
                              return dic['sign.empty'];
                            }
                            if (v.length < 130 || v.substring(0, 2) != '0x') {
                              return dic['input.invalid'];
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(14.w, 16.h, 12.w, 0),
                        child: InfoItemRow(
                            'isValid', '${_verifyResult.isValid ?? '-'}'),
                      ),
                      Visibility(
                          visible: _verifyResult.crypto != null,
                          child: Container(
                            margin: EdgeInsets.fromLTRB(14.w, 4.h, 12.w, 0),
                            child: InfoItemRow(
                                'crypto', '${_verifyResult.crypto ?? '-'}'),
                          )),
                      Container(
                        margin: EdgeInsets.fromLTRB(14.w, 16.h, 12.w, 24.h),
                        child: Button(
                          submitting: _submitting,
                          title: dic['sign.verify'],
                          onPressed: _onVerify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
