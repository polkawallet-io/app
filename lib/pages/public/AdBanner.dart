import 'dart:async';

import 'package:app/common/consts.dart';
import 'package:app/pages/profile/acalaCrowdLoan/acalaCrowdLoanPage.dart';
import 'package:app/pages/profile/crowdLoan/crowdLoanBanner.dart';
import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:app/pages/public/karCrowdLoanWaitPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_kusama/common/constants.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

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
  Map _started = {
    'visible': false,
    'started': false,
  };

  Future<void> _getCrowdLoanStarted() async {
    final res = await WalletApi.getKarCrowdLoanStarted();
    if (res != null && mounted) {
      setState(() {
        _started = res;
      });
    }
  }

  Future<void> _goToCrowdLoan(BuildContext context) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');

    // if (_started['started'] || widget.service.buildTarget == BuildTargets.dev) {
    if (widget.service.plugin.basic.name != network_name_polkadot) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(dic['auction.switch']),
            content: Container(height: 64, child: CupertinoActivityIndicator()),
          );
        },
      );
      await widget.switchNetwork(network_name_polkadot);
      Navigator.of(context).pop();
    }
    //   Navigator.of(context)
    //       .pushNamed(KarCrowdLoanPage.route, arguments: _started['endpoint']);
    // } else {
    //   Navigator.of(context).pushNamed(KarCrowdLoanWaitPage.route);
    // }

    Navigator.of(context).pushNamed(AcalaCrowdLoanPage.route);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCrowdLoanStarted();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final show = widget.connectedNode != null && _started['visible'];
    final show = true;

    // final fullWidth = MediaQuery.of(context).size.width;
    // final cardColor = Theme.of(context).cardColor;
    return !show
        ? CrowdLoanBanner(widget.service, widget.connectedNode)
        : Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child:
                      Image.asset("assets/images/public/banner_acala_pol.png"),
                ),
                onTap: () => _goToCrowdLoan(context),
              )
            ],
          );
    // : Stack(
    //     alignment: AlignmentDirectional.topEnd,
    //     children: [
    //       GestureDetector(
    //         child: Stack(
    //           children: [
    //             Row(
    //               children: [
    //                 Expanded(
    //                   child: Container(
    //                     margin: EdgeInsets.all(8),
    //                     child: Image.asset(
    //                         'assets/images/public/banner_kar_plo.png'),
    //                   ),
    //                 )
    //               ],
    //             ),
    //             Container(
    //               constraints: BoxConstraints(maxHeight: fullWidth / 4),
    //               child: Column(
    //                 crossAxisAlignment: CrossAxisAlignment.start,
    //                 children: [
    //                   Container(
    //                     width: fullWidth / 3 + 24,
    //                     height: 32,
    //                     margin:
    //                         EdgeInsets.only(left: 16, top: 24, right: 8),
    //                     // child: Image.asset(
    //                     //     'assets/images/public/kar_logo.png'),
    //                     child: SvgPicture.asset(
    //                         'assets/images/public/kusama_logo.svg'),
    //                   ),
    //                   Container(
    //                     margin: EdgeInsets.only(left: 24, top: 8),
    //                     child: Text(
    //                       'Parachain Auction',
    //                       style: TextStyle(
    //                           color: cardColor,
    //                           height: 0.9,
    //                           fontSize: 22,
    //                           fontWeight: FontWeight.bold),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             )
    //           ],
    //         ),
    //         onTap: () => _goToCrowdLoan(context),
    //       ),
    //       Visibility(
    //           visible: widget.canClose,
    //           child: Container(
    //             padding: EdgeInsets.only(top: 12, right: 12),
    //             child: GestureDetector(
    //               child: Icon(
    //                 Icons.cancel,
    //                 color: Colors.white60,
    //                 size: 16,
    //               ),
    //               onTap: () {
    //                 widget.service.store.storage
    //                     .write(show_banner_status_key, 'closed');
    //                 widget.service.store.account.setBannerVisible(false);
    //               },
    //             ),
    //           ))
    //     ],
    //   );
  }
}
