import 'dart:convert';

import 'package:app/pages/profile/account/exportResultPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/passwordInputDialog.dart';

import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';

class ExportAccountPage extends StatelessWidget {
  ExportAccountPage(this.service);
  final AppService service;

  static final String route = '/profile/export';

  Future<void> _onExport(BuildContext context) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PasswordInputDialog(
          service.plugin.sdk.api,
          title: Text(dic['delete.confirm']),
          account: service.keyring.current,
          onOk: (password) async {
            final seed = await service.plugin.sdk.api.keyring
                .getDecryptedSeed(service.keyring, password);
            Navigator.of(context)
                .pushNamed(ExportResultPage.route, arguments: seed);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final dicAcc = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(title: Text(dic['export']), centerTitle: true),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(dicAcc['keystore']),
            trailing: Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Map json = service.keyring.current.toJson();
              json.remove('name');
              json['meta']['name'] = service.keyring.current.name;
              json.remove('icon');
              final data = SeedBackupData();
              data.seed = jsonEncode(json);
              data.type = 'keystore';
              Navigator.of(context)
                  .pushNamed(ExportResultPage.route, arguments: data);
            },
          ),
          FutureBuilder(
            future: service.keyring.store.checkSeedExist(
                KeyType.mnemonic, service.keyring.current.pubKey),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ListTile(
                  title: Text(dicAcc['mnemonic']),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _onExport(context),
                );
              } else {
                return Container();
              }
            },
          ),
          FutureBuilder(
            future: service.keyring.store.checkSeedExist(
                KeyType.rawSeed, service.keyring.current.pubKey),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ListTile(
                  title: Text(dicAcc['rawSeed']),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _onExport(context),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}
