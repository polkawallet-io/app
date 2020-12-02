import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class WillPopScopWrapper extends StatelessWidget {
  WillPopScopWrapper(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      child: child,
      onWillPop: () {
        final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
        return Platform.isAndroid
            ? showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text(dic['exit.confirm']),
                  actions: <Widget>[
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(dic['cancel']),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      /*Navigator.of(context).pop(true)*/
                      child: Text(dic['ok']),
                    ),
                  ],
                ),
              )
            : Future.value(true);
      },
    );
  }
}
