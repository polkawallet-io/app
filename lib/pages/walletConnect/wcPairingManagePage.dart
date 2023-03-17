import 'dart:convert';

import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/walletConnect/pairingData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/listTail.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/ethSignRequestInfo.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class WCPairingManagePage extends StatefulWidget {
  const WCPairingManagePage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static const String route = '/wc/pairing/manage';

  @override
  WCPairingManagePageState createState() => WCPairingManagePageState();
}

class WCPairingManagePageState extends State<WCPairingManagePage> {
  List<WCSessionDataV2> _pairings = [];

  void _loadPairings() {
    final data = widget.service.store.storage
        .read(widget.service.store.account.localStorageWCSessionV2Key);
    if (data != null && data['pairing'] != null) {
      setState(() {
        _pairings = List.of(jsonDecode(data['pairing']))
            .map((e) => WCSessionDataV2.fromJson(Map<String, dynamic>.of({
                  'topic': e['topic'],
                  'peerMeta': e['peerMetadata'],
                })))
            .toList();
      });
    }
  }

  Future<void> _onDelete(WCSessionDataV2 pairing) async {
    final confirmed = await showCupertinoModalPopup(
        context: context,
        builder: (_) {
          return PolkawalletAlertDialog(
            content: Text(
                '${I18n.of(context).getDic(i18n_full_dic_app, 'account')['wc.pairing.delete']}${pairing.peerMeta.name}?'),
            actions: [
              PolkawalletActionSheetAction(
                  child: Text(
                    I18n.of(context)
                        .getDic(i18n_full_dic_ui, 'common')['cancel'],
                    style: TextStyle(
                        color: Theme.of(context).unselectedWidgetColor),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  }),
              PolkawalletActionSheetAction(
                  isDefaultAction: true,
                  child: Text(I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['ok']),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  })
            ],
          );
        });
    if (confirmed) {
      widget.service.wc.deletePairingV2(pairing.topic);
      _loadPairings();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadPairings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');

    return Scaffold(
      appBar: AppBar(
          title: Text(dic['wc.pairing']),
          centerTitle: true,
          leading: const BackBtn()),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _pairings.isEmpty
              ? ListTail(isEmpty: true, isLoading: false)
              : ListView.builder(
                  itemCount: _pairings.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          dic['wc.pairing.info'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }
                    return RoundedCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: WCPairingSourceInfo(_pairings[i - 1].peerMeta,
                          trailing: GestureDetector(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: PluginColorsDark.primary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              child: const Icon(
                                Icons.delete_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            onTap: () => _onDelete(_pairings[i - 1]),
                          )),
                    );
                  }),
        ),
      ),
    );
  }
}
