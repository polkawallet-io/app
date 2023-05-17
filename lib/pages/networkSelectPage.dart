import 'package:app/common/components/jumpToLink.dart';
import 'package:app/common/consts.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/pages/account/create/createAccountPage.dart';
import 'package:app/pages/account/import/selectImportTypePage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class NetworkSelectPage extends StatefulWidget {
  NetworkSelectPage(
      this.service, this.plugins, this.disabledPlugins, this.changeNetwork);

  static final String route = '/network';

  final AppService service;
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  @override
  _NetworkSelectPageState createState() => _NetworkSelectPageState();
}

class _NetworkSelectPageState extends State<NetworkSelectPage> {
  int _appVersionCode = 0;
  bool _isEvm = false;

  @override
  void initState() {
    super.initState();

    _isEvm = widget.service.store.account.accountType == AccountType.Evm;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var appVersionCode = await Utils.getBuildNumber();
      setState(() {
        _appVersionCode = appVersionCode;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final plugins = widget.plugins.toList();
    final config = widget.service.store.settings.pluginsConfig;
    if (config != null) {
      plugins.removeWhere((i) {
        final List disabled = (config[i.basic.name] ?? {})['disabled'];
        if (disabled != null) {
          return disabled.contains(_appVersionCode) || disabled.contains(0);
        }
        return false;
      });
    }
    return Scaffold(
      backgroundColor:
          UI.isDarkTheme(context) ? Color(0xFF18191B) : Colors.white,
      appBar: AppBar(
          title: Text(I18n.of(context)
              .getDic(i18n_full_dic_app, 'profile')['setting.network']),
          centerTitle: true,
          leading: BackBtn(),
          actions: [
            GestureDetector(
                onTap: () {
                  setState(() {
                    _isEvm = !_isEvm;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: v3.IconButton(
                      isBlueBg: true,
                      icon: SvgPicture.asset(
                        "assets/images/${_isEvm ? "evm" : "substrate"}.svg",
                        color: UI.isDarkTheme(context)
                            ? Colors.black
                            : Colors.white,
                        height: 22,
                      )),
                ))
          ],
          elevation: 2),
      body: NetworkSelectWidget(
        widget.service,
        plugins,
        widget.disabledPlugins,
        widget.changeNetwork,
        isEvm: _isEvm,
      ),
    );
  }
}

class _NetworkItemActive extends StatelessWidget {
  _NetworkItemActive({this.icon});
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        Padding(
            padding: EdgeInsets.only(left: 10),
            child: Image.asset(
              "assets/images/selectWallet_select_bg${UI.isDarkTheme(context) ? "_dark" : ""}.png",
              fit: BoxFit.contain,
              width: 51.w,
            )),
        Container(
            padding: EdgeInsets.only(left: UI.isDarkTheme(context) ? 11 : 13),
            width: UI.isDarkTheme(context) ? 45.w : 50.w,
            height: UI.isDarkTheme(context) ? 45.w : 50.w,
            alignment: Alignment.centerLeft,
            child: SizedBox(child: icon, height: 30, width: 30),
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(
                        "assets/images/selectWallet_select${UI.isDarkTheme(context) ? "_dark" : ""}.png"),
                    fit: BoxFit.fill)))
      ],
    );
  }
}

class _CommunityPluginNote extends StatelessWidget {
  _CommunityPluginNote(this.pluginName, this.disabled);
  final String pluginName;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).cardColor, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(
                dic['plugin.note'] +
                    pluginName.toUpperCase() +
                    dic['plugin.team'],
                style: TextStyle(fontSize: UI.getTextSize(12, context)),
              )),
              SvgPicture.asset(
                'assets/images/public/github_logo.svg',
                width: 16,
                color: Theme.of(context).textTheme.headline1.color,
              ),
              JumpToLink(
                plugin_github_links[pluginName],
                text: '',
                color: Theme.of(context).textTheme.headline1?.color,
              )
            ],
          ),
          Visibility(visible: disabled, child: Divider(height: 1)),
          Visibility(visible: disabled, child: Text(dic['plugin.disable'])),
        ],
      ),
    );
  }
}

class NetworkSelectWidget extends StatefulWidget {
  NetworkSelectWidget(
      this.service, this.plugins, this.disabledPlugins, this.changeNetwork,
      {Key key, this.isEvm})
      : super(key: key);

  final AppService service;
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;
  bool isEvm = false;

  @override
  State<NetworkSelectWidget> createState() => _NetworkSelectWidgetState();
}

