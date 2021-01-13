import 'package:app/pages/profile/contacts/contactPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class ContactsPage extends StatefulWidget {
  ContactsPage(this.service);

  final AppService service;

  static final String route = '/profile/contacts';

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<KeyPairData> _list = [];

  void _refreshData() {
    setState(() {
      _list = widget.service.keyring.contacts;
    });
  }

  void _showActions(BuildContext pageContext, KeyPairData i) {
    final dic = I18n.of(pageContext).getDic(i18n_full_dic_ui, 'common');
    showCupertinoModalPopup(
      context: pageContext,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Text(
              dic['edit'],
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await Navigator.of(context)
                  .pushNamed(ContactPage.route, arguments: i);
              _refreshData();
            },
          ),
          CupertinoActionSheetAction(
            child: Text(
              dic['delete'],
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _removeItem(pageContext, i);
            },
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(dic['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _removeItem(BuildContext context, KeyPairData i) {
    var dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(I18n.of(context)
              .getDic(i18n_full_dic_app, 'profile')['contact.delete.warn']),
          content: Text(UI.accountName(context, i)),
          actions: <Widget>[
            CupertinoButton(
              child: Text(dic['cancel']),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoButton(
              child: Text(dic['ok']),
              onPressed: () async {
                Navigator.of(context).pop();
                await widget.service.keyring.store.deleteContact(i.pubKey);
                if (i.observation &&
                    widget.service.keyring.store.currentPubKey == i.pubKey) {
                  if (widget.service.keyring.allAccounts.length > 0) {
                    widget.service.keyring
                        .setCurrent(widget.service.keyring.allAccounts[0]);

                    widget.service.plugin
                        .changeAccount(widget.service.keyring.allAccounts[0]);
                  } else {
                    widget.service.keyring.setCurrent(KeyPairData());
                  }
                }
                _refreshData();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _list = widget.service.keyring.contacts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            I18n.of(context).getDic(i18n_full_dic_app, 'profile')['contact']),
        centerTitle: true,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.add, size: 28),
              onPressed: () async {
                await Navigator.of(context).pushNamed(ContactPage.route);
                _refreshData();
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (_) {
            return ListView(
              children: _list.map((i) {
                return ListTile(
                  leading: AddressIcon(i.address, svg: i.icon),
                  title: Text(UI.accountName(context, i)),
                  subtitle: Text(Fmt.address(i.address)),
                  trailing: Container(
                    width: 36,
                    child: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () => _showActions(context, i),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
