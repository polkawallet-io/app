import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/keyring.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage(this.network, this.keyring);
  final PolkawalletPlugin network;
  final Keyring keyring;
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('profile page'),
          ],
        ),
      ),
    );
  }
}
