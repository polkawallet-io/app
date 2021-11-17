import 'dart:async';

import 'package:app/common/consts.dart';
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
import 'package:polkawallet_ui/components/listTail.dart';
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
  int _expandedIndex = 0;

  Timer _dataQueryTimer;

  Future<void> _getCrowdLoans() async {
    if (widget.connectedNode == null) return;

    final res = await Future.wait([
      widget.service.plugin.sdk.api.parachain.queryAuctionWithWinners(),
      WalletApi.getCrowdLoansConfig(
          isKSM: widget.service.plugin.basic.name == relay_chain_name_ksm),
    ]);

    if (mounted && res[0] != null && res[1] != null) {
      widget.service.store.parachain.setAuctionData(res[0], res[1]);

      if (!_loaded) {
        setState(() {
          _loaded = true;
        });
      }

      if (widget.service.store.parachain.auctionData.funds.length > 0) {
        _getUserContributions((res[0] as AuctionData).funds);
      }
    }

    if (mounted) {
      _dataQueryTimer?.cancel();
      _dataQueryTimer = Timer(Duration(seconds: 12), _getCrowdLoans);
    }
  }

  Future<void> _getUserContributions(List<FundData> funds) async {
    final data = await widget.service.plugin.sdk.api.parachain
        .queryUserContributions(funds.map((e) => e.paraId).toList(),
            widget.service.keyring.current.pubKey);

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
    _dataQueryTimer?.cancel();

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
                names: ['Auction', 'Crowdloans'],
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
                            funds.sort((a, b) =>
                                int.parse(a.paraId) - int.parse(b.paraId));

                            final List<FundData> actives = [];
                            final List<FundData> winners = [];
                            final List<FundData> ended = [];
                            funds.forEach((e) {
                              if (e.isWinner) {
                                winners.add(e);
                              } else if (e.isEnded) {
                                ended.add(e);
                              } else {
                                actives.add(e);
                              }
                            });
                            return ListView(
                              padding: EdgeInsets.only(bottom: 40),
                              children: _tab == 0
                                  ? [
                                      auction.auction.leasePeriod != null
                                          ? AuctionPanel(
                                              auction,
                                              config,
                                              decimals,
                                              symbols,
                                              expectedBlockTime,
                                              endingPeriod)
                                          : Container(
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: ListTail(
                                                  isEmpty: true,
                                                  isLoading: false),
                                            )
                                    ]
                                  : [
                                      CrowdLoanList(
                                        title: 'Active',
                                        funds: actives,
                                        expanded: _expandedIndex == 0,
                                        config: config,
                                        contributions: contributions,
                                        decimals: decimals,
                                        tokenSymbol: symbols,
                                        onContribute: _goToContribute,
                                        onToggle: (v) {
                                          setState(() {
                                            if (v) {
                                              _expandedIndex = 0;
                                            } else {
                                              _expandedIndex = 3;
                                            }
                                          });
                                        },
                                      ),
                                      CrowdLoanList(
                                        title: 'Winners',
                                        funds: winners,
                                        expanded: _expandedIndex == 1,
                                        config: config,
                                        contributions: contributions,
                                        decimals: decimals,
                                        tokenSymbol: symbols,
                                        onContribute: _goToContribute,
                                        onToggle: (v) {
                                          setState(() {
                                            if (v) {
                                              _expandedIndex = 1;
                                            } else {
                                              _expandedIndex = 3;
                                            }
                                          });
                                        },
                                      ),
                                      CrowdLoanList(
                                        title: 'Ended',
                                        funds: ended,
                                        expanded: _expandedIndex == 2,
                                        config: config,
                                        contributions: contributions,
                                        decimals: decimals,
                                        tokenSymbol: symbols,
                                        onContribute: _goToContribute,
                                        onToggle: (v) {
                                          setState(() {
                                            if (v) {
                                              _expandedIndex = 2;
                                            } else {
                                              _expandedIndex = 3;
                                            }
                                          });
                                        },
                                      )
                                    ],
                            );
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
