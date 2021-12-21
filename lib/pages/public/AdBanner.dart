import 'dart:async';

import 'package:app/app.dart';
import 'package:app/common/consts.dart';
import 'package:app/pages/profile/crowdLoan/crowdLoanBanner.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    var res = await WalletApi.getAdBannerStatus();
    widget.service.store.settings.setAdBannerState(res);

    widget.service.store.settings.claimState =
        await WalletApi.getClaim(widget.service.keyring.current.address);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAdBannerStatus();
    });
  }

  List<Widget> crowdLoanBannerList() {
    final widgets = <Widget>[];
    if ((widget.service.store.settings.adBannerState['visibleKar'] ?? false) &&
        widget.service.plugin.basic.name == relay_chain_name_ksm) {
      widgets.add(KarCrowdLoanBanner());
    }

    if ((widget.service.store.settings.adBannerState['visibleAca'] ?? false) &&
        widget.service.plugin.basic.name == relay_chain_name_dot) {
      widgets.add(ACACrowdLoanBanner());
    }

    // if ((widget.service.store.settings.adBannerState['visibleQuests'] ??
    //     false)) {
    //   widgets.add(GeneralCrowdLoanBanner(
    //       'assets/images/public/banner_aca_quests.png',
    //       'https://acala.network/acala/quests#quests'));
    // }

    if ((widget.service.store.settings.adBannerState['visibleClaim'] ??
            false) &&
        ((widget.service.store.settings.claimState['result'] == true &&
                widget.service.store.settings.claimState['claimed'] == false &&
                widget.service.store.settings.claimState['originClaimed'] ==
                    false) ||
            WalletApp.buildTarget == BuildTargets.dev)) {
      widgets.add(GeneralCrowdLoanBanner(
          'assets/images/public/banner_aca_claim.png',
          'https://distribution.acala.network/claim'));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // return Observer(builder: (_) {
    if (widget.connectedNode == null) {
      return Container();
    }
    var widgets = crowdLoanBannerList();
    if (widgets.length == 0) {
      return Container();
    }

    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        widgets.length == 1
            ? widgets[0]
            : Container(
                height: (MediaQuery.of(context).size.width - 32.w) / 340.0 * 55,
                width: double.infinity,
                padding: EdgeInsets.zero,
                child: Swiper(
                  itemCount: widgets.length,
                  itemWidth: double.infinity,
                  autoplay: true,
                  itemBuilder: (BuildContext context, int index) {
                    return widgets[index];
                  },
                  pagination: SwiperPagination(margin: EdgeInsets.zero),
                ),
              ),
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
