import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/polkawallet_sdk.dart';

class BridgeTestPage extends StatefulWidget {
  BridgeTestPage(this.sdk);

  final WalletSDK sdk;

  static const String route = '/bridge/test';

  @override
  _BridgeTestPageState createState() => _BridgeTestPageState();
}

class _BridgeTestPageState extends State<BridgeTestPage> {
  final String _testAddress =
      '5GREeQcGHt7na341Py6Y6Grr38KUYRvVoiFSiDB52Gt7VZiN';
  bool _submitting = false;

  void _showResult(BuildContext context, String title, res) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: SelectableText(res, textAlign: TextAlign.left),
          actions: [
            CupertinoButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _testAllApis() async {
    setState(() {
      _submitting = true;
    });
    bool isSuccess = true;
    final chainsAll = await widget.sdk.api.bridge.getFromChainsAll();
    if (chainsAll.length < 2) {
      isSuccess = false;
    }
    final routes = await widget.sdk.api.bridge.getRoutes();
    if (routes.length < 2 || routes[0].token.length < 3) {
      isSuccess = false;
    }
    final chainsInfo = await widget.sdk.api.bridge.getChainsInfo();
    if (chainsInfo.length < 6 || chainsInfo[chainsAll[0]].id.length < 3) {
      isSuccess = false;
    }
    final connected =
        await widget.sdk.api.bridge.connectFromChains(chainsAll, nodeList: {
      'karura': ['wss://crosschain-dev.polkawallet.io:9907']
    });
    if (connected.length < 1) {
      isSuccess = false;
    }
    final props =
        await widget.sdk.api.bridge.getNetworkProperties(connected[0]);
    if (props.tokenSymbol.length < 1 || props.tokenDecimals.length < 1) {
      isSuccess = false;
    }
    final config = await widget.sdk.api.bridge.getAmountInputConfig(
        connected[0],
        connected[1],
        routes[0].token,
        _testAddress,
        _testAddress);
    if (config.from != connected[0] ||
        config.to != connected[1] ||
        config.token != routes[0].token) {
      isSuccess = false;
    }
    widget.sdk.api.bridge.subscribeBalances(connected[0], _testAddress,
        (res) async {
      final balance = res[routes[0].token];
      if (balance?.token != routes[0].token || balance?.decimals == null) {
        isSuccess = false;
      }

      final tx = await widget.sdk.api.bridge.getTxParams(
          connected[0],
          connected[1],
          routes[0].token,
          _testAddress,
          '23300000000',
          balance?.decimals ?? 8,
          _testAddress);
      if (tx.module.isEmpty || tx.call.isEmpty || tx.params.length == 0) {
        isSuccess = false;
      }
      await widget.sdk.api.bridge
          .unsubscribeBalances(connected[0], _testAddress);
      await widget.sdk.api.bridge.disconnectFromChains();
      _showResult(
        context,
        'test all apis',
        isSuccess ? 'success' : 'error',
      );
      setState(() {
        _submitting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('keyring API'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text('testAllBridgeApis'),
              subtitle: Text('''
sdk.api.bridge'''),
              trailing: SubmitButton(
                submitting: _submitting,
                call: _testAllApis,
              ),
            ),
            Divider(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SubmitButton extends StatelessWidget {
  SubmitButton({this.call, this.submitting, this.needConnect = false});
  final bool submitting;
  final bool needConnect;
  final Function call;

  @override
  Widget build(BuildContext context) {
    return needConnect
        ? Column(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).disabledColor,
              ),
              Text('Connection\nRequired', style: TextStyle(fontSize: 10))
            ],
          )
        : IconButton(
            color: submitting
                ? Theme.of(context).disabledColor
                : Theme.of(context).primaryColor,
            icon: submitting
                ? Icon(Icons.refresh)
                : Icon(Icons.play_circle_outline),
            onPressed: () => call(),
          );
  }
}
