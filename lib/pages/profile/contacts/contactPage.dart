import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/components/tapTooltip.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ContactPage extends StatefulWidget {
  ContactPage(this.service);
  final AppService service;

  static final String route = '/profile/contact';

  @override
  _Contact createState() => _Contact();
}

class _Contact extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _addressCtrl = new TextEditingController();
  final TextEditingController _nameCtrl = new TextEditingController();
  final TextEditingController _memoCtrl = new TextEditingController();

  bool _isObservation = false;

  KeyPairData _args;

  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _args = ModalRoute.of(context).settings.arguments;
    if (_args != null) {
      _addressCtrl.text = _args.address;
      _nameCtrl.text = _args.name;
      _memoCtrl.text = _args.memo;
      _isObservation = _args.observation;
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState.validate()) {
      setState(() {
        _submitting = true;
      });
      final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
      final address = _addressCtrl.text.trim();
      Map<String, dynamic> con = {
        'address': address,
        'name': _nameCtrl.text,
        'memo': _memoCtrl.text,
        'observation': _isObservation
      };
      if (_args == null) {
        // create new contact
        int exist = widget.service.keyring.contacts
            .indexWhere((i) => i.address == address);
        if (exist > -1) {
          showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return CupertinoAlertDialog(
                title: Container(),
                content: Text(dic['contact.exist']),
                actions: <Widget>[
                  CupertinoButton(
                    child: Text(I18n.of(context)
                        .getDic(i18n_full_dic_ui, 'common')['ok']),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
          setState(() {
            _submitting = false;
          });
          return;
        } else {
          final res = await widget.service.plugin.sdk.api.keyring
              .addContact(widget.service.keyring, con);

          if (_isObservation) {
            widget.service.plugin.changeAccount(res);
            widget.service.store.assets
                .loadCache(res, widget.service.plugin.basic.name);
          }
        }
      } else {
        // edit contact
        con['pubKey'] = _args.pubKey;
        await widget.service.keyring.store.updateContact(con);
        // if the contact being edited was current account
        // and was set not observable, we should reset current account.
        if (_args.pubKey == widget.service.keyring.store.currentPubKey &&
            _args.observation &&
            !_isObservation) {
          if (widget.service.keyring.allAccounts.length > 0) {
            widget.service.keyring
                .setCurrent(widget.service.keyring.allAccounts[0]);
            widget.service.plugin
                .changeAccount(widget.service.keyring.allAccounts[0]);
          } else {
            widget.service.keyring.setCurrent(KeyPairData());
          }
        }
      }

      setState(() {
        _submitting = false;
      });
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    List<Widget> action = <Widget>[
      IconButton(
        icon: SvgPicture.asset(
          'assets/images/scan.svg',
          color: Theme.of(context).cardColor,
          width: 24,
        ),
        onPressed: () async {
          final to = await Navigator.of(context).pushNamed(ScanPage.route);
          if (to != null) {
            setState(() {
              _addressCtrl.text = (to as QRCodeResult).address.address;
              _nameCtrl.text = (to as QRCodeResult).address.name;
            });
          }
        },
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['contact']),
        centerTitle: true,
        actions: _args == null ? action : null,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: dic['contact.address'],
                          labelText: dic['contact.address'],
                        ),
                        controller: _addressCtrl,
                        validator: (v) {
                          if (!Fmt.isAddress(v.trim())) {
                            return dic['contact.address.error'];
                          }
                          return null;
                        },
                        readOnly: _args != null,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: dic['contact.name'],
                          labelText: dic['contact.name'],
                        ),
                        controller: _nameCtrl,
                        validator: (v) {
                          return v.trim().length > 0
                              ? null
                              : dic['contact.name.error'];
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: dic['contact.memo'],
                          labelText: dic['contact.memo'],
                        ),
                        controller: _memoCtrl,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Checkbox(
                          value: _isObservation,
                          onChanged: (v) {
                            setState(() {
                              _isObservation = v;
                            });
                          },
                        ),
                        GestureDetector(
                          child: Text(I18n.of(context)
                              .getDic(i18n_full_dic_app, 'account')['observe']),
                          onTap: () {
                            setState(() {
                              _isObservation = !_isObservation;
                            });
                          },
                        ),
                        TapTooltip(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.info_outline, size: 16),
                          ),
                          message: I18n.of(context).getDic(
                              i18n_full_dic_app, 'account')['observe.brief'],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
              child: RoundedButton(
                submitting: _submitting,
                text: dic['contact.save'],
                onPressed: () => _onSave(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
