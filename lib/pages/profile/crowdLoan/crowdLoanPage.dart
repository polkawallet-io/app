import 'dart:async';

import 'package:app/pages/profile/crowdLoan/auctionPanel.dart';
import 'package:app/pages/profile/crowdLoan/contributePage.dart';
import 'package:app/pages/profile/crowdLoan/crowdLoanList.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/api/types/parachain/auctionData.dart';
import 'package:polkawallet_sdk/api/types/parachain/fundData.dart';
import 'package:polkawallet_ui/components/pageTitleTaps.dart';
import 'package:polkawallet_ui/ui.dart';

class CrowdLoanPage extends StatefulWidget {
  CrowdLoanPage(this.service, this.connectedNode);
  final AppService service;
  final NetworkParams connectedNode;

  static final String route = '/profile/crowd/loan';

  @override
  _CrowdLoanPageState createState() => _CrowdLoanPageState();
}

class _CrowdLoanPageState extends State<CrowdLoanPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  bool _loaded = false;
  int _tab = 0;

  Timer _dataQueryTimer;

  Future<void> _getCrowdLoans() async {
    if (widget.connectedNode == null) return;

    final res = await Future.wait([
      widget.service.plugin.sdk.api.parachain.queryAuctionWithWinners(),
      WalletApi.getKSMCrowdLoansConfig(),
    ]);

    if (mounted && res[0] != null && res[1] != null) {
      widget.service.store.parachain.setAuctionData(res[0], res[1]);

      if (!_loaded) {
        setState(() {
          _loaded = true;
        });
      }

      _getUserContributions((res[0] as AuctionData).funds);
    }

    if (mounted) {
      _dataQueryTimer = Timer(Duration(seconds: 6), _getCrowdLoans);
    }
  }

  Future<void> _getUserContributions(List<FundData> funds) async {
    final data = await Future.wait(funds.map((e) =>
        widget.service.plugin.sdk.api.parachain.queryUserContributions(
            e.paraId, widget.service.keyring.current.pubKey)));

    if (mounted && data != null) {
      final res = {};
      data.asMap().forEach((k, v) {
        res[funds[k].paraId] = v;
      });
      widget.service.store.parachain.setUserContributions(res);
    }
  }

  Future<void> _goToContribute(FundData fund) async {
    final res = await Navigator.of(context)
        .pushNamed(ContributePage.route, arguments: fund);
    if (res != null) {
      _refreshKey.currentState.show();
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCrowdLoans();
    });
  }

  @override
  void dispose() {
    if (_dataQueryTimer != null) {
      _dataQueryTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final symbols =
        (widget.service.plugin.networkState.tokenSymbol ?? ['KSM'])[0];
    final expectedBlockTime = int.parse(widget
        .service.plugin.networkConst['babe']['expectedBlockTime']
        .toString());
    final endingPeriod = int.parse(widget
        .service.plugin.networkConst['auctions']['endingPeriod']
        .toString());

    final cardColor = Theme.of(context).cardColor;
    final grayColor = Theme.of(context).unselectedWidgetColor;
    final titleStyle =
        TextStyle(color: grayColor, fontSize: 20, fontWeight: FontWeight.bold);
    final textStyleSmall = TextStyle(fontSize: 12);

    return Scaffold(
      body: PageWrapperWithBackground(
        SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white))
                ],
              ),
              PageTitleTabs(
                names: ['Auctions', 'Crowdloans'],
                activeTab: _tab,
                onTab: (i) {
                  if (_tab != i) {
                    setState(() {
                      _tab = i;
                    });
                  }
                },
              ),
              Expanded(
                child: _loaded
                    ? RefreshIndicator(
                        key: _refreshKey,
                        onRefresh: _getCrowdLoans,
                        child: Observer(
                          builder: (_) {
                            final auction =
                                widget.service.store.parachain.auctionData;
                            final config =
                                widget.service.store.parachain.fundsVisible;
                            final contributions = widget
                                .service.store.parachain.userContributions;
                            final funds = auction.funds?.toList() ?? [];
                            final visibleFundIds = [];
                            config.forEach((k, v) {
                              if (v['visible'] ?? false) {
                                visibleFundIds.add(k);
                              }
                            });
                            funds.retainWhere(
                                (e) => visibleFundIds.indexOf(e.paraId) > -1);
                            return _tab == 0
                                ? ListView(
                                    children: [
                                      AuctionPanel(
                                          auction,
                                          config,
                                          decimals,
                                          symbols,
                                          expectedBlockTime,
                                          endingPeriod)
                                    ],
                                  )
                                : CrowdLoanList(funds, config, contributions,
                                    decimals, symbols, _goToContribute);
                          },
                        ),
                      )
                    : Center(
                        child: CupertinoActivityIndicator(),
                      ),
              )
            ],
          ),
        ),
        height: 220,
        backgroundImage: widget.service.plugin.basic.backgroundImage,
      ),
    );
  }
}
