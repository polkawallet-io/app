import 'package:app/common/consts.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/pages/account/createAccountEntryPage.dart';
import 'package:app/pages/public/karCrowdLoanPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairETHData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

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

class _NetworkSelectPageState extends State<NetworkSelectPage>
    with SingleTickerProviderStateMixin {
  PluginDisabled _pluginDisabledSelected;
  PolkawalletPlugin _selectedNetwork;
  bool _networkChanging = false;

  List<PolkawalletPlugin> substratePlugins;
  List<PolkawalletPlugin> etheremPlugins;

  List<PluginDisabled> substrateDisabledPlugins;
  List<PluginDisabled> etheremDisabledPlugins;

  TabController tabController;

  Future<void> _reloadNetwork() async {
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
    await widget.changeNetwork(_selectedNetwork);

    // if (mounted) {
    //   Navigator.of(context).pop();
    //   setState(() {
    //     _networkChanging = false;
    //   });
    // }
  }

  Future<void> _onSelect(KeyPairData i) async {
    bool isCurrentNetwork =
        _selectedNetwork.basic.name == widget.service.plugin.basic.name &&
            _selectedNetwork.basic.pluginType ==
                widget.service.plugin.basic.pluginType;
    if (i.address != widget.service.keyring.current.address ||
        !isCurrentNetwork) {
      /// set current account
      if (_selectedNetwork.basic.pluginType == PluginType.Etherem) {
        widget.service.keyringETH.setCurrent(i);
      } else {
        widget.service.keyring.setCurrent(i);
      }

      /// If it's a different pluginType
      if (_selectedNetwork.basic.pluginType !=
          widget.service.plugin.basic.pluginType) {
        /// clear other current account
        if (_selectedNetwork.basic.pluginType == PluginType.Etherem) {
          widget.service.keyring.setCurrent(KeyPairData());
        } else {
          widget.service.keyringETH.setCurrent(KeyPairETHData());
        }
      }

      if (!isCurrentNetwork) {
        /// set new network and reload web view
        await _reloadNetwork();

        _selectedNetwork.changeAccount(i);
      } else {
        widget.service.plugin.changeAccount(i);
      }

      widget.service.store.assets.loadCache(i, _selectedNetwork.basic.name);
    }
    Navigator.of(context).pop(_selectedNetwork);
  }

  Future<void> _onCreateAccount() async {
    bool isCurrentNetwork =
        _selectedNetwork.basic.name == widget.service.plugin.basic.name;
    if (!isCurrentNetwork) {
      await _reloadNetwork();
    }
    Navigator.of(context).pushNamed(CreateAccountEntryPage.route);
  }

  List<Widget> _buildAccountList(PluginType pluginType) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    String name = '';
    name = _selectedNetwork != null &&
            pluginType == _selectedNetwork.basic.pluginType
        ? _selectedNetwork.basic.name
        : _pluginDisabledSelected != null &&
                pluginType == _pluginDisabledSelected.pluginType
            ? _pluginDisabledSelected.name
            : "";

    final List<Widget> res = [
      Text(
        name.toUpperCase(),
        style: Theme.of(context).textTheme.headline4,
      ),
      plugin_from_community.indexOf(name) > -1
          ? _CommunityPluginNote(name, false)
          : Container(),
      GestureDetector(
        child: RoundedCard(
          margin: EdgeInsets.only(top: 8, bottom: 16),
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).unselectedWidgetColor,
              ),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  dic['add'],
                  style: Theme.of(context).textTheme.headline4,
                ),
              )
            ],
          ),
        ),
        onTap: () => _onCreateAccount(),
      ),
    ];

    final bool isCurrentNetwork =
        _selectedNetwork?.basic?.name == widget.service.plugin.basic.name &&
            _selectedNetwork?.basic?.pluginType ==
                widget.service.plugin.basic.pluginType;
    if (pluginType == PluginType.Etherem) {
      /// first item is current account
      List<KeyPairETHData> accounts = [];
      if (widget.service.keyringETH.current != null &&
          widget.service.keyringETH.current.address != null) {
        accounts = [widget.service.keyringETH.current];
      }

      /// add optional accounts
      accounts.addAll(widget.service.keyringETH.optionals);

      res.addAll(accounts.map((i) {
        // final String accIndex = isCurrentNetwork &&
        //         i.indexInfo != null &&
        //         i.indexInfo['accountIndex'] != null
        //     ? '${i.indexInfo['accountIndex']}\n'
        //     : '';
        final double padding = 0;
        final isCurrent = isCurrentNetwork &&
            i.address == widget.service.keyringETH.current.address;
        return _buildRoundedCard(isCurrent, padding, i.address, i.icon, "", i);
      }).toList());
    } else {
      /// first item is current account
      List<KeyPairData> accounts = [];
      if (widget.service.keyring.current != null &&
          widget.service.keyring.current.pubKey != null) {
        accounts = [widget.service.keyring.current];
      }

      /// add optional accounts
      accounts.addAll(widget.service.keyring.optionals);

      if (_selectedNetwork != null) {
        res.addAll(accounts.map((i) {
          final addressMap = widget.service.keyring.store
              .pubKeyAddressMap[_selectedNetwork.basic.ss58.toString()];
          final address = addressMap != null
              ? addressMap[i.pubKey]
              : widget.service.keyring.current.address;
          final String accIndex = isCurrentNetwork &&
                  i.indexInfo != null &&
                  i.indexInfo['accountIndex'] != null
              ? '${i.indexInfo['accountIndex']}\n'
              : '';
          final double padding = accIndex.isEmpty ? 0 : 7;
          final isCurrent = isCurrentNetwork &&
              i.address == widget.service.keyring.current.address;
          return _buildRoundedCard(isCurrent, padding, address, i.icon, "", i);
        }).toList());
      }
    }
    return res;
  }

  Widget _buildRoundedCard(bool isCurrent, double padding, String address,
      String svg, String accIndex, KeyPairData data) {
    return RoundedCard(
      border: isCurrent
          ? Border.all(color: Theme.of(context).primaryColorLight)
          : Border.all(color: Theme.of(context).cardColor),
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.only(top: padding, bottom: padding),
      child: ListTile(
        leading: AddressIcon(address, svg: data.icon),
        title: Text(UI.accountName(context, data)),
        subtitle: Text('$accIndex${Fmt.address(address)}', maxLines: 2),
        trailing: isCurrent
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              )
            : Container(width: 8),
        onTap: _networkChanging ? null : () => _onSelect(data),
      ),
    );
  }

  List<Widget> _buildPluginDisabled() {
    return [
      Text(
        _pluginDisabledSelected.name.toUpperCase(),
        style: Theme.of(context).textTheme.headline4,
      ),
      _CommunityPluginNote(_pluginDisabledSelected.name, true),
    ];
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);

    this.substratePlugins = widget.plugins
        .where((element) => element.basic.pluginType == PluginType.Substrate)
        .toList();
    this.etheremPlugins = widget.plugins
        .where((element) => element.basic.pluginType == PluginType.Etherem)
        .toList();

    this.substrateDisabledPlugins = widget.disabledPlugins
        .where((element) => element.pluginType == PluginType.Substrate)
        .toList();
    this.etheremDisabledPlugins = widget.disabledPlugins
        .where((element) => element.pluginType == PluginType.Etherem)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedNetwork = widget.service.plugin;
      });
    });
  }

  Widget _buildSubstrate(BuildContext context, List<PolkawalletPlugin> plugins,
      List<PluginDisabled> disabledPlugins) {
    if (plugins.length == 0 && disabledPlugins.length == 0) {
      return Container();
    }
    return Row(
      children: <Widget>[
        // left side bar
        Stack(
          children: [
            Container(
              width: 56,
              // color: Theme.of(context).cardColor,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[100],
                    blurRadius: 24.0,
                    spreadRadius: 0,
                  )
                ],
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...plugins.map((e) {
                        final isCurrent =
                            e.basic.name == _selectedNetwork?.basic?.name &&
                                e.basic.pluginType ==
                                    _selectedNetwork.basic.pluginType;
                        return isCurrent
                            ? _NetworkItemActive(icon: e.basic.icon)
                            : Container(
                                margin: EdgeInsets.all(8),
                                child: IconButton(
                                  padding: EdgeInsets.all(8),
                                  icon: isCurrent
                                      ? e.basic.icon
                                      : e.basic.iconDisabled,
                                  onPressed: () {
                                    if (!isCurrent) {
                                      setState(() {
                                        _selectedNetwork = e;
                                        _pluginDisabledSelected = null;
                                      });
                                    }
                                  },
                                ),
                              );
                      }).toList(),
                      ...disabledPlugins.map((e) {
                        final isCurrent = e.name ==
                                _pluginDisabledSelected?.name &&
                            e.pluginType == _pluginDisabledSelected.pluginType;
                        return isCurrent
                            ? _NetworkItemActive(icon: e.icon)
                            : Container(
                                margin: EdgeInsets.all(8),
                                child: IconButton(
                                  padding: EdgeInsets.all(8),
                                  icon: e.icon,
                                  onPressed: () {
                                    if (_pluginDisabledSelected?.name !=
                                        e.name) {
                                      setState(() {
                                        _pluginDisabledSelected = e;
                                        _selectedNetwork = null;
                                      });
                                    }
                                  },
                                ),
                              );
                      }).toList()
                    ],
                    // children: sideBar,
                  )),
            )
          ],
        ),
        Expanded(
          child: Visibility(
              visible: (plugins.length > 0 &&
                      plugins[0].basic.pluginType ==
                          _selectedNetwork?.basic?.pluginType) ||
                  (disabledPlugins.length > 0 &&
                      disabledPlugins[0].pluginType ==
                          _pluginDisabledSelected.pluginType),
              child: ListView(
                padding:
                    EdgeInsets.only(left: 5, top: 16, right: 16, bottom: 16),
                children: _pluginDisabledSelected == null
                    ? _buildAccountList(plugins.length > 0
                        ? plugins[0].basic.pluginType
                        : PluginType.Etherem)
                    : _buildPluginDisabled(),
              )),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(I18n.of(context)
                .getDic(i18n_full_dic_app, 'profile')['setting.network']),
            centerTitle: true,
            bottom: PreferredSize(
                preferredSize: Size.fromHeight(48),
                child: Material(
                  color: Colors.white,
                  child: TabBar(
                      labelColor: Color.fromARGB(255, 0, 0, 0),
                      indicatorColor: Color.fromARGB(255, 0, 0, 0),
                      unselectedLabelColor:
                          Color.fromARGB((0.6 * 255).toInt(), 0, 0, 0),
                      controller: this.tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorPadding: EdgeInsets.only(bottom: 17),
                      indicatorWeight: 1,
                      tabs: [Tab(text: "Substrate"), Tab(text: "Etherem")]),
                ))),
        body: TabBarView(controller: this.tabController, children: [
          _buildSubstrate(
              context, this.substratePlugins, this.substrateDisabledPlugins),
          _buildSubstrate(
              context, this.etheremPlugins, this.etheremDisabledPlugins)
        ]));
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
          padding: EdgeInsets.only(right: 8),
          child: SvgPicture.asset(
            'assets/images/network_icon_bg.svg',
            color: Colors.grey[100],
            width: 56,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 44),
          child: SvgPicture.asset(
            'assets/images/network_icon_border.svg',
            color: Theme.of(context).primaryColor,
            width: 10,
          ),
        ),
        Container(
          padding: EdgeInsets.all(8),
          child: SizedBox(child: icon, height: 28, width: 28),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(const Radius.circular(24)),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12.0,
                spreadRadius: 0,
                offset: Offset(6.0, 1.0),
              )
            ],
          ),
        )
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
          color: Colors.black12,
          border: Border.all(color: Colors.black26, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(dic['plugin.note'] +
                      pluginName.toUpperCase() +
                      dic['plugin.team'])),
              SvgPicture.asset('assets/images/public/github_logo.svg',
                  width: 16),
              JumpToLink(
                plugin_github_links[pluginName],
                text: '',
              )
            ],
          ),
          disabled ? Divider() : Container(),
          disabled ? Text(dic['plugin.disable']) : Container(),
        ],
      ),
    );
  }
}
