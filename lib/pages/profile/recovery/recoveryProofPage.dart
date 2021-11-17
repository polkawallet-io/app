import 'dart:convert';

import 'package:app/common/components/txList.dart';
import 'package:app/pages/profile/recovery/vouchRecoveryPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/txData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/roundedButton.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class RecoveryProofPage extends StatefulWidget {
  RecoveryProofPage(this.service);
  static final String route = '/profile/recovery/proof';
  final AppService service;

  @override
  _RecoveryStatePage createState() => _RecoveryStatePage();
}

class _RecoveryStatePage extends State<RecoveryProofPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  List<TxData> _txs = [];
  bool _loading = false;

  Future<void> _fetchData() async {
    final res = await widget.service.subScan.fetchTxsAsync(
      widget.service.subScan.moduleRecovery,
      call: 'vouch_recovery',
      sender: widget.service.keyring.current.address,
    );
    if (res['extrinsics'] == null) return;

    final txs = List.of(res['extrinsics']);
    if (txs.length > 0) {
      List<TxData> ls = txs.map((e) => TxData.fromJson(e)).toList();
      List<String> pubKeys = [];
      ls.forEach((i) {
        pubKeys.addAll(List.of(jsonDecode(i.params)).map((e) => e['value']));
      });

      final pubKeyAddressMap =
          await widget.service.plugin.sdk.api.account.encodeAddress(pubKeys);
      widget.service.store.account.setPubKeyAddressMap(Map<String, Map>.from(
          {'${widget.service.plugin.basic.ss58}': pubKeyAddressMap}));

      setState(() {
        _txs = ls;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['recovery.help']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16, top: 16),
                child: BorderedTitle(
                  title: dic['recovery.history'],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchData,
                  key: _refreshKey,
                  child: _txs.length > 0
                      ? TxList(_txs)
                      : ListView(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(I18n.of(context).getDic(
                                  i18n_full_dic_ui, 'common')['list.empty']),
                            )
                          ],
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                  text: dic['recovery.help'],
                  onPressed: () async {
                    final res = await Navigator.of(context)
                        .pushNamed(VouchRecoveryPage.route);
                    if (res != null) {
                      _refreshKey.currentState.show();
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
