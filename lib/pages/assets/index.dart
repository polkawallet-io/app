import 'dart:async';
import 'dart:convert';

import 'package:app/pages/assets/announcementPage.dart';
import 'package:app/pages/networkSelectPage.dart';
// import 'package:app/pages/assets/receive/receivePage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_kusama/service/walletApi.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/passwordInputDialog.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(this.service);

  final AppService service;

  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetsPage> {
  bool _faucetSubmitting = false;
  bool _preclaimChecking = false;

  List _announcements;

  Future<List> _fetchAnnouncements() async {
    if (_announcements != null) return _announcements;

    final List res = await WalletApi.getAnnouncements();
    setState(() {
      _announcements = res;
    });
    return res;
  }

  Future<void> _handleScan() async {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final data = await Navigator.pushNamed(
      context,
      ScanPage.route,
      arguments: 'tx',
    );
    if (data != null) {
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

      String errorMsg;
      try {
        final senderPubKey = await widget.service.plugin.sdk.api.uos
            .parseQrCode(widget.service.keyring, data.toString().trim());
        if (senderPubKey == widget.service.keyring.current.pubKey) {
          showCupertinoDialog(
            context: context,
            builder: (_) {
              return PasswordInputDialog(
                widget.service.plugin.sdk.api,
                account: widget.service.keyring.current,
                title: Text(dic['uos.title']),
                content: Text(dic['uos.pass.warn']),
                onOk: (password) {
                  print('pass ok: $password');
                  _signAsync(password);
                },
              );
            },
          );
          return;
        } else {
          if (senderPubKey != null) {
            errorMsg = dic['uos.qr.mismatch'];
          } else {
            errorMsg = dic['uos.qr.invalid'];
          }
        }
      } catch (err) {
        errorMsg = err.toString();
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
      final signed =
          await widget.service.plugin.sdk.api.uos.signAsync(password);
      print('signed: $signed');
      Navigator.of(context).pushNamed(
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

  Widget _buildTopCard(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    String network = widget.service.store.settings.loading
        ? dic['node.connecting']
        : widget.service.store.settings.networkName ?? dic['node.failed'];

    final acc = widget.service.keyring.current;
    final accIndex =
        acc.indexInfo != null && acc.indexInfo['accountIndex'] != null
            ? '${acc.indexInfo['accountIndex']}\n'
            : '';
    return RoundedCard(
      margin: EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: AddressIcon(acc.address, svg: acc.icon),
            title:
                Text(UI.accountDisplayNameString(acc.address, acc.indexInfo)),
            subtitle: Text(network),
          ),
          ListTile(
            title: Row(
              children: [
                GestureDetector(
                  child: Icon(
                    Icons.qr_code,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  onTap: () {
                    // if (acc.address != '') {
                    //   Navigator.pushNamed(context, ReceivePage.route);
                    // }
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '$accIndex${Fmt.address(acc.address)}',
                    style: TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),
            trailing: IconButton(
              icon: SvgPicture.asset(
                'assets/images/scan.svg',
                color: Theme.of(context).primaryColor,
                width: 22,
              ),
              onPressed: () {
                if (acc.address != '') {
                  _handleScan();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // if network connected failed, reconnect
    if (!widget.service.store.settings.loading &&
        widget.service.store.settings.networkName == null) {
      widget.service.store.settings.setNetworkLoading(true);
      widget.service.plugin.start(widget.service.keyring,
          webView: widget.service.plugin.sdk.webView);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final symbol = widget.service.plugin.networkState.tokenSymbol ?? '';
        final decimals = widget.service.plugin.networkState.tokenDecimals ?? 12;
        final networkName = widget.service.plugin.networkState.name ?? '';

        final balancesInfo = widget.service.plugin.balances.native;
        // final tokens = widget.service.plugin.balances.tokens;
        // final extraTokens = widget.service.plugin.balances.extraTokens;

        String tokenPrice;
        if (widget.service.store.assets.marketPrices[symbol] != null &&
            balancesInfo != null) {
          tokenPrice = Fmt.priceCeil(
              widget.service.store.assets.marketPrices[symbol] *
                  Fmt.bigIntToDouble(balancesInfo.freeBalance, decimals));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: SizedBox(
              height: 28,
              child: Image.asset('assets/images/logo.png'),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).cardColor),
                onPressed: () =>
                    Navigator.of(context).pushNamed(NetworkSelectPage.route),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              _buildTopCard(context),
              FutureBuilder(
                future: _fetchAnnouncements(),
                builder: (_, AsyncSnapshot<List> snapshot) {
                  final String lang =
                      I18n.of(context).locale.toString().contains('zh')
                          ? 'zh'
                          : 'en';
                  if (!snapshot.hasData || snapshot.data.length == 0) {
                    return Container(height: 24);
                  }
                  final Map announce = snapshot.data[0][lang];
                  return GestureDetector(
                    child: Container(
                      margin: EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextTag(
                              announce['title'],
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: BorderedTitle(
                        title: I18n.of(context)
                            .getDic(i18n_full_dic_app, 'assets')['assets'],
                      ),
                    ),
                    RoundedCard(
                      margin: EdgeInsets.only(top: 16),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          child: widget.service.plugin.tokenIcons[symbol],
                        ),
                        title: Text(symbol),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Fmt.priceFloorBigInt(
                                  balancesInfo != null
                                      ? Fmt.balanceInt(
                                          (balancesInfo.freeBalance ?? 0)
                                              .toString())
                                      : BigInt.zero,
                                  decimals,
                                  lengthFixed: 3),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black54),
                            ),
                            Text(
                              '≈ \$ ${tokenPrice ?? '--.--'}',
                              style: TextStyle(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navigator.pushNamed(context, AssetPage.route,
                          //     arguments: TokenData(
                          //         tokenType: TokenType.Native, id: symbol));
                        },
                      ),
                    ),
//                   Column(
//                     children: currencyIds.map((i) {
// //                  print(store.assets.balances[i]);
//                       String token =
//                           i == acala_stable_coin ? acala_stable_coin_view : i;
//
//                       bool hasIcon = true;
//                       if (isLaminar && token != acala_stable_coin_view) {
//                         hasIcon = false;
//                       }
//                       return RoundedCard(
//                         margin: EdgeInsets.only(top: 16),
//                         child: ListTile(
//                           leading: Container(
//                             width: 36,
//                             child: hasIcon
//                                 ? Image.asset('assets/images/assets/$i.png')
//                                 : CircleAvatar(
//                                     child: Text(token.substring(0, 2)),
//                                   ),
//                           ),
//                           title: Text(token),
//                           trailing: Text(
//                             Fmt.priceFloorBigInt(
//                                 Fmt.balanceInt(store.assets.tokenBalances[i]),
//                                 decimals,
//                                 lengthFixed: 3),
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 20,
//                                 color: Colors.black54),
//                           ),
//                           onTap: () {
//                             Navigator.pushNamed(context, AssetPage.route,
//                                 arguments: TokenData(
//                                     tokenType: TokenType.Token, id: token));
//                           },
//                         ),
//                       );
//                     }).toList(),
//                   ),
                    Container(
                      padding: EdgeInsets.only(bottom: 32),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
