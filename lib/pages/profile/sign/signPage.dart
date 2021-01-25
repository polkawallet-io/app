import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/api/types/verifyResult.dart';
import 'package:polkawallet_sdk/webviewWithExtension/types/signExtrinsicParam.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/addressInputField.dart';
import 'package:polkawallet_ui/components/infoItemRow.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/regInputFormatter.dart';

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

  TabController _tabController;
  int _tab = 0;
  bool _submitting = false;

  KeyPairData _verifySigner;
  VerifyResult _verifyResult = VerifyResult();

  void _onSign() async {
    if (_formKey.currentState.validate()) {
      setState(() {
        _submitting = true;
      });
      final password = await widget.service.account
          .getPassword(context, widget.service.keyring.current);

      final params = SignAsExtensionParam();
      params.msgType = "pub(bytes.sign)";
      params.request = {
        "address": widget.service.keyring.current.address,
        "data": _messageCtrl.text,
      };

      final res = await widget.service.plugin.sdk.api.keyring
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
      final res = await widget.service.plugin.sdk.api.keyring.signatureVerify(
        _messageVerifyCtrl.text,
        _signatureCtrl.text,
        _verifySigner.address,
      );
      setState(() {
        _verifyResult = res;
        _submitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _verifySigner = widget.service.keyring.current;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final dicCommon = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final List<Tab> _myTabs = <Tab>[
      Tab(text: dic['sign.sign']),
      Tab(text: dic['sign.verify']),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['sign']),
      ),
      body: ListView(
        padding: EdgeInsets.only(left: 16, right: 16),
        children: [
          TabBar(
            labelColor: Colors.black87,
            labelStyle: TextStyle(fontSize: 18),
            controller: _tabController,
            tabs: _myTabs,
            onTap: (i) {
              setState(() {
                _tab = i;
              });
            },
          ),
          _tab == 0
              ? Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: AddressFormItem(
                          widget.service.keyring.current,
                          label: dicCommon['account'],
                          svg: widget.service.keyring.current.icon,
                        ),
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: '',
                          labelText: dic['sign.data'],
                        ),
                        controller: _messageCtrl,
                        inputFormatters: [
                          RegExInputFormatter.withRegex(r'^(.*)$')
                        ],
                        minLines: 1,
                        maxLines: 3,
                        validator: (v) {
                          if (v.isEmpty) {
                            return dic['sign.empty'];
                          }
                          return null;
                        },
                      ),
                      GestureDetector(
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: '',
                            labelText: dic['sign.res'],
                          ),
                          controller: _signResCtrl,
                          enabled: false,
                          minLines: 1,
                          maxLines: 3,
                        ),
                        onTap: _signResCtrl.text.isEmpty
                            ? null
                            : () =>
                                UI.copyAndNotify(context, _signResCtrl.text),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: RoundedButton(
                          text: dic['sign.sign'],
                          onPressed: _submitting ? null : _onSign,
                          icon:
                              _submitting ? CupertinoActivityIndicator() : null,
                        ),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey2,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: AddressInputField(
                          widget.service.plugin.sdk.api,
                          widget.service.keyring.allWithContacts,
                          label: dicCommon['account'],
                          initialValue:
                              _verifySigner ?? widget.service.keyring.current,
                          onChanged: (KeyPairData acc) {
                            setState(() {
                              _verifySigner = acc;
                            });
                          },
                        ),
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: '',
                          labelText: dic['sign.data'],
                        ),
                        controller: _messageVerifyCtrl,
                        inputFormatters: [
                          RegExInputFormatter.withRegex(r'^(.*)$')
                        ],
                        minLines: 1,
                        maxLines: 3,
                        validator: (v) {
                          if (v.isEmpty) {
                            return dic['sign.empty'];
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: '',
                          labelText: dic['sign.verify'],
                        ),
                        controller: _signatureCtrl,
                        inputFormatters: [
                          RegExInputFormatter.withRegex(r'^(\w*)$')
                        ],
                        minLines: 1,
                        maxLines: 3,
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
                      Container(height: 16),
                      InfoItemRow('isValid', '${_verifyResult.isValid ?? '-'}'),
                      InfoItemRow('crypto', '${_verifyResult.crypto ?? '-'}'),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: RoundedButton(
                          icon:
                              _submitting ? CupertinoActivityIndicator() : null,
                          text: dic['sign.verify'],
                          onPressed: _submitting ? null : _onVerify,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
