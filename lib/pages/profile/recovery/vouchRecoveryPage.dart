import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/txButton.dart';
import 'package:polkawallet_ui/pages/accountListPage.dart';
import 'package:polkawallet_ui/pages/txConfirmPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class VouchRecoveryPage extends StatefulWidget {
  VouchRecoveryPage(this.service);
  final AppService service;
  static final String route = '/profile/recovery/vouch';

  @override
  _VouchRecoveryPage createState() => _VouchRecoveryPage();
}

class _VouchRecoveryPage extends State<VouchRecoveryPage> {
  final TextEditingController _addressOldCtrl = new TextEditingController();
  final TextEditingController _addressNewCtrl = new TextEditingController();

  bool _loading = false;

  Future<void> _onValidateSubmit() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    setState(() {
      _loading = true;
    });
    String addressOld = _addressOldCtrl.text.trim();
    String addressNew = _addressNewCtrl.text.trim();
    String address;
    String errorMsg;

    /// check if old account is recoverable
    var info = await widget.service.account
        .queryRecoverable(_addressOldCtrl.text.trim());
    if (info == null) {
      address = addressOld;
      errorMsg = dic['recovery.not.recoverable'];
    } else {
      /// check if there is an active recovery for new account
      info = (await widget.service.plugin.sdk.api.recovery
          .queryActiveRecoveryAttempts(
        _addressOldCtrl.text.trim(),
        [_addressNewCtrl.text.trim()],
      ))[0];
      if (info == null) {
        address = addressNew;
        errorMsg = dic['recovery.no.active'];
      }
    }

    setState(() {
      _loading = false;
    });

    if (errorMsg != null) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(Fmt.address(address)),
            content: Text(errorMsg),
            actions: <Widget>[
              CupertinoButton(
                child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel'],
                  style: TextStyle(
                    color: Theme.of(context).unselectedWidgetColor,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      _onSubmit(addressOld, addressNew);
    }
  }

  Future<void> _onSubmit(String addressOld, String addressNew) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final args = TxConfirmParams(
        txTitle: dic['recovery.help'],
        module: 'recovery',
        call: 'vouchRecovery',
        txDisplay: {
          'lost': addressOld,
          'rescuer': addressNew,
        },
        params: [
          addressOld,
          addressNew
        ]);
    final res = await Navigator.of(context)
        .pushNamed(TxConfirmPage.route, arguments: args);
    if (res != null) {
      Navigator.of(context).pop(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final primary = Theme.of(context).primaryColor;
    final grey = Theme.of(context).disabledColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['recovery.help']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: dic['recovery.help.old'],
                        labelText: dic['recovery.help.old'],
                        suffix: GestureDetector(
                          child:
                              Icon(Icons.people_outline, color: grey, size: 22),
                          onTap: () async {
                            var to = await Navigator.of(context).pushNamed(
                              AccountListPage.route,
                              arguments: AccountListPageParams(
                                  title: I18n.of(context).getDic(
                                      i18n_full_dic_app, 'profile')['contact'],
                                  list: widget.service.keyring.allWithContacts),
                            );
                            if (to != null) {
                              setState(() {
                                _addressOldCtrl.text =
                                    (to as KeyPairData).address;
                              });
                            }
                          },
                        ),
                      ),
                      controller: _addressOldCtrl,
                      validator: (v) {
                        return Fmt.isAddress(v.trim())
                            ? null
                            : dic['address.error'];
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: dic['recovery.help.new'],
                        labelText: dic['recovery.help.new'],
                        suffix: GestureDetector(
                          child:
                              Icon(Icons.people_outline, color: grey, size: 22),
                          onTap: () async {
                            var to = await Navigator.of(context).pushNamed(
                              AccountListPage.route,
                              arguments: AccountListPageParams(
                                  title: I18n.of(context).getDic(
                                      i18n_full_dic_app, 'profile')['contact'],
                                  list: widget.service.keyring.allWithContacts),
                            );
                            ;
                            if (to != null) {
                              setState(() {
                                _addressNewCtrl.text =
                                    (to as KeyPairData).address;
                              });
                            }
                          },
                        ),
                      ),
                      controller: _addressNewCtrl,
                      validator: (v) {
                        return Fmt.isAddress(v.trim())
                            ? null
                            : dic['address.error'];
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                  text: I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['next'],
                  onPressed: () => _onValidateSubmit(),
                  submitting: _loading,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
