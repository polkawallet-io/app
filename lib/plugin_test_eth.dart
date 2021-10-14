import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/plugin/homeNavItem.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';
import 'package:polkawallet_ui/components/entryPageCard.dart';
import 'package:polkawallet_ui/components/entryPageCard.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';

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
            pluginType: PluginType.Etherem),
        recoveryEnabled = false;

  @override
  final PluginBasicData basic;

  @override
  final bool recoveryEnabled;

  @override
  List<HomeNavItem> getNavItems(BuildContext context, Keyring keyring) {
    return [
      HomeNavItem(
        text: "test",
        icon: Text("test"),
        iconActive: Text("test"),
        content: Container(
          child: SafeArea(
              child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  child: EntryPageCard(
                    'Polkassembly',
                    'polkassembly',
                    Image.asset(
                      'packages/polkawallet_plugin_kusama/assets/images/public/polkassembly.png',
                      width: 48,
                    ),
                    color: Colors.transparent,
                  ),
                  onTap: () => Navigator.of(context).pushNamed(
                    DAppWrapperPage.route,
                    arguments: 'https://app.uniswap.org/#/swap',
                    // "https://polkadot.js.org/apps/",
                  ),
                ),
              )
            ],
          )),
        ),
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
  Map<String, Widget> tokenIcons = {
    'KSM': Image.asset(
        'packages/polkawallet_plugin_kusama/assets/images/tokens/KSM.png'),
    'DOT': Image.asset(
        'packages/polkawallet_plugin_kusama/assets/images/tokens/DOT.png'),
  };
}
