import 'package:app/pages/account/createAccountEntryPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_ui/components/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class NetworkSelectPage extends StatefulWidget {
  NetworkSelectPage(this.service, this.plugins, this.changeNetwork);

  static final String route = '/network';

  final AppService service;
  final List<PolkawalletPlugin> plugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  @override
  _NetworkSelectPageState createState() => _NetworkSelectPageState();
}

class _NetworkSelectPageState extends State<NetworkSelectPage> {
  PolkawalletPlugin _selectedNetwork;
  bool _networkChanging = false;

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

    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _networkChanging = false;
      });
    }
  }

  Future<void> _onSelect(KeyPairData i) async {
    bool isCurrentNetwork =
        _selectedNetwork.basic.name == widget.service.plugin.basic.name;
    if (i.address != widget.service.keyring.current.address ||
        !isCurrentNetwork) {
      /// set current account
      widget.service.keyring.setCurrent(i);

      if (!isCurrentNetwork) {
        /// set new network and reload web view
        await _reloadNetwork();

        _selectedNetwork.changeAccount(i);
      } else {
        widget.service.plugin.changeAccount(i);
      }

      widget.service.store.assets
          .loadCache(i, widget.service.plugin.basic.name);
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

  List<Widget> _buildAccountList() {
    Color primaryColor = Theme.of(context).primaryColor;
    List<Widget> res = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            _selectedNetwork.basic.name.toUpperCase(),
            style: Theme.of(context).textTheme.headline4,
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            color: primaryColor,
            onPressed: () => _onCreateAccount(),
          )
        ],
      ),
    ];

    /// first item is current account
    List<KeyPairData> accounts = [widget.service.keyring.current];

    /// add optional accounts
    accounts.addAll(widget.service.keyring.optionals);

    res.addAll(accounts.map((i) {
      final bool isCurrentNetwork =
          _selectedNetwork.basic.name == widget.service.plugin.basic.name;
      final accInfo = widget.service.keyring.current.indexInfo;
      final addressMap = widget.service.keyring.store
          .pubKeyAddressMap[_selectedNetwork.basic.ss58.toString()];
      final address = addressMap != null
          ? addressMap[i.pubKey]
          : widget.service.keyring.current.address;
      final String accIndex =
          isCurrentNetwork && accInfo != null && accInfo['accountIndex'] != null
              ? '${accInfo['accountIndex']}\n'
              : '';
      final double padding = accIndex.isEmpty ? 0 : 7;
      return RoundedCard(
        border: isCurrentNetwork &&
                i.address == widget.service.keyring.current.address
            ? Border.all(color: Theme.of(context).primaryColorLight)
            : Border.all(color: Theme.of(context).cardColor),
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.only(top: padding, bottom: padding),
        child: ListTile(
          leading: AddressIcon(address, svg: i.icon),
          title: Text(UI.accountName(context, i)),
          subtitle: Text('$accIndex${Fmt.address(address)}', maxLines: 2),
          onTap: _networkChanging ? null : () => _onSelect(i),
        ),
      );
    }).toList());
    return res;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedNetwork = widget.service.plugin;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    return Scaffold(
      appBar: AppBar(
        title: Text(doc['setting.network']),
        centerTitle: true,
      ),
      body: _selectedNetwork == null
          ? Container()
          : Row(
              children: <Widget>[
                // left side bar
                Container(
                  padding: EdgeInsets.fromLTRB(8, 16, 0, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius:
                            8.0, // has the effect of softening the shadow
                        spreadRadius: 2.0, // ha
                      )
                    ],
                  ),
                  child: Column(
                    children: widget.plugins.map((i) {
                      final network = i.basic.name;
                      final isCurrent = network == _selectedNetwork.basic.name;
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.only(right: 6),
                        decoration: isCurrent
                            ? BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        width: 2,
                                        color: Theme.of(context).primaryColor)),
                              )
                            : null,
                        child: IconButton(
                          padding: EdgeInsets.all(8),
                          icon: isCurrent ? i.basic.icon : i.basic.iconDisabled,
                          onPressed: () {
                            if (!isCurrent) {
                              setState(() {
                                _selectedNetwork = i;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: _buildAccountList(),
                  ),
                )
              ],
            ),
    );
  }
}
