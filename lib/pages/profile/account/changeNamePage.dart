import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';

class ChangeNamePage extends StatefulWidget {
  ChangeNamePage(this.service);
  final AppService service;

  static final String route = '/profile/name';

  @override
  _ChangeName createState() => _ChangeName();
}

class _ChangeName extends State<ChangeNamePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = new TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nameCtrl.text =
        widget.service.plugin.basic.pluginType == PluginType.Etherem
            ? widget.service.keyringETH.current.name
            : widget.service.keyring.current.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['name.change']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: dic['contact.name'],
                          labelText: dic['contact.name'],
                        ),
                        controller: _nameCtrl,
                        validator: (v) {
                          String name = v.trim();
                          if (name.length == 0) {
                            return dic['contact.name.error'];
                          }
                          int exist = (widget.service.plugin.basic.pluginType ==
                                      PluginType.Etherem
                                  ? widget.service.keyringETH.optionals
                                  : widget.service.keyring.optionals)
                              .indexWhere((i) => i.name == name);
                          if (exist > -1) {
                            return dic['contact.name.exist'];
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
              child: RoundedButton(
                text: dic['contact.save'],
                onPressed: () {
                  if (_formKey.currentState.validate()) {
<<<<<<< HEAD
                    if (widget.service.plugin.basic.pluginType ==
=======
                    if (widget.service.plugin.pluginType ==
>>>>>>> 6d7760e (add eth(networkSelect、createAccount、changeName、changePassword、exportKeyStore、exportMnemonic、sign and signVerify))
                        PluginType.Etherem) {
                      widget.service.plugin.sdk.api.ethKeyring.changeName(
                          widget.service.keyringETH, _nameCtrl.text.trim());
                    } else {
                      widget.service.plugin.sdk.api.keyring.changeName(
                          widget.service.keyring, _nameCtrl.text.trim());
                    }
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
