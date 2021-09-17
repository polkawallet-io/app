import 'dart:async';

import 'package:app/common/components/CustomRefreshIndicator.dart';
import 'package:app/common/consts.dart';
import 'package:app/pages/assets/announcementPage.dart';
import 'package:app/pages/assets/asset/assetPage.dart';
import 'package:app/pages/assets/manage/manageAssetsPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/pages/public/AdBanner.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/components/outlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(
    this.service,
    this.connectedNode,
    this.checkJSCodeUpdate,
    this.changeToKusama,
    this.handleWalletConnect,
  );

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;
  final Future<void> Function() changeToKusama;
  final Future<void> Function(String) handleWalletConnect;

  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetsPage> {
  final GlobalKey<CustomRefreshIndicatorState> _refreshKey =
      new GlobalKey<CustomRefreshIndicatorState>();
  bool _refreshing = false;

  List _announcements;

  Timer _priceUpdateTimer;

  Future<void> _updateBalances() async {
    setState(() {
      _refreshing = true;
    });
    await widget.service.plugin.updateBalances(widget.service.keyring.current);
    setState(() {
      _refreshing = false;
    });
  }

  Future<List> _fetchAnnouncements() async {
    if (_announcements != null) return _announcements;

    final List res = await WalletApi.getAnnouncements();
    setState(() {
      _announcements = res;
    });
    return res;
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
                  margin: EdgeInsets.only(top: 16),
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

  Widget _buildTopCard(BuildContext context, bool transferEnabled) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    String network = widget.connectedNode == null
        ? dic['node.connecting']
        : widget.service.plugin.networkState.name ?? dic['node.failed'];

    final acc = widget.service.keyring.current;
    final accIndex =
        acc.indexInfo != null && acc.indexInfo['accountIndex'] != null
            ? '${acc.indexInfo['accountIndex']}\n'
            : '';
    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: AddressIcon(acc.address, svg: acc.icon),
              title: Text(UI.accountName(context, acc)),
              subtitle: Text(network),
            ),
          ),
          ListTile(
            title: Row(
              children: [
                GestureDetector(
                  child: SvgPicture.asset(
                    'assets/images/qr.svg',
                    color: Theme.of(context).primaryColor,
                    width: 32,
                  ),
                  onTap: () {
                    if (acc.address != '') {
                      Navigator.pushNamed(context, AccountQrCodePage.route);
                    }
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '$accIndex${Fmt.address(acc.address)}',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
            trailing: IconButton(
              icon: SvgPicture.asset(
                'assets/images/scan.svg',
                color: Theme.of(context).primaryColor,
                width: 32,
              ),
              onPressed: () {
                if (acc.address != '') {
                  _handleScan(transferEnabled);
                }
              },
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        bool transferEnabled = true;
        // todo: fix this after new acala online
        if (widget.service.plugin.basic.name == 'acala') {
          if (widget.service.buildTarget != BuildTargets.dev) {
            transferEnabled = false;
            if (widget.service.store.settings.liveModules['assets'] != null) {
              transferEnabled = widget
                  .service.store.settings.liveModules['assets']['enabled'];
            }
          }
        }
        bool claimKarEnabled = false;
        if (widget.service.plugin.basic.name == 'karura') {
          if (widget.service.buildTarget != BuildTargets.dev) {
            if (widget.service.store.settings.liveModules['claim'] != null) {
              claimKarEnabled =
                  widget.service.store.settings.liveModules['claim']['enabled'];
            }
          } else {
            claimKarEnabled = true;
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

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: SizedBox(
              height: 36,
              child: Image.asset('assets/images/logo.png'),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            actions: <Widget>[
              IconButton(
                padding: EdgeInsets.only(right: 8),
                icon: SvgPicture.asset(
                  'assets/images/menu.svg',
                  color: Theme.of(context).cardColor,
                  width: 24,
                ),
                onPressed: widget.service.keyring.allAccounts.length > 0
                    ? () async {
                        final selected = (await Navigator.of(context)
                                .pushNamed(NetworkSelectPage.route))
                            as PolkawalletPlugin;
                        setState(() {});
                        if (selected != null &&
                            selected.basic.name !=
                                widget.service.plugin.basic.name) {
                          widget.checkJSCodeUpdate(selected);
                        }
                      }
                    : null,
              ),
            ],
          ),
          body: Stack(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 120),
                child: CustomRefreshIndicator(
                  edgeOffset: 16,
                  key: _refreshKey,
                  onRefresh: _updateBalances,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 56, 16, 24),
                    children: [
                      widget.service.plugin.basic.isTestNet
                          ? Padding(
                              padding: EdgeInsets.only(bottom: 16, top: 8),
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
                          : Container(height: 24),
                      FutureBuilder(
                        future: _fetchAnnouncements(),
                        builder: (_, AsyncSnapshot<List> snapshot) {
                          final String lang =
                              I18n.of(context).locale.toString().contains('zh')
                                  ? 'zh'
                                  : 'en';
                          if (!snapshot.hasData || snapshot.data.length == 0) {
                            return Container();
                          }
                          final Map announce = snapshot.data[0][lang];
                          return GestureDetector(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextTag(
                                      announce['title'],
                                      padding:
                                          EdgeInsets.fromLTRB(16, 12, 16, 12),
                                      color: Colors.lightGreen,
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
                      Row(
                        children: [
                          BorderedTitle(
                            title: I18n.of(context)
                                .getDic(i18n_full_dic_app, 'assets')['assets'],
                          ),
                          widget.service.plugin.basic.name == 'karura' &&
                                  claimKarEnabled
                              ? OutlinedButtonSmall(
                                  content: 'Claim KAR',
                                  active: true,
                                  margin: EdgeInsets.only(left: 8),
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed(
                                    DAppWrapperPage.route,
                                    arguments:
                                        'https://distribution.acala.network/claim',
                                  ),
                                )
                              : Container(),
                          (widget.service.plugin.noneNativeTokensAll ?? [])
                                      .length >
                                  0
                              ? Expanded(
                                  child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                              ManageAssetsPage.route);
                                        },
                                        child: Icon(
                                          Icons.add_circle,
                                          color:
                                              Theme.of(context).disabledColor,
                                        ))
                                  ],
                                ))
                              : Container()
                        ],
                      ),
                      RoundedCard(
                        margin: EdgeInsets.only(top: 16),
                        child: ListTile(
                          leading: Container(
                            height: 36,
                            width: 37,
                            margin: EdgeInsets.only(right: 8),
                            child: widget.service.plugin.tokenIcons[symbol],
                          ),
                          title: Text(symbol),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                balancesInfo != null &&
                                        balancesInfo.freeBalance != null
                                    ? Fmt.priceFloorBigInt(
                                        Fmt.balanceTotal(balancesInfo),
                                        decimals,
                                        lengthFixed: 4)
                                    : '--.--',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: -0.6,
                                    color: balancesInfo?.isFromCache == false
                                        ? Colors.black54
                                        : Colors.black26),
                              ),
                              Text(
                                '≈ \$${tokenPrice ?? '--.--'}',
                                style: TextStyle(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: transferEnabled
                              ? () {
                                  Navigator.pushNamed(context, AssetPage.route);
                                }
                              : null,
                        ),
                      ),
                      Column(
                        children: tokens == null || tokens.length == 0
                            ? [Container()]
                            : tokens.map((TokenBalanceData i) {
                                // we can use token price form plugin or from market
                                final price = i.price ??
                                    widget.service.store.assets
                                        .marketPrices[i.symbol];
                                return TokenItem(
                                  i,
                                  i.decimals,
                                  isFromCache: isTokensFromCache,
                                  detailPageRoute: i.detailPageRoute,
                                  marketPrice: price,
                                  icon: TokenIcon(
                                    i.id ?? i.symbol,
                                    widget.service.plugin.tokenIcons,
                                    symbol: i.symbol,
                                  ),
                                );
                              }).toList(),
                      ),
                      Column(
                        children: extraTokens == null || extraTokens.length == 0
                            ? [Container()]
                            : extraTokens.map((ExtraTokenData i) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 16),
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
                                              ))
                                          .toList(),
                                    )
                                  ],
                                );
                              }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  _buildTopCard(context, transferEnabled),
                  Expanded(child: Container()),
                  widget.service.store.account.showBanner &&
                          !(widget.service.keyring.current.observation ?? false)
                      ? AdBanner(widget.service, widget.connectedNode,
                          widget.changeToKusama,
                          canClose: true)
                      : Container(),
                ],
              )
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
      this.isFromCache = false});
  final TokenBalanceData item;
  final int decimals;
  final double marketPrice;
  final String detailPageRoute;
  final Widget icon;
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    final balanceTotal =
        Fmt.balanceInt(item.amount) + Fmt.balanceInt(item.reserved);
    return RoundedCard(
      margin: EdgeInsets.only(top: 16),
      child: ListTile(
        leading: Container(
          height: 36,
          width: 45,
          alignment: Alignment.centerLeft,
          child: icon ??
              CircleAvatar(
                child: Text(item.symbol.substring(0, 2)),
              ),
        ),
        title: Text(item.symbol),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Fmt.priceFloorBigInt(balanceTotal, decimals, lengthFixed: 4),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: -0.6,
                  color: isFromCache ? Colors.black26 : Colors.black54),
            ),
            marketPrice != null
                ? Text(
                    '≈ \$${Fmt.priceFloor(Fmt.bigIntToDouble(balanceTotal, decimals) * marketPrice)}',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 12,
                    ),
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
      ),
    );
  }
}
