import 'dart:async';

import 'package:app/common/components/CustomRefreshIndicator.dart';
import 'package:app/common/consts.dart';
import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/bind/accountBindPage.dart';
import 'package:app/pages/account/import/selectImportTypePage.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/pages/assets/nodeSelectPage.dart';
import 'package:app/pages/assets/transfer/transferPage.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/pages/public/AdBanner.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/textTag.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/borderedTitle.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/pages/accountQrCodePage.dart';
import 'package:polkawallet_ui/pages/qrSignerPage.dart';
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:rive/rive.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';

final assetsType = [
  "All",
  "Native",
  "ERC-20",
  "Cross-chain",
  "LP Tokens",
  "Taiga token"
];

class AssetsEVMPage extends StatefulWidget {
  AssetsEVMPage(
      this.service,
      this.plugins,
      this.connectedNode,
      this.checkJSCodeUpdate,
      this.disabledPlugins,
      this.changeNetwork,
      this.handleWalletConnect,
      this.homePageContext);

  final AppService service;
  final NetworkParams connectedNode;
  final Future<void> Function(PolkawalletPlugin) checkJSCodeUpdate;
  final Future<void> Function(String) handleWalletConnect;

  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;
  final BuildContext homePageContext;
  @override
  _AssetsEVMState createState() => _AssetsEVMState();
}

class _AssetsEVMState extends State<AssetsEVMPage> {
  final GlobalKey<CustomRefreshIndicatorState> _refreshKey =
      new GlobalKey<CustomRefreshIndicatorState>();
  bool _refreshing = false;

  Timer _priceUpdateTimer;

  int instrumentIndex = 0;

  double _rate = 1.0;

  int _assetsTypeIndex = 0;

  ScrollController _scrollController;

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

