import 'dart:async';

import 'package:app/common/components/CustomRefreshIndicator.dart';
import 'package:app/common/consts.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:rive/rive.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(
    this.service,
    this.plugins,
    this.connectedNode,
    this.checkJSCodeUpdate,
    this.switchNetwork,
    this.handleWalletConnect,
  );

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;
  final Future<void> Function(String, {NetworkParams node}) switchNetwork;
  final Future<void> Function(String) handleWalletConnect;

  final List<PolkawalletPlugin> plugins;

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

  double _rate = 1.0;

  Future<void> _updateBalances() async {
    if (widget.connectedNode == null) return;

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
    widget.service.assets.fetchMarketPrices();

    final duration =
        widget.service.store.assets.marketPrices.keys.length > 0 ? 60 : 6;
    _priceUpdateTimer = Timer(Duration(seconds: duration), _updateMarketPrices);
  }

  Future<void> _handleScan() async {
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

      if (data.type == QRCodeResultType.address) {
        if (widget.service.plugin.basic.name == para_chain_name_karura) {
          final symbol =
              (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
          Navigator.of(context).pushNamed('/assets/token/transfer', arguments: {
            'tokenNameId': symbol,
            'address': data.address.address
          });
          return;
        }
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

      List<Widget> errorMsg = [];
      try {
        final qrData = await widget.service.plugin.sdk.api.uos.parseQrCode(
            widget.service.keyring, data.rawData.toString().trim());
        Navigator.of(context).pop();

        final networkIndex = widget.plugins
            .indexWhere((e) => e.basic.genesisHash == qrData.genesisHash);
        // we can do the signing if we have this plugin support
        if (qrData.genesisHash != null && networkIndex < 0) {
          errorMsg.add(Text(dic['uos.qr.invalid']));
        } else {
          final sender = widget.service.keyring.keyPairs
              .firstWhere((e) => e.pubKey == qrData.signer);
          final confirmMsg = <Widget>[
            networkIndex < 0
                ? Container()
                : Container(
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(dic['uos.network']),
                  ),
            networkIndex < 0
                ? Container()
                : Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).dividerColor, width: 0.5),
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    child: Row(
                      children: [
                        Container(
                            margin: EdgeInsets.only(right: 8),
                            width: 32,
                            child: widget.plugins[networkIndex].basic.icon),
                        Text(
                          widget.plugins[networkIndex].basic.name.toUpperCase(),
                          style: Theme.of(context).textTheme.headline4,
                        )
                      ],
                    ),
                  ),
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 8),
              child: Text(dic['uos.signer']),
            ),
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).dividerColor, width: 0.5),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 32,
                    child: AddressIcon(sender.address, svg: sender.icon),
                  ),
                  Text(
                    Fmt.address(sender.address),
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
            ),
          ];

          bool needSwitchAccount = false;
          if (qrData.signer == widget.service.keyring.current.pubKey) {
            confirmMsg.add(Text(dic['uos.continue']));
          } else {
            confirmMsg.add(Text(dic['uos.continue.switch']));
            needSwitchAccount = true;
          }

          final confirmed = await showCupertinoDialog(
            context: context,
            builder: (_) {
              return CupertinoAlertDialog(
                title: Text(dic['uos.title']),
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: confirmMsg),
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

          if (confirmed) {
            if (needSwitchAccount) {
              widget.service.keyring.setCurrent(sender);
              widget.service.plugin.changeAccount(sender);
              widget.service.store.assets
                  .loadCache(sender, widget.service.plugin.basic.name);
            }

            final password = await widget.service.account
                .getPassword(context, widget.service.keyring.current);
            if (password != null) {
              print('pass ok: $password');
              _signAsync(password);
            }
          }
          return;
        }
      } catch (err) {
        errorMsg.add(Text(err.toString()));
        Navigator.of(context).pop();
      }

      showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text(dic['uos.title']),
            content: Column(children: errorMsg),
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
      getRate();
    });
  }

  Future<void> getRate() async {
    var rate = await widget.service.store.settings.getRate();
    if (mounted) {
      setState(() {
        this._rate = rate;
      });
    }
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();

    super.dispose();
  }

  List<Color> _gradienColors() {
    switch (widget.service.plugin.basic.name) {
      case para_chain_name_karura:
        return [Color(0xFFFF4646), Color(0xFFFF5D4D), Color(0xFF323133)];
      case para_chain_name_acala:
        return [Color(0xFFFF5D3A), Color(0xFFFF3F3F), Color(0xFF4528FF)];
      case para_chain_name_bifrost:
        return [
          Color(0xFF5AAFE1),
          Color(0xFF596ED2),
          Color(0xFFB358BD),
          Color(0xFFFFAE5E)
        ];
      default:
        return [Theme.of(context).primaryColor, Theme.of(context).hoverColor];
    }
  }

  List<InstrumentData> _instrumentDatas() {
    final List<InstrumentData> datas = [];

    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final symbol = (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
    final title = "${dic['v3.my']} $symbol";

    final instrument1 = InstrumentData(0, [], title: title);

    final decimals =
        (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
    var marketPrice = widget.service.store.assets.marketPrices[symbol] ?? 0;
    if (widget.service.store.settings.priceCurrency == "CNY") {
      marketPrice *= _rate;
    }
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

    InstrumentData totalBalance =
        InstrumentData(available + reserved + locked, [], title: title);
    totalBalance.items.add(InstrumentItemData(Color(0xFFCE623C),
        dic['reserved'], reserved, "assets/images/icon_instrument_orange.png"));
    totalBalance.items.add(InstrumentItemData(Color(0xFFFFC952), dic['locked'],
        locked, "assets/images/icon_instrument_yellow.png"));
    totalBalance.items.add(InstrumentItemData(Color(0xFF768FE1),
        dic['available'], available, "assets/images/icon_instrument_blue.png"));

    datas.add(instrument1);
    datas.add(totalBalance);
    datas.add(instrument1);

    return datas;
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            child: AddressIcon(widget.service.keyring.current.address,
                svg: widget.service.keyring.current.icon),
            margin: EdgeInsets.only(right: 8.w),
          ),
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Column(
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
                            child: NodeSelectPage(widget.service,
                                widget.plugins, widget.switchNetwork),
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
                                  width: 11,
                                  height: 11,
                                  margin: EdgeInsets.only(right: 4),
                                  child: Center(
                                      child: RiveAnimation.asset(
                                    'assets/images/connecting.riv',
                                  )))
                              : Container(
                                  width: 11,
                                  height: 11,
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .toggleableActiveColor,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(5.5))),
                                ),
                          Text(
                            "${widget.service.plugin.basic.name.toUpperCase()}",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                .copyWith(
                                    fontWeight: FontWeight.w600, height: 0.9),
                          ),
                          Container(
                            width: 14,
                            margin: EdgeInsets.only(left: 9),
                            child: SvgPicture.asset(
                              'assets/images/icon_changenetwork.svg',
                              width: 14,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      leading: v3.IconButton(
        isBlueBg: true,
        icon: SvgPicture.asset(
          "assets/images/icon_car.svg",
          color: Colors.white,
          height: 22,
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
            margin: EdgeInsets.only(right: 6.w),
            child: v3.PopupMenuButton(
                offset: Offset(-12, 52),
                color: Theme.of(context).cardColor,
                padding: EdgeInsets.zero,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                ),
                onSelected: (value) {
                  if (widget.service.keyring.current.address != '') {
                    if (value == '0') {
                      _handleScan();
                    } else {
                      Navigator.pushNamed(context, AccountQrCodePage.route);
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <v3.PopupMenuEntry<String>>[
                    v3.PopupMenuItem(
                      height: 34,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: SvgPicture.asset(
                                'assets/images/scan.svg',
                                color: Color(0xFF979797),
                                width: 20,
                              )),
                          Padding(
                            padding: EdgeInsets.only(left: 5),
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
                    v3.PopupMenuDivider(height: 1.0),
                    v3.PopupMenuItem(
                      height: 34,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/qr.svg',
                            color: Color(0xFF979797),
                            width: 22,
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
                    size: 20,
                  ),
                ))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final symbol =
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
        final decimals =
            (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

        final balancesInfo = widget.service.plugin.balances.native;
        final tokens = widget.service.plugin.balances.tokens.toList();
        final tokensAll = widget.service.plugin.noneNativeTokensAll ?? [];
        final defaultTokens = widget.service.plugin.defaultTokens;

        // filter tokens by plugin.defaultTokens
        if (defaultTokens.length > 0) {
          tokens.retainWhere((e) =>
              e.symbol.contains('-') ||
              defaultTokens.indexOf(e.tokenNameId) > -1);
        }
        // remove empty LP tokens
        if (tokens.length > 0) {
          tokens.removeWhere((e) => e.symbol.contains('-') && e.amount == '0');
        }
        // add custom assets from user's config & tokensAll
        final customTokensConfig = widget.service.store.assets.customAssets;
        if (customTokensConfig.keys.length > 0) {
          tokens.retainWhere((e) => customTokensConfig[e.symbol]);

          tokensAll.retainWhere((e) => customTokensConfig[e.symbol]);
          tokensAll.forEach((e) {
            if (tokens.indexWhere((token) => token.symbol == e.symbol) < 0) {
              tokens.add(e);
            }
          });
        }
        // sort the list
        if (tokens.length > 0) {
          tokens.sort((a, b) => a.symbol.contains('-')
              ? 1
              : b.symbol.contains('-')
                  ? -1
                  : a.symbol.compareTo(b.symbol));
        }

        final extraTokens = widget.service.plugin.balances.extraTokens;
        final isTokensFromCache =
            widget.service.plugin.balances.isTokensFromCache;

        String tokenPrice;
        if (widget.service.store.assets.marketPrices[symbol] != null &&
            balancesInfo != null) {
          tokenPrice = Fmt.priceCeil(
              widget.service.store.assets.marketPrices[symbol] *
                  (widget.service.store.settings.priceCurrency == "CNY"
                      ? _rate
                      : 1.0) *
                  Fmt.bigIntToDouble(Fmt.balanceTotal(balancesInfo), decimals));
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: buildAppBar(),
          body: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 10.h),
                child: instrumentIndex == 0 ||
                        widget.service.plugin.getAggregatedAssetsWidget(
                                onSwitchBack: null,
                                onSwitchHideBalance: null) ==
                            null
                    ? InstrumentWidget(
                        _instrumentDatas(),
                        gradienColors: _gradienColors(),
                        switchDefi: widget.service.plugin
                                .getAggregatedAssetsWidget(
                                    onSwitchBack: null,
                                    onSwitchHideBalance: null) !=
                            null,
                        onSwitchChange: () {
                          setState(() {
                            instrumentIndex = 1;
                          });
                        },
                        onSwitchHideBalance: () {
                          widget.service.store.settings.setIsHideBalance(
                              !widget.service.store.settings.isHideBalance);
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
                              !widget.service.store.settings.isHideBalance);
                        },
                        priceCurrency:
                            widget.service.store.settings.priceCurrency,
                        rate:
                            widget.service.store.settings.priceCurrency == "CNY"
                                ? _rate
                                : 1.0,
                        hideBalance:
                            widget.service.store.settings.isHideBalance),
              ),
              Container(
                margin: EdgeInsets.only(left: 16.w, right: 16.w),
                child: AdBanner(widget.service, widget.connectedNode),
              ),
              // Container(
              //   margin: EdgeInsets.only(left: 16.w, right: 16.w),
              //   child: RoundedButton(
              //     text: 'DApps Test',
              //     onPressed: () =>
              //         Navigator.of(context).pushNamed(DAppsTestPage.route),
              //   ),
              // ),
              widget.service.plugin.basic.isTestNet
                  ? Padding(
                      padding: EdgeInsets.only(top: 5.h),
                      child: Row(
                        children: [
                          Expanded(
                              child: TextTag(
                            I18n.of(context).getDic(
                                i18n_full_dic_app, 'assets')['assets.warn'],
                            color: Colors.deepOrange,
                            fontSize: 12,
                            margin: EdgeInsets.all(0),
                            padding: EdgeInsets.all(8),
                          ))
                        ],
                      ),
                    )
                  : Container(height: 0.h),
              // FutureBuilder(
              //   future: _fetchAnnouncements(),
              //   builder: (_, AsyncSnapshot<dynamic> snapshot) {
              //     final String lang =
              //         I18n.of(context).locale.toString().contains('zh')
              //             ? 'zh'
              //             : 'en';
              //     if (!snapshot.hasData || snapshot.data == null) {
              //       return Container();
              //     }
              //     int level = snapshot.data['level'];
              //     final Map announce = snapshot.data[lang];
              //     return GestureDetector(
              //       child: Container(
              //         margin: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 0),
              //         child: Row(
              //           children: <Widget>[
              //             Expanded(
              //               child: TextTag(
              //                 announce['title'],
              //                 padding:
              //                     EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              //                 color: level == 0
              //                     ? Colors.blue
              //                     : level == 1
              //                         ? Colors.yellow
              //                         : Colors.red,
              //               ),
              //             )
              //           ],
              //         ),
              //       ),
              //       onTap: () {
              //         Navigator.of(context).pushNamed(
              //           AnnouncementPage.route,
              //           arguments: AnnouncePageParams(
              //             title: announce['title'],
              //             link: announce['link'],
              //           ),
              //         );
              //       },
              //     );
              //   },
              // ),
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Divider(height: 1),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: Row(
                  children: [
                    BorderedTitle(
                      title: I18n.of(context)
                          .getDic(i18n_full_dic_app, 'assets')['assets'],
                    ),
                    Visibility(
                        visible:
                            (widget.service.plugin.noneNativeTokensAll ?? [])
                                    .length >
                                0,
                        child: Expanded(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            v3.IconButton(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(ManageAssetsPage.route),
                              icon: Icon(
                                Icons.menu,
                                color: Theme.of(context).disabledColor,
                                size: 20,
                              ),
                            )
                          ],
                        )))
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                child: CustomRefreshIndicator(
                  edgeOffset: 16,
                  key: _refreshKey,
                  onRefresh: _updateBalances,
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 6.h, top: 3.h),
                    children: [
                      RoundedCard(
                        margin: EdgeInsets.only(left: 16.w, right: 16.w),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                width: 48.w,
                                alignment: Alignment.centerLeft,
                                child: TokenIcon(
                                  symbol,
                                  widget.service.plugin.tokenIcons,
                                ),
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
                              onTap: () {
                                Navigator.pushNamed(context, AssetPage.route);
                              },
                            ),
                            Visibility(
                                visible: tokens != null && tokens.length > 0,
                                child: Column(
                                  children:
                                      (tokens ?? []).map((TokenBalanceData i) {
                                    // we can use token price form plugin or from market
                                    final price = i.price ??
                                        widget.service.store.assets
                                            .marketPrices[i.symbol] ??
                                        0.0;
                                    return TokenItem(
                                      i,
                                      i.decimals,
                                      isFromCache: isTokensFromCache,
                                      detailPageRoute: i.detailPageRoute,
                                      marketPrice: price *
                                          (widget.service.store.settings
                                                      .priceCurrency ==
                                                  "CNY"
                                              ? _rate
                                              : 1.0),
                                      icon: TokenIcon(
                                        widget.service.plugin.basic.name ==
                                                para_chain_name_statemine
                                            ? i.id
                                            : i.symbol,
                                        widget.service.plugin.tokenIcons,
                                        symbol: i.symbol,
                                      ),
                                      isHideBalance: widget
                                          .service.store.settings.isHideBalance,
                                      priceCurrency: widget
                                          .service.store.settings.priceCurrency,
                                    );
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
                                          .map((e) => TokenItem(
                                                e,
                                                e.decimals,
                                                isFromCache: isTokensFromCache,
                                                detailPageRoute:
                                                    e.detailPageRoute,
                                                icon: widget.service.plugin
                                                    .tokenIcons[e.symbol],
                                                isHideBalance: widget
                                                    .service
                                                    .store
                                                    .settings
                                                    .isHideBalance,
                                                priceCurrency: widget
                                                    .service
                                                    .store
                                                    .settings
                                                    .priceCurrency,
                                              ))
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
            width: 48.w,
            alignment: Alignment.centerLeft,
            child: icon ??
                CircleAvatar(
                  child: Text(item.symbol.substring(0, 2)),
                ),
          ),
          title: Text(
            item.name,
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
              marketPrice != null && marketPrice > 0
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
