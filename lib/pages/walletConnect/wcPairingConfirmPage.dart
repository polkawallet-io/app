import 'dart:convert';

import 'package:app/common/components/jumpToLink.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';

class WCPairingConfirmPageParams {
  WCPairingConfirmPageParams({this.pairingData, this.peerMeta});
  final WCProposerMeta peerMeta;
  final WCPairingData pairingData;
}

class WCPairingConfirmPage extends StatelessWidget {
  const WCPairingConfirmPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static String route = '/wc/pairing';

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    final WCPairingConfirmPageParams args =
        ModalRoute.of(context).settings.arguments;
    final WCProposerMeta peerMeta = args.pairingData == null
        ? args.peerMeta
        : args.pairingData.params.proposer.metadata;
    // TODO: fix this page to implement wallet-connect
    // final permissions = List.of(args.permissions.jsonrpc['methods']);

    return Scaffold(
      appBar: AppBar(
          title: Image.asset('assets/images/wallet_connect_banner.png',
              height: 20),
          centerTitle: true,
          leading: const BackBtn()),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        dic['wc.connect'],
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            .copyWith(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: WCPairingSourceInfoDetail(peerMeta),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        dic['wc.permission'],
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            .copyWith(fontSize: 16),
                      ),
                    ),
                    args.pairingData == null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                dic['wc.permission.address'],
                                dic['wc.permission.req']
                              ].map((e) {
                                return Text('- $e');
                              }).toList(),
                            ),
                          )
                        : WCPairingPermissions(
                            args.pairingData.params.requiredNamespaces,
                            args.pairingData.params.expiry)
                  ]),
            ),
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 8),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                JumpToLink(
                  'https://walletconnect.com/',
                  text: dic['wc.service'],
                  color: Theme.of(context).disabledColor,
                ),
              ]),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                    child: Button(
                      isBlueBg: false,
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        dic['wc.reject'],
                        style: const TextStyle(color: PluginColorsDark.primary),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                    child: Button(
                      child: Text(
                        dic['wc.approve'],
                        style: TextStyle(
                            color: UI.isDarkTheme(context)
                                ? Colors.black
                                : Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WCPairingSourceInfoDetail extends StatelessWidget {
  const WCPairingSourceInfoDetail(this.metadata, {Key key}) : super(key: key);
  final WCProposerMeta metadata;
  @override
  Widget build(BuildContext context) {
    return metadata != null
        ? Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Image.network(metadata.icons[0], width: 64),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Text(metadata.name,
                    style: Theme.of(context).textTheme.displaySmall),
              ),
              Text(
                metadata.url,
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
              Text(
                metadata.description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          )
        : Container();
  }
}

class WCPairingPermissions extends StatelessWidget {
  const WCPairingPermissions(this.namespaces, this.expiry, {Key key})
      : super(key: key);
  final Map<String, WCPermissionNamespaces> namespaces;
  final int expiry;
  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Column(
      children: namespaces.keys.map((chain) {
        final permission = namespaces[chain];
        return RoundedCard(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: UI.isDarkTheme(context)
              ? Colors.orangeAccent.shade400
              : Colors.orangeAccent.shade100,
          child: Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chain.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        .copyWith(fontSize: 16),
                  ),
                  Text(
                    'Methods',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        .copyWith(fontSize: 14),
                  ),
                  Text(
                    jsonEncode(permission.methods),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        .copyWith(fontWeight: FontWeight.normal),
                  ),
                  Text(
                    'Events',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        .copyWith(fontSize: 14),
                  ),
                  Text(
                    jsonEncode(permission.events),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        .copyWith(fontWeight: FontWeight.normal),
                  ),
                  Text(
                    dic['wc.expiry'],
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        .copyWith(fontSize: 14),
                  ),
                  Text(
                    Fmt.dateTime(
                        DateTime.fromMillisecondsSinceEpoch(expiry * 1000)),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        .copyWith(fontWeight: FontWeight.normal),
                  )
                ],
              ))
            ],
          ),
        );
      }).toList(),
    );
  }
}
