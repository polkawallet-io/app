import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class PluginTestETH extends PolkawalletPlugin {
  PluginTestETH({name = 'testETH'})
      : basic = PluginBasicData(
          name: name,
          genesisHash: "",
          primaryColor: Colors.pink,
          gradientColor: Colors.red,
          backgroundImage: AssetImage('assets/images/logo_about.png'),
          icon: Image.asset('assets/images/logo_about.png'),
          iconDisabled: Image.asset('assets/images/logo_about.png'),
          jsCodeVersion: 22201,
          isTestNet: false,
          isXCMSupport: false,
        ),
        pluginType = PluginType.Etherem;
  @override
  PluginType pluginType;

  @override
  final PluginBasicData basic;

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: "test",
        icon: Text("test"),
        iconActive: Text("test"),
        content: Container(),
      )
    ];
  }

  @override
  Map<String, WidgetBuilder> getRoutes(Keyring keyring) {
    return {};
  }

  @override
  Future<String> loadJSCode() => null;

  @override
  // TODO: implement nodeList
  List<NetworkParams> get nodeList {
    return [
      {
        'name': 'Polkadot (Live, hosted by PatractLabs)',
        'ss58': 0,
        'endpoint': 'wss://polkadot.elara.patract.io',
      },
      {
        'name': 'Polkadot (Live, hosted by Parity)',
        'ss58': 0,
        'endpoint': 'wss://rpc.polkadot.io',
      },
      {
        'name': 'Polkadot (Live, hosted by onfinality)',
        'ss58': 0,
        'endpoint': 'wss://polkadot.api.onfinality.io/public-ws',
      },
    ].map((e) => NetworkParams.fromJson(e)).toList();
  }

  @override
  // TODO: implement tokenIcons
  Map<String, Widget> tokenIcons = {};
}