  Future<void> _updateMarketPrices() async {
    final symbol = (widget.service.plugin is PluginEvm)
        ? (widget.service.plugin as PluginEvm).nativeToken
        : '-';
    final tokens = widget.service.plugin.noneNativeTokensAll
        .map((e) => e.symbol.toUpperCase())
        .toList()
      ..add(symbol.toUpperCase());
    widget.service.assets.fetchMarketPrices(tokens);

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
        if (widget.service.plugin.basic.name == para_chain_name_karura ||
            widget.service.plugin.basic.name == para_chain_name_acala) {
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
            return PolkawalletAlertDialog(
              title: Text(dic['uos.title']),
              content: Text(dic['uos.acc.invalid']),
              actions: <Widget>[
                PolkawalletActionSheetAction(
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
          return PolkawalletAlertDialog(
            content: Column(
              children: [
                Text(dic['uos.parse']),
                Container(
                  margin: EdgeInsets.only(top: 16.h),
                  child: const CupertinoActivityIndicator(
                      color: Color(0xFF3C3C44)),
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
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(dic['uos.network']),
                  ),
            networkIndex < 0
                ? Container()
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).dividerColor, width: 0.5),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8))),
                    child: Row(
                      children: [
                        Container(
                            margin: const EdgeInsets.only(right: 8),
                            height: 32,
                            width: 32,
                            child: widget.plugins[networkIndex].basic.icon),
                        Text(
                          widget.plugins[networkIndex].basic.name.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(color: Colors.black),
                        )
                      ],
                    ),
                  ),
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(dic['uos.signer']),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).dividerColor, width: 0.5),
                  borderRadius: const BorderRadius.all(Radius.circular(8))),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    child: AddressIcon(sender.address, svg: sender.icon),
                  ),
                  Text(
                    Fmt.address(sender.address),
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        ?.copyWith(color: Colors.black),
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
              return PolkawalletAlertDialog(
                title: Text(dic['uos.title']),
                content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: confirmMsg),
                actions: <Widget>[
                  PolkawalletActionSheetAction(
                    child: Text(I18n.of(context)
                        .getDic(i18n_full_dic_ui, 'common')['cancel']),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  PolkawalletActionSheetAction(
                    isDefaultAction: true,
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
          return PolkawalletAlertDialog(
            title: Text(dic['uos.title']),
            content: Column(children: errorMsg),
            actions: <Widget>[
              PolkawalletActionSheetAction(
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
          return PolkawalletAlertDialog(
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
          return PolkawalletAlertDialog(
            title: Text(dic['uos.title']),
            content: Text(err.toString()),
            actions: <Widget>[
              PolkawalletActionSheetAction(
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
  void didUpdateWidget(covariant AssetsEVMPage oldWidget) {
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

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMarketPrices();
      _getRate();
    });
  }

  Future<void> _getRate() async {
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

  List _evmMenuItem(KeyPairData substrate, KeyPairData account) {
    if (!widget.service.plugin.basic.name.contains(para_chain_name_acala) &&
        !widget.service.plugin.basic.name.contains(para_chain_name_karura)) {
      return [];
    }

    final querying =
        (widget.service.plugin as PluginEvm).store.account.querying == true;
    if (querying && substrate == null) return [];

    String buttonTitle;
    String buttonIcon;

    if (substrate == null) {
      buttonTitle =
          I18n.of(context).getDic(i18n_full_dic_app, 'assets')['bind'];
      buttonIcon = "assets/images/bind.svg";
    } else if (account != null) {
      buttonTitle =
          I18n.of(context).getDic(i18n_full_dic_app, 'assets')['change'];
      buttonIcon = "assets/images/change.svg";
    } else {
      buttonTitle =
          I18n.of(context).getDic(i18n_full_dic_app, 'assets')['import'];
      buttonIcon = "assets/images/import.svg";
    }

    return [
      const v3.PopupMenuDivider(height: 1.0),
      v3.PopupMenuItem(
        height: 34,
        value: '2',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              buttonIcon,
              color: UI.isDarkTheme(context)
                  ? Colors.white
                  : const Color(0xFF979797),
              width: 22,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                buttonTitle,
                style: Theme.of(context).textTheme.headline5,
              ),
            )
          ],
        ),
      )
    ];
  }

  Future<void> _reloadNetwork(PolkawalletPlugin plugin) async {
    showCupertinoDialog(
      context: widget.homePageContext,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['loading']),
          content:
              const SizedBox(height: 64, child: CupertinoActivityIndicator()),
        );
      },
    );
    await widget.changeNetwork(plugin);

    ///current context is disposed
    Navigator.of(widget.homePageContext).pop();
  }

  void _evmMenuItemAction(KeyPairData substrate, KeyPairData account) async {
    final querying =
        (widget.service.plugin as PluginEvm).store.account.querying == true;
    if (querying) return;
    if (substrate == null) {
      // bind
      final res = await Navigator.of(context)
          .pushNamed(AccountBindPage.route, arguments: {"isPlugin": false});
      // update bindAccount
      if (res != null) {
        (widget.service.plugin as PluginEvm).updateSubstrateAccount();
      }
    } else if (account != null) {
      final dicPublic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
      final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
      final confirmed = await showCupertinoDialog(
        context: widget.homePageContext,
        builder: (_) {
          return PolkawalletAlertDialog(
            title: Text(dicPublic['evm.change.title']),
            content: Container(
                margin: const EdgeInsets.only(top: 8),
                child: Text(dicPublic['evm.change.tips'])),
            actions: <Widget>[
              PolkawalletActionSheetAction(
                child: Text(dic['cancel']),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              PolkawalletActionSheetAction(
                isDefaultAction: true,
                child: Text(dic['ok']),
                onPressed: () {
                  Navigator.of(widget.homePageContext).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (!confirmed) {
        return;
      }
      //change
      widget.service.store.account.setAccountType(AccountType.Substrate);

      /// set current account
      widget.service.keyring.setCurrent(account);
      final plugin = widget.service.allPlugins
          .where((element) =>
              widget.service.plugin.basic.name.contains(element.basic.name))
          .first;

      /// set new network and reload web view
      await _reloadNetwork(plugin);
      plugin.changeAccount(account);
      widget.service.store.assets.loadCache(account, plugin.basic.name);
    } else {
      //import
      await Navigator.of(context).pushNamed(SelectImportTypePage.route,
          arguments: {
            "accountType": AccountType.Substrate,
            "needChange": false
          });
      setState(() {});
    }
  }

  PreferredSizeWidget _buildAppBar(KeyPairData substrate) {
    final account = widget.service.keyring.allAccounts
        .firstWhereOrNull((element) => element.pubKey == substrate?.pubKey);
    return AppBar(
      systemOverlayStyle: UI.isDarkTheme(context)
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            child: AddressIcon(widget.service.keyringEVM.current.address,
                svg: widget.service.keyringEVM.current.icon),
          ),
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Fmt.address(widget.service.keyringEVM.current.address),
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
                                10.h,
                            width: double.infinity,
                            child: NodeSelectPage(
                                widget.service,
                                widget.plugins,
                                widget.changeNetwork,
                                widget.disabledPlugins),
                          );
                        },
                        context: context,
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      margin: EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          widget.connectedNode == null
                              ? Container(
                                  width: 9,
                                  height: 9,
                                  margin: EdgeInsets.only(right: 4),
                                  child: Center(
                                      child: RiveAnimation.asset(
                                    'assets/images/connecting.riv',
                                  )))
                              : Container(
                                  width: 9,
                                  height: 9,
                                  margin: EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                      color: UI.isDarkTheme(context)
                                          ? Color(0xFF82FF99)
                                          : Color(0xFF7D97EE),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(5.5))),
                                ),
                          Text(
                            "${widget.service.plugin.basic.name.split("-").last.toString().toUpperCase()} ${widget.service.plugin.basic.name.split("-").first.toString().toUpperCase()} +",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                .copyWith(
                                    fontWeight: FontWeight.w600, height: 1.1),
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
      leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Row(children: [
            v3.IconButton(
              isBlueBg: true,
              icon: SvgPicture.asset(
                "assets/images/icon_car.svg",
                color: UI.isDarkTheme(context) ? Colors.black : Colors.white,
                height: 22,
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
            )
          ])),
      actions: <Widget>[
        Container(
            margin: EdgeInsets.only(right: 6.w),
            child: v3.PopupMenuButton(
                offset: Offset(-12, 52),
                color: UI.isDarkTheme(context)
                    ? Color(0xA63A3B3D)
                    : Theme.of(context).cardColor,
                padding: EdgeInsets.zero,
                elevation: 3,
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Color(0x21FFFFFF), width: 0.5),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                ),
                onSelected: (value) {
                  if (widget.service.keyring.current.address != '') {
                    if (value == '0') {
                      _handleScan();
                    } else if (value == '1') {
                      Navigator.pushNamed(context, AccountQrCodePage.route);
                    } else {
                      _evmMenuItemAction(substrate, account);
                    }
                  }
                },
                itemWidth: 132.w,
                itemBuilder: (BuildContext context) {
                  return <v3.PopupMenuEntry<String>>[
                    v3.PopupMenuItem(
                      height: 34,
                      value: '0',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: SvgPicture.asset(
                                'assets/images/scan.svg',
                                color: UI.isDarkTheme(context)
                                    ? Colors.white
                                    : const Color(0xFF979797),
                                width: 20,
                              )),
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              I18n.of(context)
                                  .getDic(i18n_full_dic_app, 'assets')['scan'],
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          )
                        ],
                      ),
                    ),
                    const v3.PopupMenuDivider(height: 1.0),
                    v3.PopupMenuItem(
                      height: 34,
                      value: '1',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/qr.svg',
                            color: UI.isDarkTheme(context)
                                ? Colors.white
                                : const Color(0xFF979797),
                            width: 22,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              I18n.of(context).getDic(
                                  i18n_full_dic_app, 'assets')['QRCode'],
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          )
                        ],
                      ),
                    ),
                    ..._evmMenuItem(substrate, account)
                  ];
                },
                icon: v3.IconButton(
                  icon: Icon(
                    Icons.add,
                    color: UI.isDarkTheme(context)
                        ? Colors.white
                        : Theme.of(context).disabledColor,
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
        final symbol = (widget.service.plugin is PluginEvm)
            ? (widget.service.plugin as PluginEvm).nativeToken
            : '-';

        final substrate = (widget.service.plugin is PluginEvm)
            ? (widget.service.plugin as PluginEvm).store.account.substrate
            : null;

        const decimals = 18;

        final balancesInfo = widget.service.plugin.balances.native;
        var tokens = widget.service.plugin.noneNativeTokensAll.toList() ?? [];

        final customTokensConfig = (widget.service.plugin is PluginEvm)
            ? (widget.service.plugin as PluginEvm).store.assets.customAssets
            : {};
        if (customTokensConfig.keys.isNotEmpty) {
          tokens.retainWhere((e) => customTokensConfig[e.id]);
        } else {
          tokens = [];
        }

        // final extraTokens = widget.service.plugin.balances.extraTokens;
        final isTokensFromCache =
            widget.service.plugin.balances.isTokensFromCache;

        String tokenPrice;
        double allPrice = 0.0;
        if (widget.service.store.assets.marketPrices[symbol] != null &&
            balancesInfo != null) {
          allPrice = widget.service.store.assets.marketPrices[symbol] *
              (widget.service.store.settings.priceCurrency != "USD"
                  ? _rate
                  : 1.0) *
              Fmt.bigIntToDouble(Fmt.balanceTotal(balancesInfo), decimals);
          tokenPrice = Fmt.priceCeil(allPrice);
        }

        tokens.forEach(
          (element) {
            if (widget.service.store.assets
                    .marketPrices[element.symbol.toUpperCase()] !=
                null) {
              allPrice += widget.service.store.assets
                      .marketPrices[element.symbol.toUpperCase()] *
                  (widget.service.store.settings.priceCurrency != "USD"
                      ? _rate
                      : 1.0) *
                  Fmt.bigIntToDouble(
                      BigInt.parse(element.amount), element.decimals);
            }
          },
        );

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(substrate),
          body: CustomRefreshIndicator(
              edgeOffset: 16,
              key: _refreshKey,
              onRefresh: _updateBalances,
              child: ListView(controller: _scrollController, children: [
                StickyHeader(
                    header: Container(),
                    content: Column(
                      children: <Widget>[
                        GestureDetector(
                            onTap: () {
                              widget.service.store.settings.setIsHideBalance(
                                  !widget.service.store.settings.isHideBalance);
                            },
                            child: Container(
                              margin:
                                  EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                              width: 200,
                              height: 54,
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  color: UI.isDarkTheme(context)
                                      ? Color.fromARGB(255, 23, 25, 26)
                                      : Colors.white,
                                  border: UI.isDarkTheme(context)
                                      ? Border.all(
                                          color: const Color(0xFFFFFFFF)
                                              .withAlpha(38),
                                          width: 1)
                                      : null,
                                  boxShadow: UI.isDarkTheme(context)
                                      ? [
                                          BoxShadow(
                                              color: Colors.white.withAlpha(84),
                                              offset: const Offset(-1.0, -1.0),
                                              blurRadius: 2.0,
                                              spreadRadius: 0.0,
                                              blurStyle: BlurStyle.inner),
                                          BoxShadow(
                                              color: Colors.white.withAlpha(84),
                                              offset: const Offset(1.0, 1.0),
                                              blurRadius: 2.0,
                                              spreadRadius: 0.0,
                                              blurStyle: BlurStyle.inner),
                                        ]
                                      : [
                                          BoxShadow(
                                              color: Colors.black.withAlpha(84),
                                              offset: const Offset(-1.0, -1.0),
                                              blurRadius: 8.0,
                                              spreadRadius: 0.0,
                                              blurStyle: BlurStyle.inner),
                                        ]),
                              child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.filled(
                                        3,
                                        Container(
                                          height: double.infinity,
                                          width: 0.5,
                                          color: UI.isDarkTheme(context)
                                              ? Colors.white.withAlpha(40)
                                              : const Color(0xFF979797)
                                                  .withAlpha(77),
                                        )),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        balancesInfo != null &&
                                                balancesInfo.freeBalance != null
                                            ? widget.service.store.settings
                                                    .isHideBalance
                                                ? "******"
                                                : "${Fmt.priceCurrencySymbol(widget.service.store.settings.priceCurrency)} ${Fmt.priceFloorFormatter(allPrice, lengthMax: 4)}"
                                            : '--.--',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline1
                                            ?.copyWith(
                                                fontSize:
                                                    UI.getTextSize(24, context),
                                                height: 1.0),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.only(left: 5),
                                          child: SvgPicture.asset(
                                            "assets/images/hide_balance_${widget.service.store.settings.isHideBalance ? 'yes' : 'no'}.svg",
                                            height: widget.service.store
                                                    .settings.isHideBalance
                                                ? 8
                                                : 11,
                                            color: UI.isDarkTheme(context)
                                                ? Colors.white.withAlpha(127)
                                                : Colors.black.withAlpha(127),
                                          ))
                                    ],
                                  )
                                ],
                              ),
                            )),
                        Container(
                          margin: EdgeInsets.only(left: 16.w, right: 16.w),
                          child: AdBanner(widget.service, widget.connectedNode),
                        ),
                        widget.service.plugin.basic.isTestNet
                            ? Padding(
                                padding: EdgeInsets.only(top: 5.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: TextTag(
                                      I18n.of(context).getDic(i18n_full_dic_app,
                                          'assets')['assets.warn'],
                                      color: Colors.deepOrange,
                                      fontSize: UI.getTextSize(12, context),
                                      margin: EdgeInsets.all(0),
                                      padding: EdgeInsets.all(8),
                                    ))
                                  ],
                                ),
                              )
                            : Container(height: 0.h),
                        Container(
                          margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                          child: Divider(height: 1),
                        ),
                      ],
                    )),
                StickyHeader(
                    header: Container(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                BorderedTitle(
                                  title: I18n.of(context).getDic(
                                      i18n_full_dic_app, 'assets')['assets'],
                                ),
                                Expanded(
                                    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    v3.IconButton(
                                      onPressed: () => Navigator.of(context)
                                          .pushNamed('evm/assets/manage'),
                                      icon: Icon(
                                        Icons.menu,
                                        color: Theme.of(context).disabledColor,
                                        size: 20,
                                      ),
                                    )
                                  ],
                                ))
                              ],
                            ),
                            Visibility(
                                visible: widget.service.plugin.basic.name ==
                                        plugin_name_karura ||
                                    widget.service.plugin.basic.name ==
                                        plugin_name_acala,
                                child: Container(
                                    height: 30,
                                    width: double.infinity,
                                    margin: EdgeInsets.only(top: 8),
                                    child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) {
                                          final child = Center(
                                            child: Text(assetsType[index],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .button
                                                    ?.copyWith(
                                                        color:
                                                            _assetsTypeIndex ==
                                                                    index
                                                                ? Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .button
                                                                    ?.color
                                                                : Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .headline1
                                                                    ?.color,
                                                        fontSize:
                                                            UI.getTextSize(
                                                                10, context))),
                                          );
                                          return CupertinoButton(
                                            padding: EdgeInsets.all(0),
                                            onPressed: () {
                                              _scrollController.animateTo(0,
                                                  duration: Duration(
                                                      milliseconds: 500),
                                                  curve: Curves.ease);
                                              setState(() {
                                                _assetsTypeIndex = index;
                                              });
                                            },
                                            child: Container(
                                              height: 24,
                                              width: 65,
                                              child: UI.isDarkTheme(context) &&
                                                      _assetsTypeIndex != index
                                                  ? RoundedCard(
                                                      radius: 6, child: child)
                                                  : Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            _assetsTypeIndex ==
                                                                    index
                                                                ? null
                                                                : BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            6.0)),
                                                        color: _assetsTypeIndex ==
                                                                index
                                                            ? Colors.transparent
                                                            : UI.isDarkTheme(
                                                                    context)
                                                                ? Color(
                                                                    0x14FFFFFF)
                                                                : Colors.white,
                                                        border:
                                                            _assetsTypeIndex ==
                                                                    index
                                                                ? null
                                                                : Border.all(
                                                                    color: Color(
                                                                        0xFF979797),
                                                                    width: 0.2,
                                                                  ),
                                                        image: _assetsTypeIndex ==
                                                                index
                                                            ? DecorationImage(
                                                                image: AssetImage(
                                                                    'assets/images/icon_select_btn${UI.isDarkTheme(context) ? "_dark" : ""}.png'),
                                                                fit:
                                                                    BoxFit.fill,
                                                              )
                                                            : null,
                                                        boxShadow:
                                                            _assetsTypeIndex ==
                                                                    index
                                                                ? []
                                                                : [
                                                                    BoxShadow(
                                                                      offset:
                                                                          Offset(
                                                                              1,
                                                                              1),
                                                                      blurRadius:
                                                                          1,
                                                                      spreadRadius:
                                                                          0,
                                                                      color: Color(
                                                                          0x30000000),
                                                                    ),
                                                                  ],
                                                      ),
                                                      child: child,
                                                    ),
                                            ),
                                          );
                                        },
                                        separatorBuilder: (context, index) =>
                                            Container(width: 9),
                                        itemCount: assetsType.length)))
                          ],
                        )),
                    content: Container(
                      child: ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 6.h, top: 3.h),
                        children: [
                          RoundedCard(
                            margin: EdgeInsets.only(left: 16.w, right: 16.w),
                            child: Column(
                              children: [
                                Visibility(
                                    visible: _assetsTypeIndex == 0 ||
                                        _assetsTypeIndex == 1,
                                    child: ListTile(
                                      horizontalTitleGap: 10,
                                      leading: Container(
                                        child: TokenIcon(
                                          symbol,
                                          widget.service.plugin.tokenIcons,
                                          size: 30,
                                        ),
                                      ),
                                      title: Text(
                                        symbol,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5
                                            .copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: UI.getTextSize(
                                                    18, context)),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                              balancesInfo != null &&
                                                      balancesInfo.freeBalance !=
                                                          null
                                                  ? widget
                                                          .service
                                                          .store
                                                          .settings
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: balancesInfo?.isFromCache ==
                                                              false
                                                          ? Theme.of(context)
                                                              .textTheme
                                                              .headline1
                                                              .color
                                                          : Theme.of(context)
                                                              .dividerColor)),
                                          Text(
                                            widget.service.store.settings
                                                    .isHideBalance
                                                ? "******"
                                                : '≈ ${Fmt.priceCurrencySymbol(widget.service.store.settings.priceCurrency)}${tokenPrice ?? '--.--'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline6
                                                .copyWith(
                                                    fontFamily:
                                                        UI.getFontFamily(
                                                            'TitilliumWeb',
                                                            context)),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // Navigator.pushNamed(
                                        //     context, AssetPage.route);

                                        Navigator.of(context).pushNamed(
                                            '/assets/token/detail',
                                            arguments: TokenBalanceData(
                                              amount:
                                                  Fmt.balanceTotal(balancesInfo)
                                                      .toString(),
                                              decimals: decimals,
                                              id: symbol.toUpperCase(),
                                              symbol: symbol.toUpperCase(),
                                              name: symbol.toUpperCase(),
                                              tokenNameId: symbol.toUpperCase(),
                                            )
                                              ..priceCurrency = widget.service
                                                  .store.settings.priceCurrency
                                              ..priceRate = _rate
                                              ..getPrice = () => widget
                                                  .service
                                                  .store
                                                  .assets
                                                  .marketPrices[symbol]);
                                      },
                                    )),
                                Visibility(
                                    visible:
                                        tokens != null && tokens.length > 0,
                                    child: Column(
                                      children: (tokens ?? [])
                                          .map((TokenBalanceData i) {
                                        // we can use token price form plugin or from market
                                        final price = (i.getPrice != null
                                                ? i.getPrice()
                                                : i.price) ??
                                            widget.service.store.assets
                                                    .marketPrices[
                                                i.symbol.toUpperCase()] ??
                                            0.0;
                                        return TokenItem(
                                          i,
                                          i.decimals,
                                          isFromCache: isTokensFromCache,
                                          detailPageRoute: i.detailPageRoute,
                                          marketPrice: price,
                                          icon: TokenIcon(
                                            i.id,
                                            widget.service.plugin.tokenIcons,
                                            symbol: i.id,
                                            size: 30,
                                          ),
                                          isHideBalance: widget.service.store
                                              .settings.isHideBalance,
                                          priceCurrency: widget.service.store
                                              .settings.priceCurrency,
                                          priceRate: _rate,
                                        );
                                      }).toList(),
                                    )),
                                // Visibility(
                                //   visible: extraTokens == null ||
                                //       extraTokens.length == 0,
                                //   child: Column(
                                //       children: (extraTokens ?? [])
                                //           .map((ExtraTokenData i) {
                                //     return Column(
                                //       crossAxisAlignment:
                                //           CrossAxisAlignment.start,
                                //       children: [
                                //         Padding(
                                //           padding: EdgeInsets.only(top: 16.h),
                                //           child: BorderedTitle(
                                //             title: i.title,
                                //           ),
                                //         ),
                                //         Column(
                                //           children: i.tokens
                                //               .map((e) => TokenItem(
                                //                     e,
                                //                     e.decimals,
                                //                     isFromCache:
                                //                         isTokensFromCache,
                                //                     detailPageRoute:
                                //                         e.detailPageRoute,
                                //                     icon: widget.service.plugin
                                //                         .tokenIcons[e.symbol],
                                //                     isHideBalance: widget
                                //                         .service
                                //                         .store
                                //                         .settings
                                //                         .isHideBalance,
                                //                     priceCurrency: widget
                                //                         .service
                                //                         .store
                                //                         .settings
                                //                         .priceCurrency,
                                //                     priceRate: _rate,
                                //                   ))
                                //               .toList(),
                                //         )
                                //       ],
                                //     );
                                //   }).toList()),
                                // )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
              ])),
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
      this.priceCurrency,
      this.priceRate});
  final TokenBalanceData item;
  final int decimals;
  final double marketPrice;
  final String detailPageRoute;
  final Widget icon;
  final bool isFromCache;
  final bool isHideBalance;
  final String priceCurrency;
  final double priceRate;

  @override
  Widget build(BuildContext context) {
    final balanceTotal =
        Fmt.balanceInt(item.amount) + Fmt.balanceInt(item.reserved);
    return Column(
      children: [
        Divider(height: 1),
        ListTile(
          horizontalTitleGap: 10,
          leading: Container(
            child: icon ??
                CircleAvatar(
                  child: Text(item.symbol.substring(0, 2)),
                ),
          ),
          title: Text(
            item.name,
            style: Theme.of(context).textTheme.headline5.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: UI.getTextSize(18, context)),
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
                        ? Theme.of(context).textTheme.headline1.color
                        : Theme.of(context).dividerColor),
              ),
              marketPrice != null && marketPrice > 0
                  ? Text(
                      isHideBalance
                          ? "******"
                          : '≈ ${Fmt.priceCurrencySymbol(priceCurrency)}${Fmt.priceFloor(Fmt.bigIntToDouble(balanceTotal, decimals) * marketPrice * priceRate)}',
                      style: Theme.of(context).textTheme.headline6.copyWith(
                          fontFamily:
                              UI.getFontFamily('TitilliumWeb', context)),
                    )
                  : Container(height: 0, width: 8),
            ],
          ),
          onTap: detailPageRoute == null
              ? null
              : () {
                  Navigator.of(context).pushNamed(detailPageRoute,
                      arguments: item
                        ..priceCurrency = priceCurrency
                        ..priceRate = priceRate
                        ..getPrice = () => marketPrice);
                },
        )
      ],
    );
  }
}
