import 'package:app/pages/profile/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

class RemoteNodeListPage extends StatelessWidget {
  RemoteNodeListPage(this.service, this.changeNode);
  final AppService service;
  final Future<void> Function(NetworkParams) changeNode;

  static final String route = '/profile/endpoint';

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).getDic(i18n_full_dic_app, 'profile');
    final endpoints = service.plugin.nodeList;
    final List<Widget> list = [];
    endpoints.asMap().forEach((k, i) {
      final isCurrent =
          service.plugin.sdk.api.connectedNode?.endpoint == i.endpoint;
      list.add(SettingsPageListItem(
        label: i.name,
        subtitle: i.endpoint,
        content: Visibility(
            visible: isCurrent,
            child: Image.asset(
              "assets/images/icon_circle_select.png",
              width: 16,
            )),
        onTap: () {
          if (isCurrent) {
            Navigator.of(context).pop();
            return;
          }
          changeNode(i);
          Navigator.of(context).pop();
        },
      ));
      if (k < endpoints.length - 1) {
        list.add(Divider(height: 24.h));
      }
    });
    return Scaffold(
      appBar: AppBar(
          title: Text(dic['setting.node.list']),
          centerTitle: true,
          leading: BackBtn()),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: RoundedCard(
              margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
              padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
              child: Column(children: list)),
        ),
      ),
    );
  }
}
