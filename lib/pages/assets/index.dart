import 'dart:async';

import 'package:app/common/components/CustomRefreshIndicator.dart';
import 'package:app/common/consts.dart';
import 'package:app/pages/assets/announcementPage.dart';
import 'package:app/pages/assets/asset/assetPage.dart';
import 'package:app/pages/assets/manage/manageAssetsPage.dart';
import 'package:app/pages/assets/nodeSelectPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/pages/public/AdBanner.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/InstrumentWidget.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:rive/rive.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(
    this.service,
    this.plugins,
    this.changeNode,
    this.connectedNode,
    this.checkJSCodeUpdate,
    this.switchNetwork,
    this.handleWalletConnect,
  );

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;
  final Future<void> Function(String) switchNetwork;
  final Future<void> Function(String) handleWalletConnect;

  final List<PolkawalletPlugin> plugins;
  final Future<void> Function(NetworkParams) changeNode;

  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetsPage> {
  final GlobalKey<CustomRefreshIndicatorState> _refreshKey =
      new GlobalKey<CustomRefreshIndicatorState>();
  bool _refreshing = false;

  List _announcements;

  Timer _priceUpdateTimer;

  int instrumentIndex = 0;

  Future<void> _updateBalances() async {
    setState(() {
      _refreshing = true;
    });
    await widget.service.plugin.updateBalances(widget.service.keyring.current);
    setState(() {
      _refreshing = false;
    });
  }

  Future<dynamic> _fetchAnnouncements() async {
    final res = await WalletApi.getAnnouncements();
    if (res == null) return;

    _announcements = res;
    var index = _announcements.indexWhere((element) {
      return element["plugin"] == widget.service.plugin.basic.name;
    });
    if (index == -1) {
      final i =
          _announcements.indexWhere((element) => element["plugin"] == "all");
      return i == -1 ? null : _announcements[i];
    } else {
      return _announcements[index];
    }
  }

  Future<void> _updateMarketPrices() async {
    if (widget.service.plugin.balances.tokens.length > 0) {
      widget.service.assets.fetchMarketPrices(
          widget.service.plugin.balances.tokens.map((e) => e.symbol).toList());
    }

    _priceUpdateTimer = Timer(Duration(seconds: 60), _updateMarketPrices);
  }

  Future<void> _handleScan(bool transferEnabled) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = (await Navigator.pushNamed(
      context,
      ScanPage.route,
      arguments: 'tx',
    )) as QRCodeResult;
    if (data != null) {
      if (data.type == QRCodeResultType.rawData &&
          data.rawData.substring(0, 3) == 'wc:') {
        widget.handleWalletConnect(data.rawData);
        return;
      }

      if (transferEnabled && data.type == QRCodeResultType.address) {
        Navigator.of(context).pushNamed(
          TransferPage.route,
          arguments: TransferPageParams(address: data.address.address),
        );
        return;
      }

      if (widget.service.keyring.current.observation ?? false) {
        showCupertinoDialog(
          context: context,
          builder: (_) {
            return CupertinoAlertDialog(
              title: Text(dic['uos.title']),
              content: Text(dic['uos.acc.invalid']),
              actions: <Widget>[
                CupertinoButton(
                  child: Text(I18n.of(context)
                      .getDic(i18n_full_dic_ui, 'common')['ok']),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
        return;
      }

      showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            content: Column(
              children: [
                Text(dic['uos.parse']),
                Container(
                  margin: EdgeInsets.only(top: 16.h),
                  child: CupertinoActivityIndicator(),
                )
              ],
            ),
          );
        },
      );

      String errorMsg;
      KeyPairData sender;
      try {
        final senderPubKey = await widget.service.plugin.sdk.api.uos
            .parseQrCode(
                widget.service.keyring, data.rawData.toString().trim());
        Navigator.of(context).pop();

        if (senderPubKey == widget.service.keyring.current.pubKey) {
          final password = await widget.service.account
              .getPassword(context, widget.service.keyring.current);
          if (password != null) {
            print('pass ok: $password');
            _signAsync(password);
          }
          return;
        } else {
          if (senderPubKey != null) {
            final senderAccIndex = widget.service.keyring.optionals
                .indexWhere((e) => e.pubKey == senderPubKey);
            if (senderAccIndex >= 0) {
              sender = widget.service.keyring.optionals[senderAccIndex];
              errorMsg = dic['uos.acc.mismatch.switch'] +
                  ' ${Fmt.address(sender.address)} ?';
              final needSwitch = await showCupertinoDialog(
                context: context,
                builder: (_) {
                  return CupertinoAlertDialog(
                    title: Text(dic['uos.title']),
                    content: Text(errorMsg),
                    actions: <Widget>[
                      CupertinoButton(
                        child: Text(I18n.of(context)
                            .getDic(i18n_full_dic_ui, 'common')['cancel']),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      CupertinoButton(
                        child: Text(I18n.of(context)
                            .getDic(i18n_full_dic_ui, 'common')['ok']),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );
              if (needSwitch) {
                widget.service.keyring.setCurrent(sender);
                widget.service.plugin.changeAccount(sender);
                widget.service.store.assets
                    .loadCache(sender, widget.service.plugin.basic.name);

                final password = await widget.service.account
                    .getPassword(context, widget.service.keyring.current);
                if (password != null) {
                  print('pass ok: $password');
                  _signAsync(password);
                }
              }
              return;
            } else {
              errorMsg = dic['uos.acc.mismatch'];
            }
          } else {
            errorMsg = dic['uos.qr.invalid'];
          }
        }
      } catch (err) {
        errorMsg = err.toString();
        Navigator.of(context).pop();
      }
      showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text(dic['uos.title']),
            content: Text(errorMsg),
            actions: <Widget>[
              CupertinoButton(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _signAsync(String password) async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    try {
      showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text(dic['uos.title']),
            content: Text(dic['uos.signing']),
          );
        },
      );

      final signed = await widget.service.plugin.sdk.api.uos
          .signAsync(widget.service.plugin.basic.name, password);
      print('signed: $signed');

      Navigator.of(context).popAndPushNamed(
        QrSignerPage.route,
        arguments: signed.substring(2),
      );
    } catch (err) {
      showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text(dic['uos.title']),
            content: Text(err.toString()),
            actions: <Widget>[
              CupertinoButton(
                child: Text(
                    I18n.of(context).getDic(i18n_full_dic_ui, 'account')['ok']),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant AssetsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectedNode?.endpoint != widget.connectedNode?.endpoint) {
      if (_refreshing) {
        _refreshKey.currentState.dismiss(CustomRefreshIndicatorMode.canceled);
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMarketPrices();
    });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();

    super.dispose();
  }

  List<InstrumentData> instrumentDatas() {
    final List<InstrumentData> datas = [];
    if (widget.service.plugin.getAggregatedAssetsWidget(
            onSwitchBack: null, onSwitchHideBalance: null) !=
        null) {
      InstrumentData totalBalance1 = InstrumentData(0, []);

      datas.add(totalBalance1);
    }
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    final marketPrice = widget.service.store.assets.marketPrices[symbol] ?? 1;
    final available = marketPrice *
        Fmt.bigIntToDouble(
          Fmt.balanceInt(
              (widget.service.plugin.balances.native?.availableBalance ?? 0)
                  .toString()),
          decimals,
        );

    final reserved = marketPrice *
        Fmt.bigIntToDouble(
          Fmt.balanceInt(
              (widget.service.plugin.balances.native?.reservedBalance ?? 0)
                  .toString()),
          decimals,
        );

    final locked = marketPrice *
        Fmt.bigIntToDouble(
          Fmt.balanceInt(
              (widget.service.plugin.balances.native?.lockedBalance ?? 0)
                  .toString()),
          decimals,
        );

    InstrumentData totalBalance = InstrumentData(
        available + reserved + locked, [],
        title: I18n.of(context)
            .getDic(i18n_full_dic_app, 'assets')["v3.totalBalance"],
        prompt: I18n.of(context)
            .getDic(i18n_full_dic_app, 'assets')["v3.switchDefi"]);
    totalBalance.items.add(InstrumentItemData(
        Color(0xFFCE623C),
        dic['available'],
        available,
        "assets/images/icon_instrument_orange.png"));
    totalBalance.items.add(InstrumentItemData(Color(0xFFFFC952),
        dic['reserved'], reserved, "assets/images/icon_instrument_yellow.png"));
    totalBalance.items.add(InstrumentItemData(Color(0xFF768FE1), dic['locked'],
        locked, "assets/images/icon_instrument_blue.png"));

    datas.add(totalBalance);

    if (widget.service.plugin.getAggregatedAssetsWidget(
            onSwitchBack: null, onSwitchHideBalance: null) !=
        null) {
      InstrumentData totalBalance1 = InstrumentData(0, []);

      datas.add(totalBalance1);
    }
    return datas;
  }

  PreferredSizeWidget buildAppBar(bool transferEnabled) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            child: AddressIcon(widget.service.keyring.current.address,
                svg: widget.service.keyring.current.icon),
            margin: EdgeInsets.only(right: 8.w),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${Fmt.address(widget.service.keyring.current.address)}",
                style: Theme.of(context).textTheme.headline5,
              ),
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10)),
                        ),
                        height: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            kToolbarHeight -
                            20.h,
                        width: double.infinity,
                        child: NodeSelectPage(
                            widget.service,
                            widget.plugins,
                            widget.switchNetwork,
                            widget.changeNode,
                            widget.checkJSCodeUpdate),
                      );
                    },
                    context: context,
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      widget.connectedNode == null
                          ? Container(
                              width: 11.w,
                              height: 11.w,
                              margin: EdgeInsets.only(right: 4.w),
                              child: Center(
                                  child: RiveAnimation.asset(
                                'assets/images/connecting.riv',
                              )))
                          : Container(
                              width: 11.w,
                              height: 11.w,
                              margin: EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).toggleableActiveColor,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5.5))),
                            ),
                      Text(
                        "${widget.service.plugin.basic.name.toUpperCase()}",
                        style: Theme.of(context)
                            .textTheme
                            .headline4
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        width: 14.w,
                        height: 8.h,
                        margin: EdgeInsets.only(left: 9.w),
                        child: SvgPicture.asset(
                          'assets/images/icon_changenetwork.svg',
                          width: 20.w,
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      leading: v3.IconButton(
        margin: EdgeInsets.only(left: 16.w),
        isBlueBg: true,
        icon: SvgPicture.asset(
          "assets/images/icon_car.svg",
          color: Colors.white,
          height: 24.h,
        ),
        onPressed: widget.service.keyring.allAccounts.length > 0
            ? () async {
                final selected = (await Navigator.of(context)
                    .pushNamed(NetworkSelectPage.route)) as PolkawalletPlugin;
                setState(() {});
                if (selected != null &&
                    selected.basic.name != widget.service.plugin.basic.name) {
                  widget.checkJSCodeUpdate(selected);
                }
              }
            : null,
      ),
      actions: <Widget>[
        Container(
            margin: EdgeInsets.only(right: 16.w),
            child: PopupMenuButton(
                offset: Offset(-12.w, 50.h),
                color: Theme.of(context).cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.w),
                      bottomLeft: Radius.circular(10.w),
                      bottomRight: Radius.circular(10.w)),
                ),
                onSelected: (value) {
                  if (widget.service.keyring.current.address != '') {
                    if (value == '0') {
                      _handleScan(transferEnabled);
                    } else {
                      Navigator.pushNamed(context, AccountQrCodePage.route);
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: SvgPicture.asset(
                                'assets/images/scan.svg',
                                color: Color(0xFF979797),
                                width: 20.w,
                              )),
                          Padding(
                            padding: EdgeInsets.only(left: 5.w),
                            child: Text(
                              I18n.of(context)
                                  .getDic(i18n_full_dic_app, 'assets')['scan'],
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          )
                        ],
                      ),
                      value: '0',
                    ),
                    PopupMenuDivider(height: 1.0),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/qr.svg',
                            color: Color(0xFF979797),
                            width: 22.w,
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              I18n.of(context).getDic(
                                  i18n_full_dic_app, 'assets')['QRCode'],
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          )
                        ],
                      ),
                      value: '1',
                    ),
                  ];
                },
                icon: v3.IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).disabledColor,
                    size: 20.w,
                  ),
                ))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        bool transferEnabled = true;
        // // todo: fix this after new acala online
        if (widget.service.plugin.basic.name == 'acala') {
          transferEnabled = false;
          if (widget.service.store.settings.liveModules['assets'] != null) {
            transferEnabled =
                widget.service.store.settings.liveModules['assets']['enabled'];
          }
        }
        bool claimKarEnabled = false;
        if (widget.service.plugin.basic.name == 'karura') {
          if (widget.service.store.settings.liveModules['claim'] != null) {
            claimKarEnabled =
                widget.service.store.settings.liveModules['claim']['enabled'];
          }
        }
        final symbol =
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
        final decimals =
            (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

        final balancesInfo = widget.service.plugin.balances.native;
        final tokens = widget.service.plugin.balances.tokens.toList();
        final tokensAll = widget.service.plugin.noneNativeTokensAll ?? [];

        // add custom assets from user's config & tokensAll
        final customTokensConfig = widget.service.store.assets.customAssets;
        if (customTokensConfig.keys.length > 0) {
          tokens.retainWhere((e) => customTokensConfig[e.id]);

          tokensAll.retainWhere((e) => customTokensConfig[e.id]);
          tokensAll.forEach((e) {
            if (tokens.indexWhere((token) => token.id == e.id) < 0) {
              tokens.add(e);
            }
          });
        }

        final extraTokens = widget.service.plugin.balances.extraTokens;
        final isTokensFromCache =
            widget.service.plugin.balances.isTokensFromCache;

        String tokenPrice;
        if (widget.service.store.assets.marketPrices[symbol] != null &&
            balancesInfo != null) {
          tokenPrice = Fmt.priceCeil(
              widget.service.store.assets.marketPrices[symbol] *
                  Fmt.bigIntToDouble(Fmt.balanceTotal(balancesInfo), decimals));
        }

        /// Banner visible:
        /// 1. Polkadot always shows banner.
        /// 2. Other plugins can be closed.
        final bannerVisible =
            widget.service.plugin.basic.name == relay_chain_name_dot ||
                widget.service.store.account.showBanner;

        return Scaffold(
          appBar: buildAppBar(transferEnabled),
          body: Column(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.h, top: 15.h),
                      child: instrumentIndex == 0 ||
                              widget.service.plugin.getAggregatedAssetsWidget(
                                      onSwitchBack: null,
                                      onSwitchHideBalance: null) ==
                                  null
                          ? InstrumentWidget(
                              instrumentDatas(),
                              onSwitchChange: () {
                                setState(() {
                                  instrumentIndex = 1;
                                });
                              },
                              onSwitchHideBalance: () {
                                widget.service.store.settings.setIsHideBalance(
                                    !widget
                                        .service.store.settings.isHideBalance);
                              },
                              enabled: widget.connectedNode != null,
                              hideBalance:
                                  widget.service.store.settings.isHideBalance,
                              priceCurrency:
                                  widget.service.store.settings.priceCurrency,
                              key: Key(
                                  "${widget.service.keyring.current.address}_${widget.service.plugin.basic.name}"),
                            )
                          : widget.service.plugin.getAggregatedAssetsWidget(
                              onSwitchBack: () {
                                setState(() {
                                  instrumentIndex = 0;
                                });
                              },
                              onSwitchHideBalance: () {
                                widget.service.store.settings.setIsHideBalance(
                                    !widget
                                        .service.store.settings.isHideBalance);
                              },
                              priceCurrency:
                                  widget.service.store.settings.priceCurrency,
                              hideBalance:
                                  widget.service.store.settings.isHideBalance),
                    ),
                    Visibility(
                        visible: bannerVisible &&
                            !(widget.service.keyring.current.observation ??
                                false),
                        child: AdBanner(widget.service, widget.connectedNode,
                            widget.switchNetwork,
                            canClose: widget.service.plugin.basic.name !=
                                relay_chain_name_dot)),
                    widget.service.plugin.basic.isTestNet
                        ? Padding(
                            padding: EdgeInsets.only(bottom: 7.h, top: 7.h),
                            child: Row(
                              children: [
                                Expanded(
                                    child: TextTag(
                                  I18n.of(context).getDic(i18n_full_dic_app,
                                      'assets')['assets.warn'],
                                  color: Colors.deepOrange,
                                  fontSize: 12,
                                  margin: EdgeInsets.all(0),
                                  padding: EdgeInsets.all(8),
                                ))
                              ],
                            ),
                          )
                        : Container(height: 0.h),
                    FutureBuilder(
                      future: _fetchAnnouncements(),
                      builder: (_, AsyncSnapshot<dynamic> snapshot) {
                        final String lang =
                            I18n.of(context).locale.toString().contains('zh')
                                ? 'zh'
                                : 'en';
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Container();
                        }
                        int level = snapshot.data['level'];
                        final Map announce = snapshot.data[lang];
                        return GestureDetector(
                          child: Container(
                            margin: EdgeInsets.only(bottom: 7.h),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextTag(
                                    announce['title'],
                                    padding: EdgeInsets.fromLTRB(
                                        16.w, 12.h, 16.w, 12.h),
                                    color: level == 0
                                        ? Colors.blue
                                        : level == 1
                                            ? Colors.yellow
                                            : Colors.red,
                                  ),
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AnnouncementPage.route,
                              arguments: AnnouncePageParams(
                                title: announce['title'],
                                link: announce['link'],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Divider(height: 1),
                  ])),
              Expanded(
                  child: Container(
                child: CustomRefreshIndicator(
                  edgeOffset: 16,
                  key: _refreshKey,
                  onRefresh: _updateBalances,
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 6.h, top: 8.h),
                    children: [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(children: [
                            Row(
                              children: [
                                BorderedTitle(
                                  title: I18n.of(context).getDic(
                                      i18n_full_dic_app, 'assets')['assets'],
                                ),
                                Visibility(
                                    visible: widget.service.plugin.basic.name ==
                                            'karura' &&
                                        claimKarEnabled,
                                    child: GestureDetector(
                                        onTap: () => Navigator.of(context)
                                            .pushNamed(DAppWrapperPage.route,
                                                arguments:
                                                    'https://distribution.acala.network/claim'),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(
                                              15.w, 0, 15.w, 4),
                                          height: 24,
                                          margin: EdgeInsets.only(left: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    "assets/images/icon_bg_2.png"),
                                                fit: BoxFit.contain),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Claim KAR',
                                            style: TextStyle(
                                              color:
                                                  Theme.of(context).cardColor,
                                              fontSize: 12,
                                              fontFamily: 'TitilliumWeb',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ))),
                                Visibility(
                                    visible: (widget.service.plugin
                                                    .noneNativeTokensAll ??
                                                [])
                                            .length >
                                        0,
                                    child: Expanded(
                                        child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        v3.IconButton(
                                          onPressed: () => Navigator.of(context)
                                              .pushNamed(
                                                  ManageAssetsPage.route),
                                          icon: Icon(
                                            Icons.menu,
                                            color:
                                                Theme.of(context).disabledColor,
                                            size: 20,
                                          ),
                                        )
                                      ],
                                    )))
                              ],
                            )
                          ])),
                      RoundedCard(
                        margin:
                            EdgeInsets.only(top: 5.h, left: 25.w, right: 25.w),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                height: 30.h,
                                width: 30.w,
                                child: widget.service.plugin.tokenIcons[symbol],
                              ),
                              title: Text(
                                symbol,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      balancesInfo != null &&
                                              balancesInfo.freeBalance != null
                                          ? widget.service.store.settings
                                                  .isHideBalance
                                              ? "******"
                                              : Fmt.priceFloorBigInt(
                                                  Fmt.balanceTotal(
                                                      balancesInfo),
                                                  decimals,
                                                  lengthFixed: 4)
                                          : '--.--',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5
                                          .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: balancesInfo
                                                          ?.isFromCache ==
                                                      false
                                                  ? Theme.of(context)
                                                      .textSelectionTheme
                                                      .selectionColor
                                                  : Theme.of(context)
                                                      .dividerColor)),
                                  Text(
                                    widget.service.store.settings.isHideBalance
                                        ? "******"
                                        : '≈ ${Utils.currencySymbol(widget.service.store.settings.priceCurrency)}${tokenPrice ?? '--.--'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        .copyWith(fontFamily: "TitilliumWeb"),
                                  ),
                                ],
                              ),
                              onTap: transferEnabled
                                  ? () {
                                      Navigator.pushNamed(
                                          context, AssetPage.route);
                                    }
                                  : null,
                            ),
                            Visibility(
                                visible: tokens != null && tokens.length > 0,
                                child: Column(
                                  children:
                                      (tokens ?? []).map((TokenBalanceData i) {
                                    // we can use token price form plugin or from market
                                    final price = i.price ??
                                        widget.service.store.assets
                                            .marketPrices[i.symbol];
                                    return TokenItem(i, i.decimals,
                                        isFromCache: isTokensFromCache,
                                        detailPageRoute: i.detailPageRoute,
                                        marketPrice: price,
                                        icon: TokenIcon(
                                          i.id ?? i.symbol,
                                          widget.service.plugin.tokenIcons,
                                          symbol: i.symbol,
                                        ),
                                        isHideBalance: widget.service.store
                                            .settings.isHideBalance,
                                        priceCurrency: widget.service.store
                                            .settings.priceCurrency);
                                  }).toList(),
                                )),
                            Visibility(
                              visible: extraTokens == null ||
                                  extraTokens.length == 0,
                              child: Column(
                                  children: (extraTokens ?? [])
                                      .map((ExtraTokenData i) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 16.h),
                                      child: BorderedTitle(
                                        title: i.title,
                                      ),
                                    ),
                                    Column(
                                      children: i.tokens
                                          .map((e) => TokenItem(e, e.decimals,
                                              isFromCache: isTokensFromCache,
                                              detailPageRoute:
                                                  e.detailPageRoute,
                                              icon: widget.service.plugin
                                                  .tokenIcons[e.symbol],
                                              isHideBalance: widget.service
                                                  .store.settings.isHideBalance,
                                              priceCurrency: widget
                                                  .service
                                                  .store
                                                  .settings
                                                  .priceCurrency))
                                          .toList(),
                                    )
                                  ],
                                );
                              }).toList()),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