class _NetworkSelectWidgetState extends State<NetworkSelectWidget> {
  PluginDisabled _pluginDisabledSelected;
  PolkawalletPlugin _selectedNetwork;
  bool _networkChanging = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _selectedNetwork = widget.service.plugin;
      });
    });
  }

  @override
  void didUpdateWidget(covariant NetworkSelectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEvm != oldWidget.isEvm) {
      setState(() {
        if (widget.isEvm) {
          if (widget.service.plugin is PluginEvm) {
            _selectedNetwork = widget.service.plugin;
          } else {
            final ethNetworks =
                PluginEvm(config: widget.service.store.settings.ethConfig)
                    .networkList();
            _selectedNetwork = PluginEvm(
                networkName: ethNetworks[0],
                config: widget.service.store.settings.ethConfig);
          }
        } else {
          if (widget.service.plugin is! PluginEvm) {
            _selectedNetwork = widget.service.plugin;
          } else {
            _selectedNetwork = widget.plugins[0];
          }
        }
      });
    }
  }

  void _disconnectWC() {
    if (widget.service.store.account.wcSessionURI != null) {
      widget.service.wc.disconnect();
    }
    final v2sessions = widget.service.store.account.wcV2Sessions.toList();
    if (v2sessions.isNotEmpty) {
      for (var e in v2sessions) {
        widget.service.wc.disconnectV2(e.topic);
      }
    }
  }

  Future<void> _doSelect(KeyPairData i) async {
    final isCurrentNetwork =
        _selectedNetwork.basic.name == widget.service.plugin.basic.name;
    final currentAddress = widget.service.keyring.current.address;
    if (i.address != currentAddress || !isCurrentNetwork) {
      final isWalletConnectAlive =
          widget.service.store.account.wcV2Sessions.isNotEmpty;
      widget.service.store.account.setAccountType(AccountType.Substrate);
      widget.service.keyring.setCurrent(i);
      if (!isCurrentNetwork) {
        if (isWalletConnectAlive) {
          _disconnectWC();
        }

        /// set new network and reload web view
        await _reloadNetwork();

        _selectedNetwork.changeAccount(i);
      } else {
        widget.service.plugin.changeAccount(i);

        if (isWalletConnectAlive) {
          widget.service.wc.updateSession(i.address);
        }
      }

      widget.service.store.assets.loadCache(i, _selectedNetwork.basic.name);
    }
  }

  Future<void> _doSelectEvm(EthWalletData i) async {
    final isCurrentNetwork = widget.service.plugin is PluginEvm &&
        (_selectedNetwork as PluginEvm).network ==
            (widget.service.plugin as PluginEvm).network;
    final currentAddress = widget.service.keyringEVM.current.address;
    if (i.address != currentAddress || !isCurrentNetwork) {
      final isWalletConnectAlive =
          widget.service.store.account.wcSessionURI != null ||
              widget.service.store.account.wcV2Sessions.isNotEmpty;

      widget.service.store.account.setAccountType(AccountType.Evm);
      widget.service.keyringEVM.setCurrent(i);
      if (!isCurrentNetwork) {
        if (isWalletConnectAlive) {
          _disconnectWC();
        }

        /// set new network and reload web view
        await _reloadNetwork();

        _selectedNetwork.changeAccount(i.toKeyPairData());
      } else {
        widget.service.plugin.changeAccount(i.toKeyPairData());

        if (isWalletConnectAlive) {
          widget.service.wc.updateSession(i.address);
        }
      }
    }
  }

  Future<void> _onSelect(dynamic i) async {
    final navigator = Navigator.of(context);
    if (widget.isEvm) {
      await _doSelectEvm(i as EthWalletData);
    } else {
      await _doSelect(i as KeyPairData);
    }
    navigator.pop(_selectedNetwork);
  }

  Future<void> _reloadNetwork() async {
    final pageNavigator = Navigator.of(context);
    setState(() {
      _networkChanging = true;
    });
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['loading']),
          content: Container(height: 64, child: CupertinoActivityIndicator()),
        );
      },
    );
    if (widget.isEvm !=
        (widget.service.store.account.accountType == AccountType.Evm)) {
      widget.service.store.account.setAccountType(
          widget.isEvm ? AccountType.Evm : AccountType.Substrate);
    }
    await widget.changeNetwork(_selectedNetwork);

    pageNavigator.pop();
    if (mounted) {
      setState(() {
        _networkChanging = false;
      });
    }
  }

  Future<void> _onCreateAccount(int isImport) async {
    await Navigator.of(context).pushNamed(
        isImport == 0 ? CreateAccountPage.route : SelectImportTypePage.route,
        arguments: {
          "accountType": widget.isEvm ? AccountType.Evm : AccountType.Substrate
        });
    if (widget.service.store.account.accountCreated &&
        _selectedNetwork.basic.name != widget.service.plugin.basic.name) {
      await _reloadNetwork();
    }
  }

  Widget netWorkItem(Function() onTap, Widget icon) {
    return Container(
        margin: EdgeInsets.only(left: 6.w),
        width: 48.w,
        height: 64.h,
        child: Center(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                  padding: EdgeInsets.fromLTRB(
                      6,
                      6,
                      UI.isDarkTheme(context) ? 6 : 10,
                      UI.isDarkTheme(context) ? 6 : 10),
                  child: SizedBox(child: icon, height: 22, width: 22),
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              "assets/images/selectWallet_unselect${UI.isDarkTheme(context) ? "_dark" : ""}.png"),
                          fit: BoxFit.fill)))),
        ));
  }

  List<Widget> _buildAccountList() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final name =
        _selectedNetwork?.basic?.name ?? _pluginDisabledSelected?.name ?? '';

    /// first item is current account
    List<dynamic> accounts = [];
    final dynamic current = widget.isEvm
        ? widget.service.keyringEVM.current
        : widget.service.keyring.current;
    if (current.address != null) {
      accounts.add(current);
    }

    /// add optional accounts
    accounts.addAll(!widget.isEvm
        ? widget.service.keyring.optionals
        : widget.service.keyringEVM.optionals);
    final List<Widget> accountWidgets = [];
    if (_selectedNetwork != null) {
      final bool isCurrentNetwork =
          _selectedNetwork.basic.name == widget.service.plugin.basic.name;
      accountWidgets.addAll(accounts.map((i) {
        final addressMap = widget.service.keyring.store
            .pubKeyAddressMap[_selectedNetwork.basic.ss58.toString()];
        final address = !widget.isEvm
            ? (addressMap != null
                ? addressMap[i.pubKey]
                : widget.service.keyring.current.address)
            : i.address;
        final String accIndex = !widget.isEvm
            ? isCurrentNetwork &&
                    i.indexInfo != null &&
                    i.indexInfo['accountIndex'] != null
                ? '${i.indexInfo['accountIndex']}\n'
                : ''
            : "";
        final isCurrent = isCurrentNetwork &&
            i.address ==
                (widget.service.store.account.accountType ==
                        AccountType.Substrate
                    ? widget.service.keyring.current.address
                    : widget.service.keyringEVM.current.address);

        final substrate = (widget.service.plugin is PluginEvm)
            ? (widget.service.plugin as PluginEvm).store?.account?.substrate
            : null;
        if (substrate != null && substrate.name == null) {
          final index = widget.service.keyring.allAccounts
              .indexWhere(((element) => element.pubKey == substrate.pubKey));
          if (index >= 0) {
            (widget.service.plugin as PluginEvm).store.account.setSubstrate(
                substrate
                  ..name = widget.service.keyring.allAccounts[index].name
                  ..observation =
                      widget.service.keyring.allAccounts[index].observation,
                widget.service.keyringEVM.current.toKeyPairData());
          }
        }
        return Column(
          children: [
            isCurrent && widget.isEvm
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                AddressIcon(address, svg: i.icon),
                                Padding(
                                    padding: EdgeInsets.only(left: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                            padding: EdgeInsets.only(bottom: 3),
                                            child: Text(
                                              UI.accountName(context, i),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5,
                                            )),
                                        Text('$accIndex${Fmt.address(address)}',
                                            maxLines: 2,
                                            style: TextStyle(
                                                fontSize:
                                                    UI.getTextSize(10, context),
                                                fontWeight: FontWeight.w300,
                                                color: UI.isDarkTheme(context)
                                                    ? Colors.white
                                                        .withAlpha(191)
                                                    : Color(0xFF565554),
                                                fontFamily: UI.getFontFamily(
                                                    'SF_Pro', context)))
                                      ],
                                    ))
                              ],
                            ),
                            Image.asset(
                              "assets/images/${isCurrent ? "icon_circle_select${UI.isDarkTheme(context) ? "_dark" : ""}.png" : "icon_circle_unselect${UI.isDarkTheme(context) ? "_dark" : ""}.png"}",
                              fit: BoxFit.contain,
                              width: 16.w,
                            )
                          ],
                        ),
                        substrate != null
                            ? Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Row(
                                  children: [
                                    Padding(
                                        padding: EdgeInsets.only(
                                            left: 16, right: 12),
                                        child: Stack(
                                          alignment:
                                              AlignmentDirectional.bottomStart,
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .toggleableActiveColor,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  2))),
                                            ),
                                            Container(
                                              width: 18,
                                              height: 9,
                                              margin: const EdgeInsets.only(
                                                  left: 1.5, bottom: 1.5),
                                              decoration: BoxDecoration(
                                                  color: UI.isDarkTheme(context)
                                                      ? Color(0xFF18191B)
                                                      : Colors.white,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  2))),
                                            )
                                          ],
                                        )),
                                    AddressIcon(
                                      substrate.address,
                                      svg: substrate.icon,
                                      size: 18,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 5),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            substrate.name != null
                                                ? UI.accountName(
                                                    context, substrate)
                                                : "",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                ?.copyWith(
                                                    fontSize: UI.getTextSize(
                                                        10, context)),
                                          ),
                                          Text(Fmt.address(substrate.address),
                                              maxLines: 2,
                                              style: TextStyle(
                                                  fontSize: UI.getTextSize(
                                                      8, context),
                                                  fontWeight: FontWeight.w300,
                                                  color: UI.isDarkTheme(context)
                                                      ? Colors.white
                                                          .withAlpha(191)
                                                      : Color(0xFF565554),
                                                  fontFamily: UI.getFontFamily(
                                                      'SF_Pro', context)))
                                        ],
                                      ),
                                    )
                                  ],
                                ))
                            : Container()
                      ],
                    ),
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    minLeadingWidth: 0,
                    leading: AddressIcon(address, svg: i.icon),
                    title: Text(
                      UI.accountName(context, i),
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    subtitle: Text('$accIndex${Fmt.address(address)}',
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: UI.getTextSize(10, context),
                            fontWeight: FontWeight.w300,
                            color: UI.isDarkTheme(context)
                                ? Colors.white.withAlpha(191)
                                : Color(0xFF565554),
                            fontFamily: UI.getFontFamily('SF_Pro', context))),
                    trailing: Image.asset(
                      "assets/images/${isCurrent ? "icon_circle_select${UI.isDarkTheme(context) ? "_dark" : ""}.png" : "icon_circle_unselect${UI.isDarkTheme(context) ? "_dark" : ""}.png"}",
                      fit: BoxFit.contain,
                      width: 16.w,
                    ),
                    onTap: _networkChanging ? null : () => _onSelect(i),
                  ),
            Divider(
              height: 1,
            )
          ],
        );
      }).toList());
    }

    final List<Widget> res = [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name.toUpperCase(),
            style: Theme.of(context).textTheme.headline3?.copyWith(
                fontSize: 32, fontWeight: FontWeight.bold, height: 1.0),
          ),
        ],
      ),
      Visibility(
          visible: plugin_from_community.indexOf(name) > -1,
          child: _CommunityPluginNote(name, false)),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: SingleChildScrollView(
                child: Column(
                  children: accountWidgets,
                ),
              ))),
      Column(
        children: [
          GestureDetector(
            child: Container(
                width: double.infinity,
                child: RoundedCard(
                    color: UI.isDarkTheme(context) ? null : Color(0xFFEBEAE8),
                    margin: EdgeInsets.only(top: 4.h, bottom: 16.h),
                    brightBoxShadow: const [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 2.0,
                        spreadRadius: 1.0,
                        offset: Offset(
                          1.0,
                          1.0,
                        ),
                      )
                    ],
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: SvgPicture.asset(
                            "assets/images/icon_add${UI.isDarkTheme(context) ? "_dark" : ""}.svg",
                            width: 16.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          dic['create'],
                          style: Theme.of(context).textTheme.headline4,
                        )
                      ],
                    ))),
            onTap: () => _onCreateAccount(0),
          ),
          Container(
            width: 16.h,
          ),
          GestureDetector(
            child: Container(
                width: double.infinity,
                child: RoundedCard(
                    color: UI.isDarkTheme(context) ? null : Color(0xFFEBEAE8),
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(10),
                    brightBoxShadow: const [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 2.0,
                        spreadRadius: 1.0,
                        offset: Offset(
                          1.0,
                          1.0,
                        ),
                      )
                    ],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: SvgPicture.asset(
                            "assets/images/icon_add${UI.isDarkTheme(context) ? "_dark" : ""}.svg",
                            width: 16.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          dic['import'],
                          style: Theme.of(context).textTheme.headline4,
                        )
                      ],
                    ))),
            onTap: () => _onCreateAccount(1),
          )
        ],
      )
    ];

    return res;
  }

  List<Widget> _buildPluginDisabled() {
    return [
      Text(
        _pluginDisabledSelected.name.toUpperCase(),
        style: Theme.of(context).textTheme.headline3,
      ),
      _CommunityPluginNote(_pluginDisabledSelected.name, true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // left side bar
        Padding(
            padding: EdgeInsets.only(top: 20.h, right: 15),
            child: Stack(
              children: [
                Container(
                  width: 54.w,
                  // color: Theme.of(context).cardColor,
                  decoration: BoxDecoration(
                    color: UI.isDarkTheme(context)
                        ? Color(0x26FFFFFF)
                        : Color(0xFFF3F1ED),
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(24.w)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3.0,
                          spreadRadius: 1.0,
                          offset: Offset(2.0, 2.0))
                    ],
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 16.h, bottom: 10.h),
                    child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(left: 12.w, right: 8.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/logo_text_line2${UI.isDarkTheme(context) ? "_dark" : ""}.png',
                                    width: 32.w,
                                  ),
                                  Container(
                                    margin:
                                        EdgeInsets.only(top: 8.h, bottom: 8.h),
                                    height: 4.h,
                                    width: 34.w,
                                    decoration: BoxDecoration(
                                        border: Border.symmetric(
                                            horizontal: BorderSide(
                                                color: UI.isDarkTheme(context)
                                                    ? Color(0xFF9E9E9E)
                                                    : Color(0xFFCCCAC6)))),
                                  )
                                ],
                              ),
                            ),
                            ...(widget.isEvm
                                    ? PluginEvm(
                                            config: widget.service.store
                                                .settings.ethConfig)
                                        .networkList()
                                    : widget.plugins)
                                .map((e) {
                              if (e is PolkawalletPlugin) {
                                final isCurrent = e.basic.name ==
                                    _selectedNetwork?.basic?.name;
                                return isCurrent
                                    ? _NetworkItemActive(icon: e.basic.icon)
                                    : netWorkItem(() {
                                        if (!isCurrent) {
                                          setState(() {
                                            _selectedNetwork = e;
                                            _pluginDisabledSelected = null;
                                          });
                                        }
                                      },
                                        isCurrent
                                            ? e.basic.icon
                                            : Image.asset(
                                                'assets/images/plugins/logo_${e.basic.name.toLowerCase()}_grey${UI.isDarkTheme(context) ? "_dark" : ""}.png'));
                              } else {
                                final network = e as String;
                                final isCurrent = _selectedNetwork
                                        is PluginEvm &&
                                    e ==
                                        (_selectedNetwork as PluginEvm).network;
                                return isCurrent
                                    ? _NetworkItemActive(
                                        icon: PluginEvm.getIcon(e))
                                    : netWorkItem(() {
                                        if (!isCurrent) {
                                          setState(() {
                                            _selectedNetwork = PluginEvm(
                                                networkName: e,
                                                config: widget.service.store
                                                    .settings.ethConfig);
                                            _pluginDisabledSelected = null;
                                          });
                                        }
                                      },
                                        isCurrent
                                            ? PluginEvm.getIcon(e)
                                            : Image.asset(
                                                'assets/images/plugins/logo_evm_${network.toLowerCase()}_grey${UI.isDarkTheme(context) ? "_dark" : ""}.png'));
                              }
                            }).toList(),
                            ...(widget.isEvm ? [] : widget.disabledPlugins)
                                .map((e) {
                              final isCurrent =
                                  e.name == _pluginDisabledSelected?.name;
                              return isCurrent
                                  ? _NetworkItemActive(icon: e.icon)
                                  : netWorkItem(() {
                                      if (_pluginDisabledSelected?.name !=
                                          e.name) {
                                        setState(() {
                                          _pluginDisabledSelected = e;
                                          _selectedNetwork = null;
                                        });
                                      }
                                    }, e.icon);
                            }).toList()
                          ],
                          // children: sideBar,
                        ))),
              ],
            )),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 112,
              height: 23.5,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius:
                    BorderRadius.only(bottomLeft: Radius.circular(20.w)),
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.2, 0.5, 1],
                    colors: widget.isEvm
                        ? [
                            Color(0xFF1DCA80),
                            Color(0xFF10B95D),
                            Color(0xFF9ABD16)
                          ]
                        : [
                            Color(0xFFFF4C3B),
                            Color(0xFFE40C5B),
                            Color(0xFF645AFF)
                          ]),
              ),
            ),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: _pluginDisabledSelected == null
                          ? _buildAccountList()
                          : _buildPluginDisabled(),
                    ))),
          ],
        ))
      ],
    );
  }
}
