import 'dart:async';

import 'package:app/common/consts.dart';
import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:app/service/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdBanner extends StatefulWidget {
  AdBanner(this.service, this.connectedNode, this.changeToKusama,
      {this.canClose = false});

  final AppService service;
  final NetworkParams connectedNode;
  final bool canClose;
  final Future<void> Function() changeToKusama;

  @override
  _AdBannerState createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  bool _started = false;

  Future<void> _getCrowdLoanStarted() async {
    final res = await WalletApi.getKarCrowdLoanStarted();
    if (res != null && res['result'] && mounted) {
      setState(() {
        _started = true;
      });
    }
  }

  Future<void> _goToCrowdLoan(BuildContext context) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'public');

    if (widget.service.plugin.basic.name != 'kusama') {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text(dic['auction.switch']),
            content: Container(height: 64, child: CupertinoActivityIndicator()),
          );
        },
      );
      await widget.changeToKusama();
      Navigator.of(context).pop();
    }

    Navigator.of(context).pushNamed(KarCrowdLoanPage.route);
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
    final show = widget.connectedNode != null && _started;

    final fullWidth = MediaQuery.of(context).size.width;
    final cardColor = Theme.of(context).cardColor;
    return !show
        ? Container()
        : Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              GestureDetector(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(8),
                            child: Image.asset(
                                'assets/images/public/banner_kar_plo.png'),
                          ),
                        )
                      ],
                    ),
                    Container(
                      constraints: BoxConstraints(maxHeight: fullWidth / 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: fullWidth / 3 + 24,
                            margin:
                                EdgeInsets.only(left: 24, top: 28, right: 8),
                            child: Image.asset(
                                'assets/images/public/kar_logo.png'),
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 24, top: 8),
                            child: Text(
                              'Parachain Auction Now Live',
                              style: TextStyle(
                                  color: cardColor,
                                  height: 0.9,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                onTap: () => _goToCrowdLoan(context),
              ),
              widget.canClose
                  ? Container(
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
                    )
                  : Container()
            ],
          );
  }
}
