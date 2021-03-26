import 'package:app/pages/profile/aboutPage.dart';
import 'package:app/pages/profile/account/accountManagePage.dart';
import 'package:app/pages/profile/contacts/contactsPage.dart';
import 'package:app/pages/profile/recovery/recoveryProofPage.dart';
import 'package:app/pages/profile/recovery/recoverySettingPage.dart';
import 'package:app/pages/profile/recovery/recoveryStatePage.dart';
import 'package:app/pages/profile/settings/settingsPage.dart';
import 'package:app/pages/public/AdBanner.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage(this.service, this.connectedNode);

  final AppService service;
  final NetworkParams connectedNode;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  KeyPairData _currentAccount;

  void _showRecoveryMenu(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            child: Text(dic['recovery.make']),
            onPressed: () {
              Navigator.of(context).popAndPushNamed(RecoverySettingPage.route);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(dic['recovery.init']),
            onPressed: () {
              Navigator.of(context).popAndPushNamed(RecoveryStatePage.route);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(dic['recovery.help']),
            onPressed: () {
              Navigator.of(context).popAndPushNamed(RecoveryProofPage.route);
            },
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['cancel']),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dic =
        I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final Color grey = Theme.of(context).unselectedWidgetColor;
    final acc = widget.service.keyring.current;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['title']),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: ListView(
        children: <Widget>[
          Container(
            color: primaryColor,
            padding: EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: AddressIcon(acc.address, svg: acc.icon),
              title: Text(UI.accountName(context, acc),
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              subtitle: Text(
                Fmt.address(acc.address) ?? '',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
          widget.service.plugin.basic.name.contains('acala')
              ? AdBanner()
              : Container(),
          !(acc.observation ?? false)
              ? Container(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RoundedButton(
                        text: dic['account'],
                        onPressed: () async {
                          await Navigator.pushNamed(
                              context, AccountManagePage.route);
                          setState(() {
                            _currentAccount = widget.service.keyring.current;
                          });
                        },
                      )
                    ],
                  ),
                )
              : Container(height: 24),
          ListTile(
            leading: Container(
              width: 32,
              child: Icon(Icons.people_outline, color: grey, size: 22),
            ),
            title: Text(dic['contact']),
            trailing: Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () async {
              await Navigator.of(context).pushNamed(ContactsPage.route);
              setState(() {
                _currentAccount = widget.service.keyring.current;
              });
            },
          ),
          widget.service.plugin.recoveryEnabled
              ? ListTile(
                  leading: Container(
                    width: 32,
                    child: Icon(Icons.security, color: grey, size: 22),
                  ),
                  title: Text(dic['recovery']),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: widget.connectedNode == null
                      ? null
                      : () => _showRecoveryMenu(context),
                )
              : Container(),
          ListTile(
            leading: Container(
              width: 32,
              child: Icon(Icons.settings, color: grey, size: 22),
            ),
            title: Text(dic['setting']),
            trailing: Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () => Navigator.of(context).pushNamed(SettingsPage.route),
          ),
          ListTile(
            leading: Container(
              width: 32,
              child: Icon(Icons.info_outline, color: grey, size: 22),
            ),
            title: Text(dic['about']),
            trailing: Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () => Navigator.of(context).pushNamed(AboutPage.route),
          ),
        ],
      ),
    );
  }
}
