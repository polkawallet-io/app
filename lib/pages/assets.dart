import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class AssetsPage extends StatefulWidget {
  AssetsPage(this.network, this.keyring);
  final PolkawalletPlugin network;
  final Keyring keyring;
  @override
  _AssetsPageState createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('assets page'),
          ],
        ),
      ),
    );
  }
}
