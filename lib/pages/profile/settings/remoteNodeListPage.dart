import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class RemoteNodeListPage extends StatelessWidget {
  RemoteNodeListPage(this.service, this.changeNode);
  final AppService service;
  final Future<void> Function(NetworkParams) changeNode;

  static final String route = '/profile/endpoint';

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final endpoints = service.plugin.nodeList;
    List<Widget> list = endpoints.map((i) {
      final isCurrent =
          service.plugin.sdk.api.connectedNode?.endpoint == i.endpoint;
      return ListTile(
        title: Text(i.name),
        subtitle: Text(i.endpoint),
        trailing: Container(
          width: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Visibility(
                  visible: isCurrent,
                  child: Icon(Icons.check_circle,
                      color: Colors.lightGreen, size: 18)),
              Icon(Icons.arrow_forward_ios, size: 18)
            ],
          ),
        ),
        onTap: () {
          if (isCurrent) {
            Navigator.of(context).pop();
            return;
          }
          changeNode(i);
          Navigator.of(context).pop();
        },
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['setting.node.list']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(padding: EdgeInsets.only(top: 8), children: list),
      ),
    );
  }
}