class TokenItem extends StatelessWidget {
  TokenItem(this.item, this.decimals,
      {this.marketPrice,
      this.detailPageRoute,
      this.icon,
      this.isFromCache = false,
      this.isHideBalance,
      this.priceCurrency});
  final TokenBalanceData item;
  final int decimals;
  final double marketPrice;
  final String detailPageRoute;
  final Widget icon;
  final bool isFromCache;
  final bool isHideBalance;
  final String priceCurrency;

  @override
  Widget build(BuildContext context) {
    final balanceTotal =
        Fmt.balanceInt(item.amount) + Fmt.balanceInt(item.reserved);
    return Column(
      children: [
        Divider(height: 1),
        ListTile(
          leading: Container(
            height: 30.h,
            width: 30.w,
            alignment: Alignment.centerLeft,
            child: icon ??
                CircleAvatar(
                  child: Text(item.symbol.substring(0, 2)),
                ),
          ),
          title: Text(
            item.symbol,
            style: Theme.of(context)
                .textTheme
                .headline5
                .copyWith(fontWeight: FontWeight.w600),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isHideBalance
                    ? "******"
                    : Fmt.priceFloorBigInt(balanceTotal, decimals,
                        lengthFixed: 4),
                style: Theme.of(context).textTheme.headline5.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFromCache == false
                        ? Theme.of(context).textSelectionTheme.selectionColor
                        : Theme.of(context).dividerColor),
              ),
              marketPrice != null
                  ? Text(
                      isHideBalance
                          ? "******"
                          : '≈ ${Utils.currencySymbol(priceCurrency)}${Fmt.priceFloor(Fmt.bigIntToDouble(balanceTotal, decimals) * marketPrice)}',
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(fontFamily: "TitilliumWeb"),
                    )
                  : Container(height: 0, width: 8),
            ],
          ),
          onTap: detailPageRoute == null
              ? null
              : () {
                  Navigator.of(context)
                      .pushNamed(detailPageRoute, arguments: item);
                },
        )
      ],
    );
  }
}
