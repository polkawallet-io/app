import 'dart:async';

import 'package:app/pages/assets/announcementPage.dart';
import 'package:app/pages/assets/asset/assetPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/service/index.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/borderedTitle.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(this.service, this.connectedNode);

  final AppService service;
  final NetworkParams connectedNode;

  @override
  _AssetsState createState() => _AssetsState();
}

class _AssetsState extends State<AssetsPage> {
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
    final data = (await Navigator.pushNamed(
      context,
      ScanPage.route,
      arguments: 'tx',
    )) as QRCodeResult;
    if (data != null) {
      if (data.type == QRCodeResultType.address) {
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

      String errorMsg;
      try {
        final senderPubKey = await widget.service.plugin.sdk.api.uos
            .parseQrCode(
                widget.service.keyring, data.rawData.toString().trim());
        if (senderPubKey == widget.service.keyring.current.pubKey) {
          final password = await widget.service.account
              .getPassword(context, widget.service.keyring.current);
          print('pass ok: $password');
          _signAsync(password);
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
      padding: EdgeInsets.all(8),
      child: Column(
        children: <Widget>[
          ListTile(
            leading: AddressIcon(acc.address, svg: acc.icon),
            title: Text(UI.accountName(context, acc)),
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
                    if (acc.address != '') {
                      Navigator.pushNamed(context, AccountQrCodePage.route);
                    }
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
                width: 20,
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
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final symbol = widget.service.plugin.networkState.tokenSymbol ?? '';
        final decimals = widget.service.plugin.networkState.tokenDecimals ?? 12;

        final balancesInfo = widget.service.plugin.balances.native;
        final tokens = widget.service.plugin.balances.tokens;
        final extraTokens = widget.service.plugin.balances.extraTokens;

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
              height: 28,
              child: Image.asset('assets/images/logo.png'),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).cardColor),
                onPressed: () async {
                  await Navigator.of(context)
                      .pushNamed(NetworkSelectPage.route);
                  setState(() {});
                },
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
              Container(
                margin: EdgeInsets.only(left: 16, bottom: 8),
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BorderedTitle(
                      title: I18n.of(context)
                          .getDic(i18n_full_dic_app, 'assets')['assets'],
                    ),
                    widget.service.plugin.basic.isTestNet
                        ? TextTag(
                            I18n.of(context).getDic(
                                i18n_full_dic_app, 'assets')['assets.test'],
                            fontSize: 16,
                            color: Colors.red,
                            margin: EdgeInsets.only(left: 12),
                            padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                          )
                        : Container()
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 32),
                  children: <Widget>[
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
                                      ? Fmt.balanceTotal(balancesInfo)
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
                          Navigator.pushNamed(context, AssetPage.route);
                        },
                      ),
                    ),
                    Column(
                      children: tokens == null || tokens.length == 0
                          ? [Container()]
                          : tokens
                              .map((i) => TokenItem(
                                    i,
                                    decimals,
                                    detailPageRoute: i.detailPageRoute,
                                    icon: widget
                                        .service.plugin.tokenIcons[i.symbol],
                                  ))
                              .toList(),
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
                                              decimals,
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
              )
            ],
          ),
        );
      },
    );
  }
}

class TokenItem extends StatelessWidget {
  TokenItem(this.item, this.decimals, {this.detailPageRoute, this.icon});
  final TokenBalanceData item;
  final int decimals;
  final String detailPageRoute;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
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
        title: Text(item.name),
        trailing: Text(
          Fmt.priceFloorBigInt(Fmt.balanceInt(item.amount), decimals,
              lengthFixed: 3),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black54),
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
