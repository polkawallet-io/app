import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/textFormField.dart' as v3;

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
    _nameCtrl.text = widget.service.keyring.current.name;
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
          leading: BackBtn(
            onBack: () => Navigator.of(context).pop(),
          )),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Form(
                    key: _formKey,
                    child: v3.TextFormField(
                      decoration: v3.InputDecorationV3(
                        labelText: dic['contact.name'],
                        labelStyle: Theme.of(context).textTheme.headline4,
                      ),
                      controller: _nameCtrl,
                      validator: (v) {
                        String name = v.trim();
                        if (name.length == 0) {
                          return dic['contact.name.error'];
                        }
                        int exist = widget.service.keyring.optionals
                            .indexWhere((i) => i.name == name);
                        if (exist > -1) {
                          return dic['contact.name.exist'];
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(14.w, 16.h, 12.w, 16.h),
              child: Button(
                title: dic['contact.save'],
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    widget.service.plugin.sdk.api.keyring.changeName(
                        widget.service.keyring, _nameCtrl.text.trim());
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
