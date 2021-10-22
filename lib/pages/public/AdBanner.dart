import 'dart:async';

import 'package:app/common/consts.dart';
import 'package:app/pages/profile/acalaCrowdLoan/acaCrowdLoanBanner.dart';
import 'package:app/pages/profile/crowdLoan/crowdLoanBanner.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';

class AdBanner extends StatefulWidget {
  AdBanner(this.service, this.connectedNode, this.switchNetwork,
      {this.canClose = false});

  final AppService service;
  final NetworkParams connectedNode;
  final bool canClose;
  final Future<void> Function(String) switchNetwork;

  @override
  _AdBannerState createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  Future<void> _getAdBannerStatus() async {
    final res = await WalletApi.getAdBannerStatus();
    widget.service.store.settings.setAdBannerState(res);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAdBannerStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // return Observer(builder: (_) {
    if (widget.connectedNode == null) {
      return Container();
    }
    final visible = widget.service.buildTarget == BuildTargets.dev
        ? true
        : (widget.service.store.settings.adBannerState['visibleAca'] ?? false);
    if (!visible) {
      final network = widget.service.plugin.basic.name;
      if (network == relay_chain_name_ksm) {
        return KarCrowdLoanBanner();
      }
      return Container();
    }

    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        ACACrowdLoanBanner(widget.service, widget.switchNetwork),
        Visibility(
          visible: widget.canClose,
          child: Container(
            padding: EdgeInsets.only(top: 12, right: 12),
            child: GestureDetector(
              child: Icon(
                Icons.cancel,
                color: Colors.white60,
                size: 16,
              ),
              onTap: () {
                widget.service.store.storage
                    .write(show_banner_status_key, 'closed');
                widget.service.store.account.setBannerVisible(false);
              },
            ),
          ),
        )
      ],
    );
    // });
  }
}
