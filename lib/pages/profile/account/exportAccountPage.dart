import 'dart:convert';

import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/profile/account/exportResultPage.dart';
import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/consts/settings.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

class ExportAccountPage extends StatelessWidget {
  ExportAccountPage(this.service);
  final AppService service;

  static final String route = '/profile/export';

  Future<void> _onExport(BuildContext context) async {
    final password = service.store.account.accountType == AccountType.Substrate
        ? await service.account.getPassword(
            context,
            service.keyring.current,
          )
        : await service.account
            .getEvmPassword(context, service.keyringEVM.current);
    if (password != null) {
      final seed = service.store.account.accountType == AccountType.Substrate
          ? await service.plugin.sdk.api.keyring
              .getDecryptedSeed(service.keyring, password)
          : await service.plugin.sdk.api.eth.keyring
              .getDecryptedSeed(service.keyringEVM, password);
      Navigator.of(context).pushNamed(ExportResultPage.route, arguments: seed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final dicAcc = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['export']), centerTitle: true, leading: BackBtn()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              RoundedCard(
                margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
                child: Column(
                  children: [
                    SettingsPageListItem(
                      label: dicAcc['keystore'],
                      onTap: () {
                        Map json = service.store.account.accountType ==
                                AccountType.Substrate
                            ? service.keyring.current.toJson()
                            : service.keyringEVM.current.toJson();
                        if (service.store.account.accountType ==
                            AccountType.Substrate) {
                          json.remove('name');
                          json['meta']['name'] = service.keyring.current.name;
                        }
                        json.remove('icon');
                        final data = SeedBackupData();
                        data.seed = jsonEncode(json);
                        data.type = 'keystore';
                        Navigator.of(context)
                            .pushNamed(ExportResultPage.route, arguments: data);
                      },
                    ),
                    FutureBuilder(
                      future: service.store.account.accountType ==
                              AccountType.Substrate
                          ? service.keyring.store.checkSeedExist(
                              KeyType.mnemonic, service.keyring.current.pubKey)
                          : service.keyringEVM.store.checkSeedExist(
                              EVMKeyType.mnemonic,
                              service.keyringEVM.current.address),
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Column(
                            children: [
                              Divider(height: 24.h),
                              SettingsPageListItem(
                                label: dicAcc['mnemonic'],
                                onTap: () => _onExport(context),
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                    FutureBuilder(
                      future: service.store.account.accountType ==
                              AccountType.Substrate
                          ? service.keyring.store.checkSeedExist(
                              KeyType.rawSeed, service.keyring.current.pubKey)
                          : service.keyringEVM.store.checkSeedExist(
                              EVMKeyType.privateKey,
                              service.keyringEVM.current.address),
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Column(
                            children: [
                              Divider(height: 24.h),
                              SettingsPageListItem(
                                label: service.store.account.accountType ==
                                        AccountType.Substrate
                                    ? dicAcc['rawSeed']
                                    : dicAcc['privateKey'],
                                onTap: () => _onExport(context),
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
